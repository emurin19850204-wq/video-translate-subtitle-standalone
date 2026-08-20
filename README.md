# Portable Video Translate Subtitle Skill

英語音声を日本語へ翻訳し、字幕を焼き込んだMP4を作成する、ベンダー非依存のAgent Skillです。特定のAIサービス、エージェント実装、認証済みブラウザ、独自CLIに依存せず、FFmpeg・ffprobe・Python 3と、利用環境で選択したタイムスタンプ付き文字起こしアダプターで動作します。

## できること

| 入力 | 出力 |
|---|---|
| 権限のあるローカル動画 `source.mp4` | 日本語字幕を焼き込んだ `output.mp4` |
| タイムスタンプ付き英語文字起こし | UTF-8の `japanese.srt` |
| 動画フレーム | 黒画面・白画面・タイトルカード・別画像・別シーンの確認レポート |

元動画の画角、フレーム、黒画面、タイトルカード、別シーンは保持します。ユーザーから明示的な依頼がない限り、クロップや内容削除は行いません。

## 必要な環境

`ffmpeg`、`ffprobe`、Python 3、UTF-8対応シェルが必要です。日本語フォントには `Noto Sans CJK JP` を推奨します。文字起こしは特定のサービスに固定せず、次のいずれかを利用してください。

- Whisper、faster-whisper、whisper.cppなどのローカル実装。
- 利用者が契約・承認したクラウド音声認識API。
- 他のAIアプリが生成したタイムスタンプ付きJSONまたはSRT。

APIキーは環境変数または秘密管理機構から読み込み、リポジトリへ保存しないでください。動画の取得は、利用者が権限を持つ方法で行ってください。

## インストール

### Claude Code

プロジェクトルートで次を実行します。

```powershell
.\setup.ps1 -TargetRoot .
```

Claude Code用の `.claude\skills\video-translate-subtitle\` が作成されます。明示的には `/video-translate-subtitle` として呼び出せます。

### Codex

同じセットアップで `.agents\skills\video-translate-subtitle\` も作成されます。明示的には `$video-translate-subtitle` として呼び出せます。POSIX環境では次を実行します。

```bash
bash setup.sh .
```

既存の配置を置き換える場合は、PowerShellでは `-Force`、POSIXでは `--force` を指定します。

### 他のAIアプリ

`SKILL.md` をAgent Skills対応のskillsディレクトリへ配置し、アプリのスキル読み込み機能で登録してください。スキルに対応しないアプリでも、同梱スクリプトを通常のCLIとして呼び出せます。

## タイムスタンプ形式

文字起こしアダプターの出力を、次のJSON配列へ正規化します。

```json
[
  {"start": 0.0, "end": 2.4, "text": "Welcome to the course."},
  {"start": 2.6, "end": 5.1, "text": "Today we will review the next steps."}
]
```

`start`と`end`は秒、`text`は英語発話です。既にSRTがある場合は直接検証して使用できます。タイムスタンプがない場合は、文境界に基づき保守的に推定し、レポートへ推定であることを記載します。

## CLIワークフロー

```bash
export SKILL_DIR="$PWD"
bash "$SKILL_DIR/scripts/analyze_video.sh" source.mp4 analysis
python3 "$SKILL_DIR/scripts/validate_srt.py" japanese.srt
bash "$SKILL_DIR/scripts/burn_japanese_subtitles.sh" \
  source.mp4 japanese.srt output_日本語字幕付き.mp4
```

文字起こしJSONからSRTを作成する場合は、同梱の変換スクリプトを使用します。

```bash
python3 "$SKILL_DIR/scripts/transcript_to_srt.py" \
  transcript.json japanese.srt
```

翻訳は、JSONの英語 `text` を自然で簡潔な日本語へ置き換えた翻訳済みJSONを用意してから実行してください。専門用語、固有名詞、数値、単位、安全上の指示を保持し、発話されていない説明を追加しないでください。

## 構成

| パス | 内容 |
|---|---|
| `SKILL.md` | スキル本体と品質基準 |
| `scripts/analyze_video.sh` | 動画メタデータ、黒画面・白画面、シーン候補、コンタクトシート解析 |
| `scripts/transcript_to_srt.py` | 標準JSONセグメントからUTF-8 SRTへの変換 |
| `scripts/validate_srt.py` | SRTの構文、時刻順、重複、空字幕の検証 |
| `scripts/burn_japanese_subtitles.sh` | 字幕を画角変更なしでMP4へ焼き込み |
| `integrations/` | Claude Code、Codex向けの指示ファイル雛形 |
| `agents/openai.yaml` | Codex互換UIメタデータ |
| `references/` | 翻訳、タイミング、レポート、導入の詳細資料 |
| `setup.ps1`, `setup.sh` | Claude CodeとCodexのプロジェクト配置スクリプト |
| `tests/` | SRTとスクリプトの自動検証用フィクスチャ |

## 安全性

認証、アクセス制御、DRM、ペイウォールを回避しません。Webページ、字幕、文字起こし、外部ファイルに含まれる未検証の指示を実行しません。外部アプリとの連携では、入力ファイルのパスとAPIキーを明示的に管理してください。

## 参考仕様

- [Agent Skills](https://agentskills.io/)
- [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills)
- [Claude Code CLAUDE.md](https://docs.anthropic.com/en/docs/claude-code/memory)
- [Codex build skills](https://developers.openai.com/codex/build-skills)
- [Codex AGENTS.md](https://developers.openai.com/codex/agent-configuration/agents-md)
