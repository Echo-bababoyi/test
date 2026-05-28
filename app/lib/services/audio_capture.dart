import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:web_audio' as wa;

class AudioCapture {
  static const int targetSampleRate = 16000;
  static const int frameSamples = 640; // 40ms @ 16k

  wa.AudioContext? _ctx;
  html.MediaStream? _stream;
  wa.MediaStreamAudioSourceNode? _source;
  wa.ScriptProcessorNode? _processor;
  final List<int> _int16Buf = [];

  Future<void> start() async {
    if (_ctx != null) return;
    _stream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': {
      'channelCount': 1,
      'echoCancellation': true,
      'noiseSuppression': true,
    }});
    _ctx = wa.AudioContext();
    _source = _ctx!.createMediaStreamSource(_stream!);
    _processor = _ctx!.createScriptProcessor(4096, 1, 1);
    final srcRate = _ctx!.sampleRate!.toInt();

    // 静音中转，防止麦克风回放
    final gain = _ctx!.createGain();
    gain.gain!.value = 0;

    _processor!.addEventListener('audioprocess', (event) {
      final e = event as wa.AudioProcessingEvent;
      final input = e.inputBuffer!.getChannelData(0);
      final down = _downsample(input, srcRate, targetSampleRate);
      for (final f in down) {
        final s = (f * 32767).clamp(-32768, 32767).toInt();
        _int16Buf.add(s);
      }
    });

    _source!.connectNode(_processor!);
    _processor!.connectNode(gain);
    gain.connectNode(_ctx!.destination!);
  }

  Future<Uint8List> stop() async {
    try { _processor?.disconnect(); } catch (_) {}
    try { _source?.disconnect(); } catch (_) {}
    try { await _ctx?.close(); } catch (_) {}
    for (final track in _stream?.getTracks() ?? const []) {
      track.stop();
    }
    final bytes = Uint8List(_int16Buf.length * 2);
    final view = ByteData.view(bytes.buffer);
    for (int i = 0; i < _int16Buf.length; i++) {
      view.setInt16(i * 2, _int16Buf[i], Endian.little);
    }
    _int16Buf.clear();
    return bytes;
  }

  static List<Uint8List> frame(Uint8List pcm) {
    const int frameBytes = frameSamples * 2; // 1280 bytes
    final out = <Uint8List>[];
    for (int i = 0; i < pcm.length; i += frameBytes) {
      final end = (i + frameBytes < pcm.length) ? i + frameBytes : pcm.length;
      out.add(Uint8List.sublistView(pcm, i, end));
    }
    return out;
  }

  static Float32List _downsample(Float32List input, int srcRate, int dstRate) {
    if (srcRate == dstRate) return input;
    final ratio = srcRate / dstRate;
    final outLen = (input.length / ratio).floor();
    final out = Float32List(outLen);
    for (int i = 0; i < outLen; i++) {
      final src = i * ratio;
      final lo = src.floor();
      final hi = (lo + 1).clamp(0, input.length - 1);
      final frac = src - lo;
      out[i] = input[lo] * (1 - frac) + input[hi] * frac;
    }
    return out;
  }
}
