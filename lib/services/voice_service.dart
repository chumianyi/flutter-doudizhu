import 'dart:js_interop';

@JS('speechSynthesis')
external SpeechSynthesis? get speechSynthesis;

@JS()
@staticInterop
class SpeechSynthesis {}

extension SpeechSynthesisExtension on SpeechSynthesis {
  @JS('speak')
  external void speak(SpeechSynthesisUtterance utterance);

  @JS('cancel')
  external void cancel();
}

@JS()
@staticInterop
class SpeechSynthesisUtterance {
  external factory SpeechSynthesisUtterance(String text);
}

extension SpeechSynthesisUtteranceExtension on SpeechSynthesisUtterance {
  external set lang(String value);
  external set rate(double value);
  external set pitch(double value);
  external set volume(double value);
}

class VoiceService {
  static bool _enabled = true;

  static void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      speechSynthesis?.cancel();
    }
  }

  static bool get isEnabled => _enabled;

  static void speak(String text) {
    if (!_enabled) return;
    try {
      final synth = speechSynthesis;
      if (synth == null) return;
      synth.cancel();
      final utterance = SpeechSynthesisUtterance(text);
      utterance.lang = 'zh-CN';
      utterance.rate = 1.1;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;
      synth.speak(utterance);
    } catch (_) {}
  }

  static void playCardVoice(String cardDisplay) {
    speak(cardDisplay);
  }

  static void playPass() {
    speak('不要');
  }

  static void playLandlord() {
    speak('地主');
  }

  static void playFarmerWin() {
    speak('农民赢了');
  }

  static void playLandlordWin() {
    speak('地主赢了');
  }
}
