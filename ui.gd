extends VBoxContainer
## 语音输入 —— 这个页面是插件自己提供的界面。
## 界面全部由插件自己拼，主程序只提供积木。

func build(plugin_id: String) -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	add_child(PluginUI.section("朗读"))
	add_child(PluginUI.slider_row(plugin_id, "rate", "语速", -10, 10, 1, "", 0,
		"0 是正常，负数更慢"))
	add_child(PluginUI.action_row("试听一句", "会用系统中文音色念出来", "播放",
		func(): return Plugins.invoke("voice_speak", {"text": "你好，我是你的本地助手。"})))

	add_child(PluginUI.section("录音"))
	add_child(PluginUI.slider_row(plugin_id, "seconds", "录音时长", 1, 20, 1, "秒", 5,
		"点下面的按钮开始录，说完等它识别"))
	add_child(PluginUI.action_row("录一段并转成文字",
		"需要系统装了中文语音识别，否则只能录音不能识别", "开始录音",
		func(): return Plugins.invoke("voice_listen", {"seconds": int(PluginPrefs.get_value(plugin_id, "seconds", 5))})))
	add_child(PluginUI.overview(plugin_id))
	add_child(PluginUI.permissions_section(plugin_id))
	add_child(PluginUI.doc_section(plugin_id))
