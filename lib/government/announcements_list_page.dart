import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../components/shared_app_bar.dart';
import '../components/role_protected_page.dart';
import '../services/theme_service.dart';
import '../citizen/announcement_details_page.dart';
import '../services/database_service.dart';

class AnnouncementsListPage extends StatefulWidget {
  const AnnouncementsListPage({super.key});

  @override
  State<AnnouncementsListPage> createState() => _AnnouncementsListPageState();
}

class _AnnouncementsListPageState extends State<AnnouncementsListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String selectedCategory = 'All';
  String selectedDateRange = 'All';

  final List<String> categoryOptions = [
    'All',
    'Health',
    'Infrastructure',
    'Education',
    'Safety',
  ];

  final List<String> dateRangeOptions = [
    'All',
    'Today',
    'This Week',
  ];

  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: 'citizen',
      child: Scaffold(
        appBar: const SharedAppBar(title: "Announcements"),
        body: Column(
          children: [
            // Search & Filter Card
            Card(
              margin: const EdgeInsets.all(12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: ThemeService.inputDecoration(
                        "Search announcements",
                        prefixIcon: Icons.search,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: ThemeService.inputDecoration("Category"),
                            items: categoryOptions.map((cat) {
                              return DropdownMenuItem(value: cat, child: Text(cat));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCategory = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedDateRange,
                            decoration: ThemeService.inputDecoration("Date"),
                            items: dateRangeOptions.map((option) {
                              return DropdownMenuItem(value: option, child: Text(option));
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDateRange = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Announcements List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: DatabaseService.getAnnouncementsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.announcement_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text("No announcements found"),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final title = (doc['title'] ?? '').toString().toLowerCase();
                    final content = (doc['content'] ?? '').toString().toLowerCase();
                    final category = (doc['category'] ?? '').toString();
                    final timestamp = doc['createdAt'];
                    final createdAt = timestamp != null ? (timestamp as Timestamp).toDate() : null;

                    final matchesSearch = title.contains(_searchQuery) || content.contains(_searchQuery);
                    final matchesCategory = selectedCategory == 'All' || category == selectedCategory;
                    final matchesDate = _matchesDateFilter(createdAt);

                    return matchesSearch && matchesCategory && matchesDate;
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text("No matching announcements found"),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                selectedCategory = 'All';
                                selectedDateRange = 'All';
                              });
                            },
                            child: const Text("Clear Filters"),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final ann = docs[index];
                      final title = ann['title'] ?? 'No Title';
                      final content = ann['content'] ?? 'No Content';
                      final category = ann['category'] ?? '';
                      final timestamp = ann['createdAt'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AnnouncementDetailsPage(
                                  announcementId: ann.id,
                                  announcement: ann.data() as Map<String, dynamic>,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (category.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(category),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    const Spacer(),
                                    Text(
                                      _formatTimestamp(timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(content),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Colors.green;
      case 'infrastructure':
        return Colors.blue;
      case 'education':
        return Colors.orange;
      case 'safety':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _matchesDateFilter(DateTime? date) {
    if (date == null || selectedDateRange == 'All') return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final input = DateTime(date.year, date.month, date.day);

    if (selectedDateRange == 'Today') {
      return input == today;
    } else if (selectedDateRange == 'This Week') {
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return input.isAfter(weekStart.subtract(const Duration(days: 1))) &&
             input.isBefore(weekEnd.add(const Duration(days: 1)));
    }

    return true;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Date unknown';
    final date = (timestamp as Timestamp).toDate();
    return _formatDate(date);
  }

  String _formatDate(DateTime date) {
    return "${_monthName(date.month)} ${date.day}, ${date.year}";
  }

  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
}
