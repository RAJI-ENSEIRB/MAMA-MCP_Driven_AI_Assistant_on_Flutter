import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class STTW extends StatefulWidget {
  STTW({Key? key, this.onTextRecognized, this.theme}) : super(key: key);

  final Function(String text)? onTextRecognized;
  final ThemeData? theme;
  @override
  _STTW createState() => _STTW();
}

class _STTW extends State<STTW> {
  SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isListening = false;
  String _conversation = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) return;

    setState(() {
      _isListening = true;
    });

    await _speechToText.listen(
      onResult: _onSpeechResult,
      pauseFor: Duration(seconds: 5),
      listenFor: Duration(seconds: 30),
    );

    _speechToText.statusListener = (status) {
      if (status == 'notListening' && _isListening) {
        Future.delayed(Duration(milliseconds: 500), () {
          if (_isListening) {
            _startListening();
          }
        });
      }
    };
  }

  void _stopListening() async {
    setState(() {
      _isListening = false;
      //widget.onTextRecognized?.call(_conversation);
      _conversation = "";
      _lastWords = "";
    });
    await _speechToText.stop();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;

      if (result.finalResult) {
        _conversation = '$_lastWords ';
        widget.onTextRecognized?.call(_conversation);
        _lastWords = "";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _isListening
            ? Colors.red.shade50
            : theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          _isListening ? Icons.stop_rounded : Icons.mic_rounded,
          color: _isListening ? Colors.red : theme.colorScheme.primary,
        ),
        onPressed: _speechToText.isNotListening
            ? _startListening
            : _stopListening,
        tooltip: 'Listen',
      ),
    );
  }
}
