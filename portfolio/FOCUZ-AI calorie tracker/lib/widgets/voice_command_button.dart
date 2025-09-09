import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/voice_service.dart';
import '../services/voice_command_handler.dart';

class VoiceCommandButton extends StatefulWidget {
  const VoiceCommandButton({super.key});

  @override
  VoiceCommandButtonState createState() => VoiceCommandButtonState();
}

class VoiceCommandButtonState extends State<VoiceCommandButton> with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final VoiceCommandHandler _commandHandler = VoiceCommandHandler();
  
  bool _isListening = false;
  late AnimationController _animationController;
  StreamSubscription? _commandSubscription;
  StreamSubscription? _textSubscription;
  String? _lastCommand;
  String _recognizedText = '';
  Timer? _feedbackTimer;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Initialize voice service
    _voiceService.initialize();
    
    // Listen for recognized text updates
    _textSubscription = _voiceService.textStream.listen((text) {
      setState(() {
        _recognizedText = text;
      });
    });
    
    // Listen for commands
    _commandSubscription = _voiceService.commandStream.listen((command) {
      setState(() {
        _lastCommand = command['text'] as String;
      });
      
      // Handle the command
      _commandHandler.handleCommand(command, context);
      
      // Clear the feedback after a few seconds
      _feedbackTimer?.cancel();
      _feedbackTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _lastCommand = null;
          });
        }
      });
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _commandSubscription?.cancel();
    _textSubscription?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }
  
  void _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      _animationController.stop();
    } else {
      final success = await _voiceService.startListening();
      if (success) {
        _animationController.repeat(reverse: true);
      }
    }
    
    setState(() {
      _isListening = !_isListening;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show recognized text during listening
        if (_isListening && _recognizedText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recognized:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _recognizedText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        
        // Show feedback if there's a last command
        if (_lastCommand != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Command executed:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"$_lastCommand"',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        
        // Voice command button
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FloatingActionButton(
              onPressed: _toggleListening,
              tooltip: _isListening ? 'Stop Listening' : 'Voice Commands',
              backgroundColor: _isListening 
                  ? Theme.of(context).colorScheme.error 
                  : Theme.of(context).colorScheme.primary,
              child: _isListening
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated circles
                        ...List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 24.0 + (_animationController.value * (index + 1) * 8.0),
                            height: 24.0 + (_animationController.value * (index + 1) * 8.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3 - (index * 0.1)),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                        // Microphone icon
                        const FaIcon(FontAwesomeIcons.microphone, color: Colors.white),
                      ],
                    )
                  : const FaIcon(FontAwesomeIcons.microphone),
            );
          },
        ),
      ],
    );
  }
} 