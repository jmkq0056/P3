import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'voice_command_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  
  VoiceService._internal();
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedText = '';
  final VoiceCommandHandler _commandHandler = VoiceCommandHandler();
  
  // Stream controllers
  final _commandController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get commandStream => _commandController.stream;
  
  final _textController = StreamController<String>.broadcast();
  Stream<String> get textStream => _textController.stream;
  
  // API credentials removed for security
  final String _witApiToken = 'REMOVED_FOR_SECURITY';
  final String _openAIKey = 'REMOVED_FOR_SECURITY';
  
  // Initialize the voice service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      debugPrint('Voice service initialized');
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Failed to initialize voice service: $e');
      return false;
    }
  }
  
  // Start listening for voice commands
  Future<bool> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }
    
    if (_isListening) return true;
    
    try {
      debugPrint('Started listening for voice commands');
      _isListening = true;
      
      // Simulate voice recognition with a timer
      // In a real implementation, this would use speech-to-text
      Timer(const Duration(seconds: 2), () {
        final testCommands = [
          "Add 500 ml water",
          "Log my weight at 78.5 kg",
          "Record 30 minutes of running",
          "I ate a chicken salad with 450 calories",
          "I slept for 7 hours last night",
          "Track 2 cups of coffee",
          "Add my dinner - pasta with 650 calories",
          "Log 20 push-ups for 15 minutes",
        ];
        
        // Use a random command from the list
        final command = testCommands[DateTime.now().second % testCommands.length];
        _recognizedText = command;
        _textController.add(_recognizedText);
        
        _onRecognitionResult(command);
      });
      
      return true;
    } catch (e) {
      debugPrint('Failed to start listening: $e');
      return false;
    }
  }
  
  // Stop listening for voice commands
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      debugPrint('Stopped listening for voice commands');
      _isListening = false;
    } catch (e) {
      debugPrint('Failed to stop listening: $e');
    }
  }
  
  // Handle recognition results
  void _onRecognitionResult(String text) async {
    if (text.isEmpty) return;
    
    debugPrint('Recognized text: $text');
    
    try {
      // Use the VoiceCommandHandler to process the text with OpenAI
      final commandData = await _commandHandler.processVoiceCommand(text);
      
      // Add the command to the stream for UI display
      _commandController.add({
        'command': commandData,
        'text': text,
        'display_message': commandData['display_message'] ?? 'Processing command...'
      });
    } catch (e) {
      debugPrint('Error processing voice command: $e');
      _commandController.add({
        'error': e.toString(),
        'text': text,
        'display_message': 'Sorry, I couldn\'t understand that command.'
      });
    }
  }
  
  // Execute the command
  Future<String> executeCommand(Map<String, dynamic> commandData, BuildContext context) async {
    try {
      return await _commandHandler.handleCommand(commandData, context);
    } catch (e) {
      debugPrint('Error executing command: $e');
      return 'Error: $e';
    }
  }
  
  // Dispose stream controllers
  void dispose() {
    _commandController.close();
    _textController.close();
  }
} 