# CLAUDE.md

All project instructions for AI agents live in [AGENTS.md](AGENTS.md) so that
Claude Code, GitHub Copilot and other agents share one source of truth.

@AGENTS.md

## Claude Code slash commands

Project commands live in `.claude/commands/`:

| Command | Purpose |
| --- | --- |
| `/check [test path]` | Run `flutter analyze` + `flutter test` and fix anything that fails |
| `/add-string <key> <English text>` | Add a translated UI string to all 11 languages |
| `/add-language <code>` | Add a new supported language end-to-end |
| `/change-rule <description>` | Change a game rule and keep code, tests, README and Guide in sync |
| `/ship [description]` | Branch → commit → PR → code review → fix → re-review → merge |
| `/release <x.y.z>` | Tag a release that uploads to Google Play internal testing |
