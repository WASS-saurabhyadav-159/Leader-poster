import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/models/TodaySpecial.dart';
import '../../../../core/network/api_service.dart';
import '../../../auth/data/RecentFinishedPoster.dart';
import '../../../auth/presentation/VideoSection.dart';
import '../../../category/domain/category.dart';
import '../../../category/presentation/AllRecentFinishedPage.dart';
import '../../../category/presentation/AllTodaySpecialPage.dart';
import '../../../category/presentation/Allbannershowpage.dart';
import '../../../category/presentation/TodaySpecialSection.dart';
import '../../../category/presentation/RecentFinishedSection.dart';
import '../../../category/presentation/edit_banner_screen.dart';
import '../../presentation/VideoPlayerPopup.dart';
import 'category_highlight.dart';
import 'home_slider.dart';
import '../../../../config/colors.dart';
// Add these imports for VideoSection


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  List<Category> allCategories = [];
  List<dynamic> bannerList = [];
  List<TodaySpecial> todaySpecialList = [];
  List<RecentFinishedPoster> recentFinishedList = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _initialLoadComplete = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!_initialLoadComplete) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_initialLoadComplete) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final apiService = ApiService();
      final results = await Future.wait([
        apiService.fetchCategories(),
        apiService.getBanners(context: context, limit: 10, offset: 0),
        _fetchTodaySpecial(apiService),
        _fetchRecentFinished(apiService),
      ]);

      setState(() {
        allCategories = results[0] as List<Category>;
        bannerList = results[1] as List<dynamic>;
        todaySpecialList = results[2] as List<TodaySpecial>;
        recentFinishedList = results[3] as List<RecentFinishedPoster>;
        _isLoading = false;
        _initialLoadComplete = true;
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<List<TodaySpecial>> _fetchTodaySpecial(ApiService apiService) async {
    try {
      final response = await apiService.fetchTodaySpecial();
      return response;
    } catch (e) {
      debugPrint("Error fetching today's special: $e");
      return [];
    }
  }

  Future<List<RecentFinishedPoster>> _fetchRecentFinished(ApiService apiService) async {
    try {
      final response = await apiService.fetchRecentFinishedPosters();
      return response;
    } catch (e) {
      debugPrint("Error fetching recent finished posters: $e");
      return [];
    }
  }

  void _handleViewAllTodaySpecial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllTodaySpecialPage(
          todaySpecialList: todaySpecialList,
        ),
      ),
    );
  }

  void _handleViewAllRecentFinished() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllRecentFinishedPage(
          recentFinishedList: recentFinishedList,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: _isLoading
          ? const _HomeShimmer()
          : _hasError
          ? _buildErrorWidget()
          : RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Banner and Today's Special Section
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  HomeSlider(banners: bannerList),
                  const SizedBox(height: 16),

                  // Today's Special Section
                  if (todaySpecialList.isNotEmpty)
                    TodaySpecialSection(
                      todaySpecialList: todaySpecialList,
                      onViewAll: _handleViewAllTodaySpecial,
                      onItemTap: (todaySpecial) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SocialMediaDetailsPage(
                              assetPath: todaySpecial.poster,
                              categoryId: "",
                              initialPosition: todaySpecial.position ?? "RIGHT",
                              posterId: todaySpecial.id,
                              topDefNum: todaySpecial.topDefNum,
                              selfDefNum: todaySpecial.selfDefNum,
                              bottomDefNum: todaySpecial.bottomDefNum,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Categories List
            if (allCategories.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => CategoryHighlightDisplay(
                    allCategories[index],
                    key: ValueKey(allCategories[index].id),
                  ),
                  childCount: allCategories.length,
                ),
              )
            else
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No categories found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),

            // Recent Finished Section - Below categories
            if (recentFinishedList.isNotEmpty)
              SliverToBoxAdapter(
                child: RecentFinishedSection(
                  recentFinishedList: recentFinishedList,
                  onViewAll: _handleViewAllRecentFinished,
                  onItemTap: (recentPoster) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SocialMediaDetailsPage(
                          assetPath: recentPoster.poster,
                          categoryId: recentPoster.categoryId,
                          initialPosition: recentPoster.position,
                          posterId: recentPoster.id,
                          topDefNum: recentPoster.topDefNum,
                          selfDefNum: recentPoster.selfDefNum,
                          bottomDefNum: recentPoster.bottomDefNum,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Video Section - Below Recent Finished
            SliverToBoxAdapter(
              child: VideoSection(), // Add VideoSection here
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 12),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Add shimmer for Today's Special section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 120,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              children: List.generate(
                4,
                    (index) => Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Categories shimmer
        ...List.generate(
          3,
              (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Add shimmer for Recent Finished section (now below categories)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              children: List.generate(
                4,
                    (index) => Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Add shimmer for Video Section
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 120,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              children: List.generate(
                4,
                    (index) => Container(
                  width: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

