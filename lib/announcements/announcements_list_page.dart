import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_announcement_page.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text("All Announcements")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by title...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Filter by category',
                border: OutlineInputBorder(),
              ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: selectedDateRange,
              decoration: const InputDecoration(
                labelText: 'Filter by date',
                border: OutlineInputBorder(),
              ),
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No announcements found."));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final title = (doc['title'] ?? '').toString().toLowerCase();
                  final category = (doc['category'] ?? '').toString();
                  final timestamp = doc['createdAt'];
                  final createdAt = timestamp != null ? (timestamp as Timestamp).toDate() : null;

                  final matchesTitle = title.contains(_searchQuery);
                  final matchesCategory = selectedCategory == 'All' || category == selectedCategory;
                  final matchesDate = _matchesDateFilter(createdAt);

                  return matchesTitle && matchesCategory && matchesDate;
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final ann = docs[index];

                    return Dismissible(
                      key: Key(ann.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Confirm Delete"),
                            content: const Text("Are you sure you want to delete this announcement?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        await ann.reference.delete();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Announcement deleted")));
                      },
                      child: ListTile(
                        title: Text(ann['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ann['content']),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(ann['createdAt']),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Text(
                          ann['category'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditAnnouncementPage(doc: ann)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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
    return "Posted on ${_formatDate(date)}";
  }

  String _formatDate(DateTime date) {
    return "${_monthName(date.month)} ${date.day}, ${date.year} at ${_formatTime(date)}";
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $suffix";
  }

  String _monthName(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
}
