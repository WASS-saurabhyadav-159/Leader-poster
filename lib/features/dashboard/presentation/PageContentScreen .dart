import 'package:flutter/material.dart';


import '../../../core/network/api_service.dart';

class PageContentScreen extends StatefulWidget {
  final int pageId;

  const PageContentScreen({super.key, required this.pageId});

  @override
  State<PageContentScreen> createState() => _PageContentScreenState();
}

class _PageContentScreenState extends State<PageContentScreen> {
  final ApiService _apiService = ApiService();
  late Future<PageContent> _pageContentFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageContentFuture = _fetchPageContent();
  }

  Future<PageContent> _fetchPageContent() async {
    try {
      final content = await _apiService.getPageContent(widget.pageId);
      setState(() => _isLoading = false);
      return content;
    } catch (e) {
      setState(() => _isLoading = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<PageContent>(
          future: _pageContentFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!.title);
            }
            return const Text('Loading...');
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<PageContent>(
        future: _pageContentFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pageContent = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page ID (optional - you can remove this if not needed)
                // Text(
                //   'Page ID: ${pageContent.id}',
                //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
                //     color: Colors.grey,
                //   ),
                // ),
                const SizedBox(height: 8),

                // Title (in body - you can remove if you only want it in AppBar)
                Text(
                  pageContent.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  pageContent.desc,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PageContent {
  final int id;
  final String title;
  final String desc;

  PageContent({
    required this.id,
    required this.title,
    required this.desc,
  });

  factory PageContent.fromJson(Map<String, dynamic> json) {
    return PageContent(
      id: json['id'],
      title: json['title'],
      desc: json['desc'],
    );
  }
}