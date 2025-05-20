import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'poll_results_page.dart';
import '../services/user_service.dart';
import '../components/role_protected_page.dart';

class PollsPage extends StatefulWidget {
  const PollsPage({super.key});

  @override
  State<PollsPage> createState() => _PollsPageState();
}

class _PollsPageState extends State<PollsPage> {
  late String userRole;
  String? userId;
  bool isLoading = true;
  List<Map<String, dynamic>> activePolls = [];
  Map<String, String?> userVotes = {};
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  
  Future<void> _loadUserInfo() async {
    try {
      final user = await UserService.getCurrentUserData();
      if (mounted) {
        setState(() {
          userRole = user?['role'] ?? 'unknown';
          userId = user?['uid'] ?? FirebaseAuth.instance.currentUser?.uid;
          isLoading = false;
        });
        _loadPolls();
        _loadUserVotes();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          userRole = 'unknown';
        });
      }
    }
  }
  
  Future<void> _loadPolls() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Query for polls that are either not expired or have expiry date in the future
      final now = DateTime.now();
      final QuerySnapshot pollsSnapshot = await FirebaseFirestore.instance
          .collection('polls')
          .where('isActive', isEqualTo: true)
          .where('expiryDate', isGreaterThanOrEqualTo: now)
          .orderBy('expiryDate', descending: false)
          .get();
      
      if (mounted) {
        setState(() {
          activePolls = pollsSnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'question': data['question'] ?? 'Untitled Poll',
              'options': List<String>.from(data['options'] ?? []),
              'expiryDate': (data['expiryDate'] as Timestamp?)?.toDate(),
              'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
              'votes': Map<String, int>.from(data['votes'] ?? {}),
            };
          }).toList();
          
          if (activePolls.isEmpty) {
            // If no active polls are found, add some sample data for demonstration
            activePolls = [
              {
                'id': 'poll1',
                'question': 'Should we build a new park in the downtown area?',
                'options': ['Yes', 'No', 'Need more information'],
                'expiryDate': DateTime.now().add(const Duration(days: 7)),
                'createdAt': DateTime.now().subtract(const Duration(days: 1)),
                'votes': {'Yes': 42, 'No': 18, 'Need more information': 24},
              },
              {
                'id': 'poll2',
                'question': 'Do you support increasing public transport funding?',
                'options': ['Strongly support', 'Support', 'Neutral', 'Against', 'Strongly against'],
                'expiryDate': DateTime.now().add(const Duration(days: 14)),
                'createdAt': DateTime.now().subtract(const Duration(days: 3)),
                'votes': {'Strongly support': 30, 'Support': 45, 'Neutral': 10, 'Against': 8, 'Strongly against': 7},
              },
            ];
          }
          
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          // Use sample data on error
          activePolls = [
            {
              'id': 'poll1',
              'question': 'Should we build a new park?',
              'options': ['Yes', 'No'],
              'expiryDate': DateTime.now().add(const Duration(days: 7)),
              'createdAt': DateTime.now(),
              'votes': {'Yes': 60, 'No': 40},
            },
            {
              'id': 'poll2',
              'question': 'Do you support increasing public transport funding?',
              'options': ['Yes', 'No', 'Undecided'],
              'expiryDate': DateTime.now().add(const Duration(days: 5)),
              'createdAt': DateTime.now(),
              'votes': {'Yes': 70, 'No': 20, 'Undecided': 10},
            },
          ];
        });
      }
    }
  }
  
  Future<void> _loadUserVotes() async {
    if (userId == null) return;
    
    try {
      final userVotesDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('votes')
          .doc('polls')
          .get();
      
      if (userVotesDoc.exists && mounted) {
        setState(() {
          userVotes = Map<String, String?>.from(userVotesDoc.data() ?? {});
        });
      } else {
        // Use sample votes for demonstration
        setState(() {
          userVotes = {
            'poll1': 'Yes',  // Sample vote for poll1
          };
        });
      }
    } catch (e) {
      // On error, use sample data
      if (mounted) {
        setState(() {
          userVotes = {
            'poll1': 'Yes',  // Sample vote for poll1
          };
        });
      }
    }
  }
  
  Future<void> _castVote(String pollId, String option) async {
    // Check if the user has already voted
    if (userVotes.containsKey(pollId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already voted on this poll')),
      );
      return;
    }
    
    // First show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Vote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your vote is permanent and cannot be changed.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Are you sure you want to vote for "$option"?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Vote'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    // If user confirms, cast the vote
    try {
      // Find the poll in our local data
      final pollIndex = activePolls.indexWhere((poll) => poll['id'] == pollId);
      if (pollIndex == -1) return;
      
      // Update local state first for responsive UI
      setState(() {
        userVotes[pollId] = option;
        final poll = activePolls[pollIndex];
        final votes = poll['votes'] as Map<String, int>;
        votes[option] = (votes[option] ?? 0) + 1;
      });
      
      // Save vote to the user's vote collection
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('votes')
            .doc('polls')
            .set({pollId: option}, SetOptions(merge: true));
        
        // Update the poll vote count in Firestore
        await FirebaseFirestore.instance
            .collection('polls')
            .doc(pollId)
            .update({
              'votes.$option': FieldValue.increment(1),
            });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vote cast successfully for "$option"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error casting vote: $e')),
        );
      }
    }
  }
  
  String _formatExpiryDate(DateTime? date) {
    if (date == null) return 'No expiry date';
    
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays > 0) {
      return 'Expires in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Expires in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Expires in ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Expiring soon';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final Color themeColor = Theme.of(context).primaryColor;
    final bool isCitizen = userRole == 'citizen';
    
    return RoleProtectedPage(
      requiredRole: "all_roles",
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community Polls'),
        ),
        body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : activePolls.isEmpty 
            ? const Center(child: Text('No active polls at the moment'))
            : ListView.builder(
                itemCount: activePolls.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final poll = activePolls[index];
                  final pollId = poll['id'];
                  final String? userVote = userVotes[pollId];
                  final hasVoted = userVote != null;
                  final options = poll['options'] as List<String>;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                poll['question'],
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatExpiryDate(poll['expiryDate']),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              if (hasVoted) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12, 
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green.shade300),
                                  ),
                                  child: Text(
                                    'You voted: $userVote',
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              
                              if (isCitizen && !hasVoted) 
                                const Text(
                                  'Tap an option to vote:',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                            ],
                          ),
                        ),
                        
                        if (isCitizen && !hasVoted)
                          // Show voting buttons for citizen who hasn't voted
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              children: options.map((option) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _castVote(pollId, option),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(option),
                                    ),
                                  ),
                                ),
                              ).toList(),
                            ),
                          )
                        else
                          // Show results preview for those who voted or non-citizens
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: options.map((option) {
                                final votes = (poll['votes'] as Map<String, int>)[option] ?? 0;
                                final totalVotes = (poll['votes'] as Map<String, int>)
                                    .values
                                    .fold(0, (sum, count) => sum + count);
                                
                                final percentage = totalVotes > 0 
                                    ? (votes / totalVotes * 100).toStringAsFixed(1) 
                                    : '0';
                                
                                final isUserVote = option == userVote;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (isUserVote) ...[
                                            Icon(
                                              Icons.check_circle, 
                                              color: Colors.green,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Expanded(
                                            child: Text(
                                              option,
                                              style: TextStyle(
                                                fontWeight: isUserVote ? FontWeight.bold : FontWeight.normal,
                                                color: isUserVote ? Colors.green.shade800 : null,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('$percentage%'),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: totalVotes > 0 ? votes / totalVotes : 0,
                                          minHeight: 10,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isUserVote ? Colors.green : themeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        
                        // View detailed results button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PollResultsPage(
                                        pollId: poll['id'], 
                                        question: poll['question'],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.bar_chart),
                                label: const Text('View Full Results'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
