import 'package:flutter/material.dart';
import 'package:focuz/app_theme.dart';
import 'package:focuz/services/auth_service.dart';
import 'package:flutter/services.dart';

class VerifyPhoneScreen extends StatefulWidget {
  final String email;
  
  const VerifyPhoneScreen({
    super.key, 
    required this.email,
  });

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;
  String? _errorMessage;
  bool _isVerified = false;
  int _resendTimer = 0;
  
  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }
  
  // Send verification code to phone
  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Format phone number
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+1$phoneNumber'; // Default to US country code if none provided
      }
      
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) {
          // Auto-verification completed (Android only)
          if (mounted) {
            setState(() {
              _isVerified = true;
              _isLoading = false;
            });
          }
        },
        verificationFailed: (exception) {
          // Handle verification failure
          if (mounted) {
            setState(() {
              _errorMessage = 'Verification failed: ${exception.message}';
              _isLoading = false;
            });
          }
        },
        codeSent: (verificationId, resendToken) {
          // Code sent to the phone number
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _isLoading = false;
              _resendTimer = 60; // 60 seconds countdown
            });
            
            // Start countdown timer
            _startResendTimer();
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // Timeout for auto-retrieval
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
          }
        },
      );
    } catch (e) {
      print('Error sending verification code: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  // Start countdown timer for resend code
  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startResendTimer();
      }
    });
  }
  
  // Verify the SMS code entered by user
  Future<void> _verifyCode() async {
    if (_codeController.text.length < 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit code';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final credential = await _authService.verifyPhoneCode(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      
      if (credential != null) {
        if (mounted) {
          setState(() {
            _isVerified = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Invalid verification code';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error verifying code: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone Number'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Security icon
                if (_isVerified)
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        size: 50,
                        color: Colors.green,
                      ),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _codeSent ? Icons.sms : Icons.phone,
                        size: 50,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Title and description
                Text(
                  _isVerified 
                      ? 'Phone Verified!'
                      : _codeSent 
                          ? 'Enter Verification Code' 
                          : 'Verify Your Phone',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _isVerified ? Colors.green : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  _isVerified 
                      ? 'Your phone number has been verified successfully. You can now reset your password.'
                      : _codeSent 
                          ? 'We\'ve sent a 6-digit verification code to your phone. Enter the code below.'
                          : 'For your security, we need to verify your phone number as a second factor for password reset.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_errorMessage != null) const SizedBox(height: 24),
                
                // Phone number field (if code not sent yet)
                if (!_codeSent && !_isVerified)
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                
                // Verification code field (if code sent)
                if (_codeSent && !_isVerified)
                  Column(
                    children: [
                      // Code input field
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          letterSpacing: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: '• • • • • •',
                          hintStyle: TextStyle(
                            fontSize: 24,
                            color: Colors.grey.shade400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        enabled: !_isLoading,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Resend code button
                      TextButton(
                        onPressed: _resendTimer > 0 || _isLoading
                            ? null
                            : _sendVerificationCode,
                        child: Text(
                          _resendTimer > 0
                              ? 'Resend code in $_resendTimer seconds'
                              : 'Resend verification code',
                          style: TextStyle(
                            color: _resendTimer > 0 
                                ? Colors.grey.shade600 
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 24),
                
                // Action button
                ElevatedButton(
                  onPressed: _isLoading 
                      ? null 
                      : _isVerified 
                          ? () => Navigator.pop(context, true) 
                          : _codeSent 
                              ? _verifyCode 
                              : _sendVerificationCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVerified ? Colors.green : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isVerified 
                              ? 'Continue' 
                              : _codeSent 
                                  ? 'Verify Code' 
                                  : 'Send Verification Code',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 