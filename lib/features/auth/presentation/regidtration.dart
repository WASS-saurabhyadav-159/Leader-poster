import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../../config/colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/local_storage.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isPhoneVerified = false;
  bool _showVerifyButton = false;
  bool _isSendingOtp = false;
  bool _otpVerified = false; // Track if OTP is verified but not yet registered

  bool _isOtpDialogOpen = false; // Only one dialog at a time

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_checkPhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_checkPhoneNumber);
    super.dispose();
  }

  void _checkPhoneNumber() {
    setState(() {
      _showVerifyButton = _phoneController.text.length == 10;
    });
  }

  Future<bool> _sendOtp({bool isResend = false}) async {
    if (_phoneController.text.length != 10) return false;

    setState(() => _isSendingOtp = true);

    try {
      final String masterAppId = await getAppMasterId();
      ApiService apiService = ApiService();
      final response = await apiService.sendOtpForRegistration(
        phoneNumber: _phoneController.text.trim(),
        masterAppId: masterAppId,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'OTP sent successfully')),
        );
        if (!isResend) {
          _showOtpDialog();
        }
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send OTP")),
        );
        return false;
      }
    } on DioException catch (e) {
      String errorMessage = "Failed to send OTP";
      if (e.response != null) {
        if (e.response?.statusCode == 409) {
          errorMessage = e.response?.data?['message'] ?? "Phone number already exists";
        } else if (e.response?.statusCode == 400) {
          errorMessage = e.response?.data?['message'] ?? "Invalid phone number or masterAppId";
        } else {
          errorMessage += ": ${e.response?.data?['message'] ?? e.response?.statusMessage ?? 'Unknown error'}";
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      return false;
    } finally {
      setState(() => _isSendingOtp = false);
    }
  }

  void _showOtpDialog() {
    if (_isOtpDialogOpen) {
      return;
    }
    _isOtpDialogOpen = true;

    int _resendSeconds = 30;
    late StateSetter dialogState;
    Timer? _resendTimer;

    void startResendTimer() {
      _resendSeconds = 30;
      _resendTimer?.cancel();
      _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_resendSeconds <= 0) {
          timer.cancel();
        } else {
          dialogState(() {
            _resendSeconds--;
          });
        }
      });
    }

    startResendTimer();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogState = setState;
            return AlertDialog(
              title: Text("Verify OTP"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Enter 6-digit OTP sent to ${_phoneController.text}"),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: "OTP",
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                  ),
                  SizedBox(height: 16),
                  _resendSeconds == 0
                      ? TextButton(
                    onPressed: () async {
                      bool success = await _sendOtp(isResend: true);
                      if (success) {
                        setState(() => _resendSeconds = 30);
                        startResendTimer();
                      }
                      // On fail, do not reset timer, allow retry immediately
                    },
                    child: Text("Resend OTP"),
                  )
                      : Text("Resend OTP in $_resendSeconds sec"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _resendTimer?.cancel();
                    Navigator.pop(context);
                    _isOtpDialogOpen = false;
                  },
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  child: Text("Verify"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SharedColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _isOtpDialogOpen = false;
    });
  }
  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid 6-digit OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      ApiService apiService = ApiService();
      final response = await apiService.verifyOtpForRegistration(
        phoneNumber: _phoneController.text.trim(),
        otp: _otpController.text.trim(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isPhoneVerified = true;
          _otpVerified = true;
          _showVerifyButton = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'OTP verified successfully')),
        );
        // Close the OTP dialog popup after successful verification
        if (_isOtpDialogOpen) {
          Navigator.pop(context);
          _isOtpDialogOpen = false;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP verification failed")),
        );
      }
    } on DioException catch (e) {
      String errorMessage = "OTP verification failed";
      if (e.response != null) {
        if (e.response?.statusCode == 400) {
          errorMessage = e.response?.data?['message'] ?? "Invalid OTP";
        } else if (e.response?.statusCode == 410) {
          errorMessage = e.response?.data?['message'] ?? "OTP expired";
        } else {
          errorMessage +=
          ": ${e.response?.data?['message'] ?? e.response?.statusMessage ?? 'Invalid OTP'}";
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }



  void _registerUser() async {
    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please verify your phone number first")),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final String masterAppId = await getAppMasterId();
        ApiService apiService = ApiService();
        final response = await apiService.registerUser(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          masterAppId: masterAppId,
          email: _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
        );

        if (response['success'] == true || response['id'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration Successful!")),
          );
          Navigator.pop(context); // Navigate only here on explicit Register button press
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Registration failed: ${response['message']}")),
          );
        }
      } on DioException catch (e) {
        String errorMessage = "Registration Failed";
        if (e.response != null) {
          errorMessage += ": ${e.response?.data?['message'] ?? e.response?.statusMessage ?? 'Invalid request'}";
          debugPrint("Full error response: ${e.response?.data}");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.transparent,
                    backgroundImage: AssetImage("assets/app_icon.png"),
                  ),
                  const SizedBox(height: 30),
                  _buildTextField(
                    controller: _nameController,
                    label: "Enter Name*",
                    icon: Icons.person,
                    validator: (value) => value!.isEmpty ? "Name is required" : null,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _emailController,
                    label: "Enter Email *",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isNotEmpty && !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _phoneController,
                          label: "Enter Phone Number*",
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value!.isEmpty) return "Phone number is required";
                            if (value.length != 10) return "Enter a valid 10-digit phone number";
                            return null;
                          },
                          enabled: !_isPhoneVerified,
                        ),
                      ),
                      if (_showVerifyButton && !_isPhoneVerified)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _isSendingOtp
                              ? CircularProgressIndicator()
                              : ElevatedButton(
                            onPressed: _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SharedColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Send OTP",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      if (_isPhoneVerified)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.verified, color: Colors.green, size: 28),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPhoneVerified ? SharedColors.primary : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isLoading ? null : _registerUser,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        _isPhoneVerified ? "Register Now" : "Verify OTP to Register",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      ),
    );
  }
}
