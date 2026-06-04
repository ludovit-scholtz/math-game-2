import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../models/player_profile.dart';
import '../services/audio_service.dart';
import '../services/coin_service.dart';
import '../services/notification_service.dart';
import '../services/player_service.dart';
import '../theme.dart';
import '../widgets/pet_widgets.dart';

class PetScreen extends StatefulWidget {
  const PetScreen({super.key, required this.playerName});

  final String playerName;

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  final PlayerService _playerService = PlayerService();
  final CoinService _coinService = CoinService();
  final AudioService _audio = AudioService();

  PlayerProfile? _player;
  int _coins = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final players = await _playerService.loadPlayers();
    final wallet = await _coinService.load(widget.playerName);
    PlayerProfile? player;
    for (final candidate in players) {
      if (candidate.name == widget.playerName) {
        player = candidate;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _player = player;
      _coins = wallet.coins;
      _loading = false;
    });
  }

  Future<void> _careForPet(_PetCareAction action) async {
    final player = _player;
    if (player == null || !player.hasPet) return;
    final strings = context.strings;
    final cost = action == _PetCareAction.feed ? 20 : 100;
    final wallet = await _coinService.spendCoins(player.name, cost);
    if (!mounted) return;
    if (wallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.notEnoughCoins)),
      );
      return;
    }
    final updated = action == _PetCareAction.feed
        ? await _playerService.feedPet(player.name)
        : await _playerService.buyPetToy(player.name);
    if (!mounted || updated == null) return;
    setState(() {
      _player = updated;
      _coins = wallet.coins;
    });
    unawaited(NotificationService().scheduleForPlayer(updated));
    unawaited(
      action == _PetCareAction.feed
          ? _audio.playPetFeed()
          : _audio.playPetToy(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == _PetCareAction.feed
              ? strings.petFed
              : strings.petToyBought,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final player = _player;
    final pet = player?.petType;
    final care = player?.petCare();
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.pet),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : pet == null || care == null
                ? Center(child: Text(strings.choosePet))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 260),
                          child: Image.asset(
                            pet.asset(care.mood),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.petGreeting(strings.petName(pet)),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 18),
                              PetMeter(
                                icon: Icons.restaurant_rounded,
                                label: strings.feeding,
                                value: care.feedingPoints,
                              ),
                              const SizedBox(height: 14),
                              PetMeter(
                                icon: Icons.toys_rounded,
                                label: strings.enjoyment,
                                value: care.enjoymentPoints,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Chip(
                          avatar: const Text('🪙'),
                          label: Text(
                            strings.coinBalanceLabel(_coins),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _careForPet(_PetCareAction.feed),
                        icon: const Icon(Icons.restaurant_rounded),
                        label: Text(
                          '${strings.feedPet}  ${strings.coinCount(20)}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _careForPet(_PetCareAction.toy),
                        icon: const Icon(Icons.toys_rounded),
                        label: Text(
                          '${strings.buyPetToy}  ${strings.coinCount(100)}',
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

enum _PetCareAction { feed, toy }