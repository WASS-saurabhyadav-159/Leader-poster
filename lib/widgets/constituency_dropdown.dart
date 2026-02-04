import 'package:flutter/material.dart';

class ConstituencyDropdown extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final List<String> constituencies;

  const ConstituencyDropdown({
    Key? key,
    required this.controller,
    this.validator,
    required this.constituencies,
  }) : super(key: key);

  @override
  _ConstituencyDropdownState createState() => _ConstituencyDropdownState();
}

class _ConstituencyDropdownState extends State<ConstituencyDropdown> {
  List<String> filteredConstituencies = [];
  bool isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    filteredConstituencies = widget.constituencies;
  }

  void _filterConstituencies(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredConstituencies = widget.constituencies;
      } else {
        filteredConstituencies = widget.constituencies
            .where((constituency) =>
                constituency.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _showConstituencyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                        setState(() {});
                      },
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredConstituencies.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(filteredConstituencies[index]),
                            onTap: () {
                              widget.controller.text = filteredConstituencies[index];
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