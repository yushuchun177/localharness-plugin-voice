# 语音输入 / Voice

朗读回答（Windows 中文语音）；也能录一段麦克风并尝试用系统语音识别转成文字。

Speak answers aloud (Windows voices) and record the mic, transcribing it with the system speech recognizer when available.

Local-Harness（Godot 版）的独立插件，不随主程序发布。

主程序「设置 → 插件管理」会从 GitHub 下载并自动部署到 `user://plugins/voice/`。

## 工具

- `voice_speak` —— 用系统语音朗读一段文字（离线，中文一般自带 Huihui）。
  - `text`: string，要朗读的文字
  - `rate`: int，可选，语速 -10..10，默认 0
- `voice_voices` —— 列出这台机器上装了的语音合成声音。
- `voice_listen` —— 录一段麦克风并尝试转成文字（需要系统装了对应语言的语音识别）。
  - `seconds`: int，可选，录音秒数，默认 5

## 安装

1. Local-Harness → 设置 → 插件管理 → 刷新列表
2. 找到「语音输入」点安装
3. 装完直接在对话里让模型调用

## 结构

```
manifest.json
main.gd
```

## 许可

GPL-3.0（与主程序一致）。
