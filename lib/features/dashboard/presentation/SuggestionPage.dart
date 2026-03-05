import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../config/colors.dart';
import '../../../core/network/api_service.dart';

class SuggestionPage extends StatefulWidget {
  const SuggestionPage({super.key});

  @override
  State<SuggestionPage> createState() => _SuggestionPageState();
}

class _SuggestionPageState extends State<SuggestionPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  File? _selectedImage;
  DateTime? _selectedDate;

  bool isLoading = false;
  int maxLength = 300;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(() {
      setState(() {
        _charCount = _descriptionController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _descriptionController.removeListener(() {});
    _titleController.dispose();
    _descriptionController.dispose();
    _eventDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE50914),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _eventDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: SharedColors.dialogBorderColor,
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Suggestions",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Top Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lightbulb,
                        color: Color(0xFFE50914), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Not able to find poster for a event ?\nLet us know, Our team will update it.",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// Title
              const Text(
                "Event Title",
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "Enter Event Title",
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color(0xFFE50914), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.grey.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// Description
              const Text(
                "Event Description",
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLength: maxLength,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Write your suggestion...",
                  counterText: "",
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color(0xFFE50914), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.grey.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "$_charCount/$maxLength",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Event Date
              const Text(
                "Event Date",
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _eventDateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  hintText: "Select Event Date",
                  suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFFE50914)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color(0xFFE50914), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.grey.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Attach Screenshot Button
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE50914),
                      width: 1.5,
                    ),
                    color: Colors.grey.shade100,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.attach_file,
                          color: Color(0xFFE50914)),
                      SizedBox(width: 10),
                      Text(
                        "Attach Screenshot",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    ],
                  ),
                ),
              ),

              /// Show Selected Image
              if (_selectedImage != null) ...[
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE50914),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 40),

              /// Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE50914),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isLoading ? null : _submitSuggestion,
                  child: isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text(
                    "SUBMIT SUGGESTION",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitSuggestion() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE50914),
          content: Text("Please fill all fields"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _apiService.submitSuggestion(
        title: _titleController.text,
        desc: _descriptionController.text,
        file: _selectedImage,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle,
                  color: Color(0xFFE50914), size: 60),
              SizedBox(height: 15),
              Text(
                "Thank You!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Your suggestion has been sent successfully.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              )
            ],
          ),
        ),
      );

      // Auto close dialog after 3 seconds and navigate back
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Navigate to previous page
        }
      });

      // Clear form
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFFE50914),
          content: Text("Failed to submit suggestion: ${e.toString()}"),
        ),
      );
    }
  }

}
