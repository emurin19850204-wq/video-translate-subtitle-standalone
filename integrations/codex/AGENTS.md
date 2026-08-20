# Codex project setup

Use the `video-translate-subtitle` skill when the task asks for English-to-Japanese video subtitles, SRT creation, FFmpeg burn-in, or reporting of black/white screens and scene changes.

## Skill location

For a repository-scoped Codex installation, place the skill folder at:

```text
.agents/skills/video-translate-subtitle/
```

The folder must contain `SKILL.md`, `scripts/`, `references/`, and optionally `agents/openai.yaml`. Codex discovers skills from `.agents/skills` and can invoke the skill explicitly with `$video-translate-subtitle` or select it when the request matches its description.

## Required behavior

Read the skill's `SKILL.md` before processing a matching request. Preserve the source framing and audio unless the user explicitly requests an edit. Use the bundled scripts for SRT validation, video analysis, and subtitle burn-in. Deliver the completed MP4, SRT, visual findings report, and subtitle preview.

Use the skill's `scripts/` through `SKILL_DIR`. Keep API keys in environment variables or the approved secrets store; never place them in `AGENTS.md`, `SKILL.md`, or generated artifacts.

## Windows installation

From the repository root in PowerShell, run the bundled setup script:

```powershell
.\video-translate-subtitle\setup.ps1 -TargetRoot .
```

This creates `.agents\skills\video-translate-subtitle\` and copies the skill resources into it without overwriting an existing installation unless `-Force` is supplied.

## Verification

After installation, start Codex from the repository root and ask it to list the active skills or explicitly invoke `$video-translate-subtitle`. Confirm that `SKILL.md` is loaded before processing a video.
