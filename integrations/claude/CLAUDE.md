# Claude Code project setup

Use the `video-translate-subtitle` skill for requests to translate English speech in authorized video files into Japanese subtitles and produce an MP4.

## Skill location

For a project-scoped Claude Code installation, place the skill folder at:

```text
.claude/skills/video-translate-subtitle/
```

The folder must contain `SKILL.md`, `scripts/`, and `references/`. Claude Code discovers the skill from `SKILL.md` and can invoke it explicitly with `/video-translate-subtitle` or select it when the request matches its description.

## Required behavior

Read the skill's `SKILL.md` before processing a matching request. Preserve the source framing and audio unless the user explicitly requests an edit. Use the bundled scripts for SRT validation, video analysis, and subtitle burn-in. Deliver the completed MP4, SRT, visual findings report, and subtitle preview.

If the project keeps the skill in another directory, use Claude Code's `--add-dir` option or copy this integration file into the project root as `CLAUDE.md`. Do not place secrets in the skill or this file.

## Windows installation

From the project root in PowerShell, run the bundled setup script:

```powershell
.\video-translate-subtitle\setup.ps1 -TargetRoot .
```

This creates `.claude\skills\video-translate-subtitle\` and copies the skill resources into it without overwriting an existing installation unless `-Force` is supplied.
