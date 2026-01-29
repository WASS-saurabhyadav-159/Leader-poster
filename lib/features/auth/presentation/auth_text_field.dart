import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for input formatters

import '../../../config/colors.dart';

class AuthTextField extends StatefulWidget {
  final String? iconName;
  final TextEditingController? controller;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const AuthTextField(
      this.hint, {
        super.key,
        this.iconName,
        this.controller,
        this.obscureText = false,
        this.keyboardType = TextInputType.text, // Default to text input
        this.inputFormatters,
      });

  @override
  _AuthTextFieldState createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    if (widget.iconName != null) {
      children.addAll([
        Image.asset(widget.iconName!, width: 16.0, height: 16.0),
        const SizedBox(width: 12.0),
        Container(height: 25, width: 1.0, decoration: const BoxDecoration(color: Colors.black)),
        const SizedBox(width: 12.0),
      ]);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: SharedColors.primary,
        ),
        borderRadius: BorderRadius.circular(2.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...children,
          const SizedBox(width: 0, height: 25),
          Expanded(
            child: TextField(
              obscureText: _obscureText,
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              decoration: InputDecoration.collapsed(
                hintText: widget.hint,
                hintStyle: TextStyle(color: SharedColors.hintColor),
              ),
            ),
          ),
          if (widget.obscureText)
            GestureDetector(
              onTap: _togglePasswordVisibility,
              child: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}