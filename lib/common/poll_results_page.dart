import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/theme_service.dart';

class PollResultsPage extends StatefulWidget {
  final String pollId;
  final String question;

  const PollResultsPage({super.key, required this.pollId, required this.question});

  @override
  State<PollResultsPage> createState() => _PollResultsPageState();
}

class _PollResultsPageState extends State<PollResultsPage> {
  bool isLoading = true;
  Map<String, dynamic> pollData = {};
  int totalVotes = 0;
  
  @override
  void initState() {
    super.initState();
    _loadPollData();
  }
  
  Future<void> _loadPollData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Try to fetch from Firestore first
      final doc = await FirebaseFirestore.instance
          .collection('polls')
          .doc(widget.pollId)
          .get();
          
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          pollData = data;
          isLoading = false;
        });
      } else {
        // Use sample data if not found
        setState(() {
          // Sample data based on poll ID
          if (widget.pollId == 'poll1') {
            pollData = {
              'question': widget.question,
              'options': ['Yes', 'No', 'Need more information'],
              'votes': {'Yes': 42, 'No': 18, 'Need more information': 24},
              'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
              'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
            };
          } else {
            pollData = {
              'question': widget.question,
              'options': ['Strongly support', 'Support', 'Neutral', 'Against', 'Strongly against'],
              'votes': {'Strongly support': 30, 'Support': 45, 'Neutral': 10, 'Against': 8, 'Strongly against': 7},
              'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
              'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
            };
          }
          isLoading = false;
        });
      }
      
      // Calculate total votes
      if (pollData.containsKey('votes')) {
        final votes = pollData['votes'] as Map<String, dynamic>;
        final total = votes.values.fold<int>(0, (sum, value) => sum + (value as int));
        setState(() {
          totalVotes = total;
        });
      }
    } catch (e) {
      // Fallback to sample data on error
      setState(() {
        pollData = {
          'question': widget.question,
          'options': ['Yes', 'No'],
          'votes': {'Yes': 60, 'No': 40},
          'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        };
        totalVotes = 100;
        isLoading = false;
      });
    }
  }
  
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${_formatDate(timestamp)} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  String _getRemainingTime(Timestamp? timestamp) {
    if (timestamp == null) return 'No expiry set';
    
    final expiryDate = timestamp.toDate();
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} remaining';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} remaining';
    } else {
      return 'Less than a minute remaining';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = ThemeService.getRoleColor('citizen');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Poll Results"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Text(
                    widget.question, 
                    style: const TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Poll info
                  Row(
                    children: [
                      Icon(Icons.how_to_vote, size: 16, color: themeColor),
                      const SizedBox(width: 4),
                      Text(
                        '$totalVotes vote${totalVotes != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getRemainingTime(pollData['expiryDate']),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 32),
                  
                  // Results header
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: themeColor),
                      const SizedBox(width: 8),
                      Text(
                        'Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Results bars
                  ..._buildResultBars(),
                  
                  const SizedBox(height: 24),
                  
                  // Poll details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Poll Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Created:', 
                          _formatTimestamp(pollData['createdAt']),
                          Icons.calendar_today,
                        ),
                        _buildInfoRow(
                          'Expires:', 
                          _formatTimestamp(pollData['expiryDate']),
                          Icons.timer,
                        ),
                        _buildInfoRow(
                          'Status:',
                          _getPollStatus(pollData['expiryDate']),
                          _getPollStatus(pollData['expiryDate']) == 'Active' 
                            ? Icons.check_circle 
                            : Icons.cancel,
                          _getPollStatus(pollData['expiryDate']) == 'Active'
                            ? Colors.green
                            : Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon, [Color? iconColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            size: 16, 
            color: iconColor ?? Colors.grey.shade700,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80, 
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getPollStatus(Timestamp? expiryDate) {
    if (expiryDate == null) return 'Unknown';
    return DateTime.now().isBefore(expiryDate.toDate()) ? 'Active' : 'Expired';
  }
  
  List<Widget> _buildResultBars() {
    final options = pollData['options'] as List<dynamic>? ?? [];
    final votes = pollData['votes'] as Map<String, dynamic>? ?? {};
    
    // Sort options by vote count (descending)
    options.sort((a, b) => (votes[b] ?? 0).compareTo(votes[a] ?? 0));
    
    return options.map<Widget>((option) {
      final count = votes[option] ?? 0;
      final percentage = totalVotes > 0 ? (count / totalVotes * 100) : 0;
      final percentageText = percentage.toStringAsFixed(1);
      
      // Determine bar color based on position
      final index = options.indexOf(option);
      Color barColor;
      if (index == 0) {
        // Winner gets the theme color
        barColor = ThemeService.getRoleColor('citizen');
      } else if (index == 1 && options.length > 2) {
        // Second place gets a lighter version
        barColor = ThemeService.getRoleColor('citizen').withOpacity(0.7);
      } else {
        // Others get gray
        barColor = Colors.grey.shade400;
      }
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  '$count vote${count != 1 ? 's' : ''} · $percentageText%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                // Background track
                Container(
                  height: 24,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                // Filled progress
                FractionallySizedBox(
                  widthFactor: percentage / 100,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Percentage label (centered in the bar)
                if (percentage >= 10) // Only show percentage on bar if it's wide enough
                  Container(
                    height: 24,
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      '$percentageText%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
