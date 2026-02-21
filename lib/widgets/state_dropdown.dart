import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../core/utils/error_handler.dart';

class StateDropdown extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Function(int?)? onStateSelected; // Callback to pass selected state ID

  const StateDropdown({
    Key? key,
    required this.controller,
    this.validator,
    this.onStateSelected,
  }) : super(key: key);

  @override
  _StateDropdownState createState() => _StateDropdownState();
}

class _StateDropdownState extends State<StateDropdown> {
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> filteredStates = [];
  bool isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchStates();
  }

  Future<void> _fetchStates() async {
    setState(() => isLoading = true);
    try {
      final result = await _apiService.fetchStates(limit: 100, offset: 0);
      setState(() {
        states = result;
        filteredStates = result;
      });
    } catch (e) {
      final errorMsg = await ErrorHandler.getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterStates(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredStates = states;
      } else {
        filteredStates = states
            .where((state) =>
                state['name'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showStateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Select State"),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search state...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _filterStates(value);
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: isLoading
                          ? Center(child: CircularProgressIndicator())
                          : filteredStates.isEmpty
                              ? Center(child: Text("No states found"))
                              : ListView.builder(
                                  itemCount: filteredStates.length,
                                  itemBuilder: (context, index) {
                                    final state = filteredStates[index];
                                    return ListTile(
                                      title: Text(state['name']),
                                      onTap: () {
                                        widget.controller.text = state['name'];
                                        widget.onStateSelected?.call(state['id']);
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      readOnly: true,
      onTap: _showStateDialog,
      decoration: InputDecoration(
        labelText: "Enter State*",
        prefixIcon: Icon(Icons.location_on),
        suffixIcon: Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      ),
    );
  }
}
