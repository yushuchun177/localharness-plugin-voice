extends VBoxContainer
## 本插件的设置界面 —— 由插件自己提供，主程序只负责挂载。
## 想改这个插件在这里长什么样、有哪些开关，改这个文件即可。

func build(plugin_id: String) -> void:
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(PluginUI.title("语音输入"))
	add_child(PluginUI.hint("朗读回答（离线中文音色），也可以录一段麦克风并尝试转成文字。"))
	add_child(PluginUI.section("行为"))
	add_child(PluginUI.int_field(plugin_id, "rate", "朗读语速", 0, "-10 慢 … 10 快"))
	add_child(PluginUI.int_field(plugin_id, "seconds", "默认录音秒数", 5, ""))
	add_child(PluginUI.section("能力开关"))
	add_child(PluginUI.hint("每一项都能单独关掉；关掉后模型看不到这个能力，也调用不了。"))
	for t in Plugins.tools_of(plugin_id):
		var tname := str(t.get("name", ""))
		var human := tname
		var desc := str(t.get("description", ""))
		if tname == "voice_speak":
			human = "朗读文字"
			desc = "用系统语音把文字念出来"
		if tname == "voice_voices":
			human = "查看可用音色"
			desc = "只读：列出这台机器装了哪些声音"
		if tname == "voice_listen":
			human = "录音并识别"
			desc = "会打开麦克风录几秒"
		add_child(PluginUI.perm_row(tname, human, desc, bool(t.get("dangerous", false))))
	add_child(PluginUI.readme_box(plugin_id))
