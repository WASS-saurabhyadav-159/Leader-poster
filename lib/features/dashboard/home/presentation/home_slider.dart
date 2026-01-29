import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_service.dart';


class HomeSlider extends StatefulWidget {
  final List<dynamic> banners; // Change to final field

  const HomeSlider({super.key, required this.banners}); // Correct constructor

  @override
  State<HomeSlider> createState() => _HomeSliderState();
}

class _HomeSliderState extends State<HomeSlider> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
  }

  void _handleBannerTap(Map<String, dynamic> banner) {
    final link = banner['link'];
    final linkType = banner['linkType'];

    if (link == null || linkType == 'DEFAULT') return;

    if (linkType == 'EXTERNAL') {
      final url = Uri.parse(link.startsWith('http') ? link : 'https://$link');
      launchUrl(url);
    } else if (linkType == 'INTERNAL') {
      // For internal links, you can show the image in a dialog or navigate
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Image.network(
            banner['image'],
            fit: BoxFit.contain,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.banners.isEmpty // Use widget.banners instead of local banners
              ? const Center(child: CircularProgressIndicator())
              : CarouselSlider.builder(
            itemCount: widget.banners.length, // Use widget.banners.length
            options: CarouselOptions(
              height: 160,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, _) {
              final banner = widget.banners[index]; // Use widget.banners[index]
              return GestureDetector(
                onTap: () => _handleBannerTap(banner),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    banner['image'],
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image),
                  ),
                ),
              );
            },
          ),

          // Dots Indicator
          if (widget.banners.isNotEmpty) // Use widget.banners.isNotEmpty
            Positioned(
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.banners.length, // Use widget.banners.length
                      (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentIndex == index ? 12.0 : 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index ? Colors.purple : Colors.white,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}