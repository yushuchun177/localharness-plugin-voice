# 语音输入 / Voice

朗读回答（Windows 中文语音）；也能录一段麦克风并尝试用系统语音识别转成文字。

Speak answers aloud (Windows voices) and record the mic, transcribing it with the system speech recognizer when available.

> Local-Harness（Godot 版）的独立插件。不随主程序发布，由主程序
> 「设置 → 插件管理」从 GitHub 下载并自动部署到 `user://plugins/voice/`。

## 安装

1. 打开 Local-Harness → 设置 → 插件管理 → 刷新列表
2. 找到「语音输入」点「安装」
3. 装好后在侧栏底部点同名按钮，里面是这个插件自己的设置页

手动安装：把本仓库下载解压到 `%LOCALAPPDATA%\Godot\app_userdata\Local-Harness\plugins\voice\`

## 工具

- `voice_speak` —— 用系统语音朗读一段文字（离线，中文一般自带 Huihui）。（会产生操作）
  - `text`: string，要朗读的文字
  - `rate`: int，可选，语速 -10..10，默认 0
- `voice_voices` —— 列出这台机器上装了的语音合成声音。（只读）
- `voice_listen` —— 录一段麦克风并尝试转成文字（需要系统装了对应语言的语音识别）。（会产生操作）
  - `seconds`: int，可选，录音秒数，默认 5

## 命令

- `/say 你好` —— 朗读一段文字

## 设置项

- **朗读语速**（`rate`，默认 `0`）-10 慢 … 10 快
- **默认录音秒数**（`seconds`，默认 `5`）

## 权限

每个工具都能在插件设置页里单独开关。关掉之后它不会出现在模型的工具清单里，
就算模型硬要调用也会被主程序拒绝。协议里用 `level` 标了风险等级：

- `read` 只读：不会改动任何东西
- `act` 会产生操作：会读写文件、联网或占用设备
- `danger` 高危：会操作你的系统

## 怎么用

装好后直接在对话里提需求，例如：“用系统语音朗读一段文字（离线，中文一般自带 Huihui）。”

模型会输出一行 ```tool 协议块，宿主解析后执行，再把结果喂回模型。
也可以直接用斜杠命令，不经过模型。

## 许可

GPL-3.0（与主程序一致）。完整协议文本见仓库根目录的 [LICENSE](LICENSE)。

---

# Voice

Speak answers aloud (Windows voices) and record the mic, transcribing it with the system speech recognizer when available.

> An independent plugin for **Local-Harness (Godot edition)**. It is not bundled with the
> app; the app downloads it from this repository into `user://plugins/voice/` and hot-loads it.

## Install

1. Local-Harness → Settings → Plugins → Refresh
2. Find "Voice" and click Install
3. Open it from the button at the bottom of the sidebar for its own settings page

Manual: unzip this repo into `%LOCALAPPDATA%\Godot\app_userdata\Local-Harness\plugins\voice\`

## Tools

- `voice_speak` — 用系统语音朗读一段文字（离线，中文一般自带 Huihui）。 (has side effects)
  - `text`: string，要朗读的文字
  - `rate`: int，可选，语速 -10..10，默认 0
- `voice_voices` — 列出这台机器上装了的语音合成声音。 (read-only)
- `voice_listen` — 录一段麦克风并尝试转成文字（需要系统装了对应语言的语音识别）。 (has side effects)
  - `seconds`: int，可选，录音秒数，默认 5

## Commands

- `/say 你好` — 朗读一段文字

## Settings

- **朗读语速** (`rate`, default `0`) -10 慢 … 10 快
- **默认录音秒数** (`seconds`, default `5`) 

## Permissions

Every tool can be toggled individually on the plugin settings page. A disabled tool is
removed from the model's tool list and rejected by the host even if the model still calls it.
`level` in the manifest marks the risk:

- `read` — no side effects
- `act` — reads/writes, network or devices
- `danger` — controls your system

## Usage

Just ask in the chat, e.g. “用系统语音朗读一段文字（离线，中文一般自带 Huihui）。”

The model emits a ```tool block, the host executes it and feeds the result back.
You can also use the slash commands above, which skip the model entirely.

## License

GPL-3.0 (same as the host app). Full text: [LICENSE](LICENSE).
