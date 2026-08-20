# Project instructions for Claude Code

This repository contains the `video-translate-subtitle` Agent Skill. When the user asks to translate English speech in an authorized video into Japanese subtitles, read `SKILL.md` and use the bundled scripts and references.

Prefer the project installation layout `.claude/skills/video-translate-subtitle/`. If it is not installed there yet, run `setup.ps1` on Windows or `setup.sh` on POSIX systems. Preserve source framing and audio, validate SRT before encoding, and report black/white screens, title cards, alternate images, and scene changes with exact intervals.

For the complete workflow, read:

```text
SKILL.md
integrations/claude/CLAUDE.md
references/portable-installation.md
```
