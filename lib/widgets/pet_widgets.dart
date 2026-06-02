import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/pet.dart';
import '../models/player_profile.dart';
import '../theme.dart';

class PetPickerGrid extends StatelessWidget {
  const PetPickerGrid({
    super.key,
    required this.selectedPet,
    required this.onSelected,
  });

  final PetType? selectedPet;
  final ValueChanged<PetType> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        for (final pet in PetType.values)
          _PetChoice(
            pet: pet,
            selected: selectedPet == pet,
            onTap: () => onSelected(pet),
          ),
      ],
    );
  }
}

class PetCareCard extends StatelessWidget {
  const PetCareCard({
    super.key,
    required this.player,
    required this.onTap,
  });

  final PlayerProfile player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pet = player.petType;
    if (pet == null) return const SizedBox.shrink();
    final strings = context.strings;
    final care = player.petCare();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(
                pet.asset(care.mood),
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.petGreeting(strings.petName(pet)),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    PetMeter(
                      icon: Icons.restaurant_rounded,
                      label: strings.feeding,
                      value: care.feedingPoints,
                    ),
                    const SizedBox(height: 8),
                    PetMeter(
                      icon: Icons.toys_rounded,
                      label: strings.enjoyment,
                      value: care.enjoymentPoints,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.touch_app_rounded, color: AppTheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetChoice extends StatelessWidget {
  const _PetChoice({
    required this.pet,
    required this.selected,
    required this.onTap,
  });

  final PetType pet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Semantics(
      button: true,
      selected: selected,
      label: strings.petName(pet),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary.withValues(alpha: 0.10) : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.primary : Colors.grey.shade300,
              width: selected ? 3 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(
                  pet.asset(PetMood.happy),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.petName(pet),
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetMeter extends StatelessWidget {
  const PetMeter({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        SizedBox(width: 82, child: Text(label)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 10,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.7),
              color: value < 20
                  ? Colors.orange.shade600
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}