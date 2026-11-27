extends Node
## 语音插件 · local-harness
## 工具：voice_speak（TTS） / voice_voices（列声音） / voice_listen（录音 + 识别）
##
## TTS 用 PowerShell 的 System.Speech.Synthesis（Windows 自带，离线）。
## 识别用 System.Speech.Recognition 的听写语法——只有装了对应语言的识别引擎才能用，
## 中文需要系统里有 zh-CN 语音识别组件；没有就明确告诉用户，不要假装听懂。
##
## 录音本身走 Godot 的麦克风采集（AudioStreamMicrophone），存成 WAV 再交给识别器。

const REC_BUS := "LHVoiceRecord"


func _app() -> Node:
	var ml := Engine.get_main_loop()
	return ml.root.get_node_or_null("/root/App") if ml != null else null



func _pref(key: String, def_value):
	var ml := Engine.get_main_loop()
	var prefs = ml.root.get_node_or_null("/root/PluginPrefs") if ml != null else null
	if prefs == null:
		return def_value
	return prefs.get_value("voice", key, def_value)

func run(tool: String, args: Dictionary) -> Dictionary:
	match tool:
		"voice_speak":
			return _speak(args)
		"voice_voices":
			return _voices()
		"voice_listen":
			return _listen(args)
	return {"ok": false, "output": "未知工具：%s" % tool}


# ---------------------------------------------------------------- TTS
func _ps(script: String) -> Array:
	var f_path := OS.get_temp_dir().path_join("lh_voice_%d.ps1" % randi())
	var f := FileAccess.open(f_path, FileAccess.WRITE)
	f.store_buffer(PackedByteArray([0xFF, 0xFE]))
	f.store_buffer(script.to_utf16_buffer())
	f.close()
	var out: Array = []
	var code := OS.execute("powershell.exe", PackedStringArray([
		"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", f_path]), out, true)
	DirAccess.remove_absolute(f_path)
	if code != 0:
		var msg := "PowerShell 失败（%d）" % code
		if out.size() > 0:
			msg += "：" + str(out[0]).strip_edges().substr(0, 300)
		return ["__ERR__", msg]
	return out


func _voices() -> Dictionary:
	var r := _ps("""
Add-Type -AssemblyName System.Speech
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$s.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo.Name + '|' + $_.VoiceInfo.Culture.Name }
""")
	if r.size() > 0 and str(r[0]) == "__ERR__":
		return {"ok": false, "output": str(r[1])}
	var lines: PackedStringArray = []
	for line in str(r[0]).split("\n"):
		var t := line.strip_edges()
		if t != "":
			lines.append("- " + t.replace("|", "  （"))
			if not t.ends_with("）"):
				lines[lines.size() - 1] += "）"
	return {"ok": true, "output": "已安装的声音：\n" + "\n".join(lines)}


func _speak(args: Dictionary) -> Dictionary:
	var text := str(args.get("text", "")).strip_edges()
	if text == "":
		return {"ok": false, "output": "text 不能为空"}
	var rate: int = int(args.get("rate", int(_pref("rate", 0))))
	# 用文件传文本，避免中文经过命令行编码被打坏
	var txt_path := OS.get_temp_dir().path_join("lh_tts_%d.txt" % randi())
	var tf := FileAccess.open(txt_path, FileAccess.WRITE)
	tf.store_string(text)
	tf.close()
	var r := _ps("""
Add-Type -AssemblyName System.Speech
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$s.Rate = RATE
$zh = $s.GetInstalledVoices() | Where-Object { $_.VoiceInfo.Culture.Name -like 'zh*' } | Select-Object -First 1
if ($zh) { $s.SelectVoice($zh.VoiceInfo.Name) }
$t = [System.IO.File]::ReadAllText('TXT_PATH', [System.Text.Encoding]::UTF8)
$s.Speak($t)
$s.Dispose()
Write-Output 'ok'
""".replace("RATE", str(rate)).replace("TXT_PATH", txt_path.replace("'", "''")))
	DirAccess.remove_absolute(txt_path)
	if r.size() > 0 and str(r[0]) == "__ERR__":
		return {"ok": false, "output": str(r[1])}
	return {"ok": true, "output": "已朗读 %d 个字" % text.length()}


# ---------------------------------------------------------------- 录音 + 识别
func _listen(args: Dictionary) -> Dictionary:
	var seconds: int = clampi(int(args.get("seconds", int(_pref("seconds", 5)))), 1, 30)
	var wav: String = _record(seconds)
	if wav == "":
		return {"ok": false, "output": "录音失败：没有可用的麦克风（或系统禁止了麦克风访问）"}
	var text := _recognize(wav)
	DirAccess.remove_absolute(wav)
	if text == "":
		return {"ok": false, "output": "录到了 %.0f 秒音频，但系统里没有可用的语音识别引擎。\n" % seconds +
			"中文需要安装「中文(简体) 语音识别」组件：设置 → 时间和语言 → 语言 → 中文 → 语音。"}
	return {"ok": true, "output": text}


## 注意：整个录音过程是阻塞的（工具调用本身就是同步的），
## 但音频采集跑在 Godot 的音频线程上，所以 OS.delay_msec 期间照样有数据。
func _record(seconds: int) -> String:
	var bus := AudioServer.get_bus_index(REC_BUS)
	if bus == -1:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, REC_BUS)
		AudioServer.set_bus_mute(bus, true)
		var echo := AudioEffectCapture.new()
		echo.buffer_length = 30.0
		AudioServer.add_bus_effect(bus, echo)

	var mic := AudioStreamMicrophone.new()
	var player := AudioStreamPlayer.new()
	player.stream = mic
	player.bus = REC_BUS
	add_child(player)
	player.play()
	OS.delay_msec(300)

	var cap: AudioEffectCapture = AudioServer.get_bus_effect(bus, 0)
	if cap == null:
		player.queue_free()
		return ""
	cap.clear_buffer()

	var frames: PackedVector2Array = PackedVector2Array()
	var t0 := Time.get_ticks_msec()
	while (Time.get_ticks_msec() - t0) < seconds * 1000:
		OS.delay_msec(40)
		var chunk := cap.get_buffer(cap.get_frames_available())
		if chunk.size() > 0:
			frames.append_array(chunk)
	player.stop()
	player.queue_free()
	if frames.size() < 2000:
		return ""

	var rate := int(AudioServer.get_mix_rate())
	var path := OS.get_temp_dir().path_join("lh_record_%d.wav" % randi())
	return _write_wav(path, frames, rate)


func _write_wav(path: String, frames: PackedVector2Array, rate: int) -> String:
	var data := PackedByteArray()
	data.resize(frames.size() * 2)
	for i in frames.size():
		var v: int = int(clampf(frames[i].x, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string("RIFF")
	f.store_32(36 + data.size())
	f.store_string("WAVEfmt ")
	f.store_32(16)
	f.store_16(1)
	f.store_16(1)
	f.store_32(rate)
	f.store_32(rate * 2)
	f.store_16(2)
	f.store_16(16)
	f.store_string("data")
	f.store_32(data.size())
	f.store_buffer(data)
	f.close()
	return path


func _recognize(wav: String) -> String:
	var out_path := OS.get_temp_dir().path_join("lh_asr_%d.txt" % randi())
	var r := _ps("""
Add-Type -AssemblyName System.Speech
try {
  $rec = New-Object System.Speech.Recognition.SpeechRecognitionEngine
  $rec.SetInputToWaveFile('WAV_PATH')
  $rec.LoadGrammar((New-Object System.Speech.Recognition.DictationGrammar))
  $sb = New-Object System.Text.StringBuilder
  while ($true) {
    try { $res = $rec.Recognize() } catch { break }
    if ($res -eq $null) { break }
    [void]$sb.Append($res.Text + ' ')
  }
  [System.IO.File]::WriteAllText('OUT_PATH', $sb.ToString(), [System.Text.Encoding]::UTF8)
  Write-Output 'ok'
} catch {
  [System.IO.File]::WriteAllText('OUT_PATH', '', [System.Text.Encoding]::UTF8)
  Write-Output ('ERR: ' + $_.Exception.Message)
} finally { if ($rec) { $rec.Dispose() } }
""".replace("WAV_PATH", wav.replace("'", "''")).replace("OUT_PATH", out_path.replace("'", "''")))
	var text := ""
	if FileAccess.file_exists(out_path):
		var f := FileAccess.open(out_path, FileAccess.READ)
		if f:
			text = f.get_as_text().strip_edges()
		DirAccess.remove_absolute(out_path)
	return text

func on_command(cmd: String, args: String) -> Dictionary:
	if cmd != "say":
		return {"ok": false, "output": "未知命令"}
	return run("voice_speak", {"text": args.strip_edges()})
