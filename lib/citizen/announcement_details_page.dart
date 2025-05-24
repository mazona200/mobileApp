import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../components/role_protected_page.dart';
import '../services/database_service.dart';

class AnnouncementDetailsPage extends StatefulWidget {
  final String announcementId;
  final Map<String, dynamic> announcement;

  const AnnouncementDetailsPage({
    super.key,
    required this.announcementId,
    required this.announcement,
  });

  @override
  State<AnnouncementDetailsPage> createState() => _AnnouncementDetailsPageState();
}

class _AnnouncementDetailsPageState extends State<AnnouncementDetailsPage> {
  final _commentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      // Use DatabaseService to add comment
      await DatabaseService.addAnnouncementComment(
        announcementId: widget.announcementId,
        text: _commentController.text.trim(),
        isAnonymous: _isAnonymous,
      );
      
      if (!mounted) return;
      
      // Clear text field
      _commentController.clear();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment posted!')),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post comment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  
  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date unknown';
    return DateFormat('MMMM d, yyyy - h:mm a').format(timestamp.toDate());
  }
  
  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'health':
        return Colors.green.shade700;
      case 'infrastructure':
        return Colors.blue.shade700;
      case 'education':
        return Colors.purple.shade700;
      case 'safety':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final title = widget.announcement['title'] ?? 'No Title';
    final content = widget.announcement['content'] ?? 'No Content';
    final category = widget.announcement['category'] ?? '';
    final timestamp = widget.announcement['createdAt'];
    final imageUrl = widget.announcement['imageUrl'];
    
    return RoleProtectedPage.forAllRoles(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Announcement Details'),
        ),
        body: Column(
          children: [
            // Announcement details
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image (if available)
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                        (loadingProgress.expectedTotalBytes ?? 1)
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category and date
                          Row(
                            children: [
                              if (category.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: getCategoryColor(category),
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  formatDate(timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Title
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Content
                          Text(
                            content,
                            style: const TextStyle(fontSize: 16),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Comments section title
                          Row(
                            children: [
                              const Icon(Icons.comment),
                              const SizedBox(width: 8),
                              const Text(
                                'Comments',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('announcements')
                                    .doc(widget.announcementId)
                                    .collection('comments')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                  return Text(
                                    '$count ${count == 1 ? 'comment' : 'comments'}',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  );
                                },
                              ),
                            ],
                          ),
                          
                          const Divider(height: 32),
                          
                          // Comments list
                          buildCommentsSection(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Comment input section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Anonymous checkbox
                  CheckboxListTile(
                    title: const Text('Comment anonymously'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() => _isAnonymous = value ?? false);
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Comment input field with send button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          maxLines: 2,
                          minLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isSubmitting)
                        const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(),
                        )
                      else
                        IconButton(
                          onPressed: submitComment,
                          icon: const Icon(Icons.send),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCommentsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService.getAnnouncementCommentsStream(widget.announcementId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No comments yet. Be the first to comment!'),
            ),
          );
        }
        
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final comment = snapshot.data!.docs[index];
            final commentText = comment['text'] ?? '';
            final userName = comment['userName'] ?? 'Unknown';
            final isAnonymous = comment['isAnonymous'] ?? false;
            final commentTimestamp = comment['createdAt'];
            
            return buildCommentCard(commentText, userName, isAnonymous, commentTimestamp);
          },
        );
      },
    );
  }
  
  Widget buildCommentCard(String text, String userName, bool isAnonymous, Timestamp? timestamp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAnonymous ? Icons.person_off : Icons.person,
                  size: 16,
                  color: isAnonymous ? Colors.grey : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  userName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAnonymous ? Colors.grey.shade700 : Colors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  formatDate(timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(text),
          ],
        ),
      ),
    );
  }
} 