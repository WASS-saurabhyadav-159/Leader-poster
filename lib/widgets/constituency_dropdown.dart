import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../core/utils/error_handler.dart';

class ConstituencyDropdown extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final int? stateId;
  final Function(int?)? onConstituencySelected;

  const ConstituencyDropdown({
    Key? key,
    required this.controller,
    this.validator,
    this.stateId,
    this.onConstituencySelected,
  }) : super(key: key);

  @override
  _ConstituencyDropdownState createState() => _ConstituencyDropdownState();
}

class _ConstituencyDropdownState extends State<ConstituencyDropdown> {
  List<Map<String, dynamic>> constituencies = [];
  List<Map<String, dynamic>> filteredConstituencies = [];
  bool isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.stateId != null) {
      _fetchConstituencies();
    }
  }

  @override
  void didUpdateWidget(ConstituencyDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stateId != oldWidget.stateId) {
      widget.controller.clear();
      if (widget.stateId != null) {
        _fetchConstituencies();
      } else {
        setState(() {
          constituencies = [];
          filteredConstituencies = [];
        });
      }
    }
  }

  Future<void> _fetchConstituencies() async {
    if (widget.stateId == null) return;
    
    setState(() {
      isLoading = true;
      constituencies = [];
      filteredConstituencies = [];
    });
    try {
      final result = await _apiService.fetchConstituencies(
        stateId: widget.stateId!,
        limit: 100,
        offset: 0,
      );
      setState(() {
        constituencies = result;
        filteredConstituencies = result;
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

  void _filterConstituencies(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredConstituencies = constituencies;
      } else {
        filteredConstituencies = constituencies
            .where((constituency) =>
                constituency['name'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showConstituencyDialog() {
    if (widget.stateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a state first")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Select Constituency"),
              content: Container(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search constituency...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _filterConstituencies(value);
                        setDialogState(() {});
                      },
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: isLoading
                          ? Center(child: CircularProgressIndicator())
                          : filteredConstituencies.isEmpty
                              ? Center(child: Text("No constituencies found"))
                              : ListView.builder(
                                  itemCount: filteredConstituencies.length,
                                  itemBuilder: (context, index) {
                                    final constituency = filteredConstituencies[index];
                                    return ListTile(
                                      title: Text(constituency['name']),
                                      onTap: () {
                                        widget.controller.text = constituency['name'];
                                        widget.onConstituencySelected?.call(constituency['id']);
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
      onTap: _showConstituencyDialog,
      decoration: InputDecoration(
        labelText: "Enter Constituency*",
        prefixIcon: Icon(Icons.location_city),
        suffixIcon: Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      ),
    );
  }
}