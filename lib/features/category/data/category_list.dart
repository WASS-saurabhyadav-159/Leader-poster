// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
//
// import '../../../config/colors.dart';
// import '../domain/category.dart';
// import '../presentation/category_screen.dart';
// import '../presentation/events.dart';
//
//
// class CategoryScreen extends StatefulWidget {
//   final Category category;
//
//   const CategoryScreen(this.category, {super.key});
//
//   @override
//   State<CategoryScreen> createState() => _CategoryScreenState();
// }
//
// class _CategoryScreenState extends State<CategoryScreen> {
//   late Category category;
//   late List<String> events;
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     category = widget.category;
//     events = category.events.keys.toList();
//     fetchCategoryDetails(); // 🔹 Fetch updated details
//   }
//
//   Future<void> fetchCategoryDetails() async {
//     try {
//       Dio dio = Dio();
//       final response = await dio.get(
//         "https://poliposter.drpauls.in:5920/api/v1/categories/${category.id}",
//         options: Options(
//           headers: {"Content-Type": "application/json"},
//         ),
//       );
//
//       if (response.statusCode == 200) {
//         setState(() {
//           category = Category.fromJson(response.data);
//           events = category.events.keys.toList();
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Error fetching category details: $e");
//       setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     List<String> categoryItems = category.events[events[0]]!; // Default first event items
//
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: SharedColors.primary,
//         foregroundColor: Colors.white,
//         title: Text(
//           category.name,
//           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
//         ),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Container(
//               color: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
//               child: EventSelector(events),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: GridView.builder(
//                   itemCount: categoryItems.length,
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     crossAxisSpacing: 8,
//                     mainAxisSpacing: 8,
//                   ),
//                   itemBuilder: (_, ind) {
//                     // return CategoryItemDisplay(categoryItems[ind]);
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
