import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../config/colors.dart';
import '../../../core/network/api_service.dart';
import '../../../widgets/state_dropdown.dart';
import '../../../widgets/constituency_dropdown.dart';
import '../../../core/utils/error_handler.dart';



class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool isEditing = false;
  bool isLoading = false;
  bool isFetching = true;
  final Logger logger = Logger();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController profileIdController = TextEditingController();
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController constituencyController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();
  final TextEditingController designationController = TextEditingController();

  int? _selectedStateId;
  int? _selectedConstituencyId;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => isFetching = true);
    try {
      final profileData = await ApiService().getProfile();
      logger.d("Profile data fetched: $profileData");
      setState(() {
        nameController.text = profileData['userDetail']['name'] ?? '';
        phoneController.text = profileData['phoneNumber'] ?? '';
        emailController.text =
            profileData['userDetail']['email'] ?? profileData['email'] ?? '';
        profileIdController.text = profileData['id'] ?? '';
        userIdController.text = profileData['userDetail']['userId'] ?? '';
        stateController.text = profileData['userDetail']['state'] ?? '';
        constituencyController.text = profileData['userDetail']['constituency'] ?? '';
        referralCodeController.text = profileData['userDetail']['referralCode'] ?? '';
        designationController.text = profileData['userDetail']['designation'] ?? '';
        isFetching = false;
      });
    } catch (e) {
      logger.e("Failed to fetch profile: $e");
      setState(() => isFetching = false);
      final errorMsg = await ErrorHandler.getErrorMessage(e);
      _showSnackBar(errorMsg);
    }
  }

  Future<void> _updateProfile() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      _showSnackBar("Name and email cannot be empty");
      return;
    }
    if (stateController.text.isEmpty || constituencyController.text.isEmpty) {
      _showSnackBar("State and constituency cannot be empty");
      return;
    }
    setState(() => isLoading = true);
    try {
      final updatedProfile = await ApiService().patch(
        'user-details/update',
        {
          'name': nameController.text,
          'email': emailController.text,
          'state': stateController.text,
          'constituency': constituencyController.text,
          if (designationController.text.isNotEmpty) 'designation': designationController.text,
        },
      );
      logger.d("Profile updated: $updatedProfile");
      setState(() => isEditing = false);
      _showSnackBar("Profile updated successfully");
      Navigator.pop(context, true);
    } catch (e) {
      logger.e("Update error: $e");
      final errorMsg = await ErrorHandler.getErrorMessage(e);
      _showSnackBar(errorMsg);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: SharedColors.primary,
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!isFetching)
            IconButton(
              icon: Icon(isEditing ? Icons.check : Icons.edit, color: Colors.white),
              onPressed: () =>
              isEditing ? _updateProfile() : setState(() => isEditing = true),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isFetching) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildProfileField("Name", Icons.person, nameController, isEditable: true),
          _buildProfileField("Phone", Icons.phone, phoneController, isEditable: false),
          _buildProfileField("Email", Icons.email, emailController, isEditable: true),
          _buildStateField(),
          _buildConstituencyField(),
          _buildProfileField("Referral Code", Icons.card_giftcard, referralCodeController, isEditable: false),
          _buildProfileField("Designation", Icons.work, designationController, isEditable: true),
          _buildProfileField("Profile ID", Icons.badge, profileIdController, isEditable: false),
          _buildProfileField("User ID", Icons.perm_identity, userIdController, isEditable: false),
          if (isEditing) _buildUpdateButton(),
        ],
      ),
    );
  }

  Widget _buildProfileField(
      String label, IconData icon, TextEditingController controller,
      {bool isEditable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            enabled: isEditing && isEditable,
            keyboardType: _getKeyboardType(label),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey),
              border: _buildBorder(SharedColors.primaryDark),
              enabledBorder: _buildBorder(SharedColors.primaryDark),
              focusedBorder: _buildBorder(SharedColors.primaryDark),
              contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              filled: true,
              fillColor:
              isEditing && isEditable ? Colors.white : Colors.grey[100],
            ),
          ),
        ],
      ),
    );
  }

  TextInputType _getKeyboardType(String label) {
    switch (label) {
      case "Email":
        return TextInputType.emailAddress;
      case "Phone":
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  OutlineInputBorder _buildBorder([Color? color, double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: color ?? SharedColors.primaryDark,
        width: width,
      ),
    );
  }

  Widget _buildStateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("State", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          isEditing
              ? StateDropdown(
                  controller: stateController,
                  onStateSelected: (stateId) {
                    setState(() {
                      _selectedStateId = stateId;
                      constituencyController.clear();
                      _selectedConstituencyId = null;
                    });
                  },
                )
              : TextField(
                  controller: stateController,
                  enabled: false,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                    border: _buildBorder(SharedColors.primaryDark),
                    enabledBorder: _buildBorder(SharedColors.primaryDark),
                    focusedBorder: _buildBorder(SharedColors.primaryDark),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildConstituencyField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Constituency", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          isEditing
              ? ConstituencyDropdown(
                  controller: constituencyController,
                  stateId: _selectedStateId,
                  onConstituencySelected: (constituencyId) {
                    setState(() {
                      _selectedConstituencyId = constituencyId;
                    });
                  },
                )
              : TextField(
                  controller: constituencyController,
                  enabled: false,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_city, color: Colors.grey),
                    border: _buildBorder(SharedColors.primaryDark),
                    enabledBorder: _buildBorder(SharedColors.primaryDark),
                    focusedBorder: _buildBorder(SharedColors.primaryDark),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: ElevatedButton(
        onPressed: isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: SharedColors.primaryDark,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(color: Colors.white),
        )
            : const Text("UPDATE PROFILE", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    profileIdController.dispose();
    userIdController.dispose();
    stateController.dispose();
    constituencyController.dispose();
    referralCodeController.dispose();
    designationController.dispose();
    super.dispose();
  }
}
