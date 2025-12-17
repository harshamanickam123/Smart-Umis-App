import 'package:flutter/material.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key}); // Fix 1: Added key parameter

  @override
  State<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState(); // Fix 2: Made State class public
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  bool _isListening = false;

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });
    // Add your voice recognition logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 100,
              color: _isListening ? Colors.red : const Color(0xFF2E7D32),
            ),
            const SizedBox(height: 20), // Fix 3: Added const
            Text(
              _isListening ? 'Listening...' : 'Tap to speak',
              style: const TextStyle(fontSize: 20), // Fix 4: Added const
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _toggleListening,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(_isListening ? 'Stop' : 'Start'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
