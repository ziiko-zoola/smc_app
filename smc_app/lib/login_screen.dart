import 'package:flutter/material.dart';
import 'api_service.dart';
import 'main.dart'; // To navigate to MainScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  bool _isLoading = false;
  int _step = 0; // 0: Phone, 1: OTP, 2: Name

  void _requestOTP() async {
    if (_phoneController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.requestOTP(_phoneController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification code is: ${res['otp']}'))); // For developer ease
      setState(() => _step = 1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOTP() async {
    if (_otpController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.verifyOTP(_phoneController.text.trim(), _otpController.text.trim());
      
      if (data['name'] == null || data['name'].toString().isEmpty) {
        setState(() => _step = 2);
      } else {
        _navigateToMain();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.verifyOTP(_phoneController.text.trim(), _otpController.text.trim(), name: _nameController.text.trim());
      _navigateToMain();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF192A45)),
      child: Center(
        child: Container(
          width: 500,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF33205B), Color(0xFF135B6D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('SMC FAMILY', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text('Developed by Ziiko', style: TextStyle(color: Colors.cyanAccent.withOpacity(0.9), fontStyle: FontStyle.italic)),
                  const SizedBox(height: 50),
                  
                  if (_step == 0) ...[
                    const Text('Enter your phone number to receive a 4-digit code', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                         hintText: 'Phone Number',
                         hintStyle: const TextStyle(color: Colors.white54),
                         filled: true,
                         fillColor: Colors.white12,
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                  ] else if (_step == 1) ...[
                    const Text('Enter the 4-digit verification code sent to your phone', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 10),
                      decoration: InputDecoration(
                         hintText: '0000',
                         hintStyle: const TextStyle(color: Colors.white24),
                         filled: true,
                         fillColor: Colors.white12,
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                  ] else if (_step == 2) ...[
                    const Text('Complete your profile by entering your full name', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                         hintText: 'Full Name',
                         hintStyle: const TextStyle(color: Colors.white54),
                         filled: true,
                         fillColor: Colors.white12,
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _isLoading ? null : (_step == 0 ? _requestOTP : (_step == 1 ? _verifyOTP : _submitName)),
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Color(0xFF192A45))
                          : Text(_step == 0 ? 'SEND CODE' : (_step == 1 ? 'VERIFY' : 'FINISH'), style: const TextStyle(color: Color(0xFF192A45), fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  if (_step > 0) ...[
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => setState(() => _step = 0),
                      child: const Text('Change Phone Number', style: TextStyle(color: Colors.white70))
                    )
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
