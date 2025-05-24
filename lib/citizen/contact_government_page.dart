import 'package:flutter/material.dart';
import '../components/role_protected_page.dart';
import '../services/database_service.dart';

class ContactGovernmentPage extends StatefulWidget {
  const ContactGovernmentPage({super.key});

  @override
  State<ContactGovernmentPage> createState() => _ContactGovernmentPageState();
}

class _ContactGovernmentPageState extends State<ContactGovernmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isAnonymous = false;
  bool _isSending = false;
  String _messageType = 'General Inquiry';
  
  final List<String> _messageTypes = [
    'General Inquiry',
    'Service Request',
    'Feedback',
    'Complaint',
    'Suggestion',
    'Other',
  ];
  
  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSending = true);
    
    try {
      // Use DatabaseService to send message
      await DatabaseService.sendGovernmentMessage(
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        type: _messageType,
        isAnonymous: _isAnonymous,
      );
      
      if (!mounted) return;
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully!')),
      );
      
      // Clear form
      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _isAnonymous = false;
        _messageType = 'General Inquiry';
      });
      
      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: 'citizen',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contact Government'),
        ),
        body: _isSending
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Sending your message...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Information card
                      Card(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, 
                                    color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'About Contacting Government',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Use this form to send a message directly to government officials. '
                                'You can choose to remain anonymous, but this may limit their ability to respond directly. '
                                'For emergencies, please call emergency services instead.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Message type dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Message Type',
                          border: OutlineInputBorder(),
                        ),
                        value: _messageType,
                        items: _messageTypes.map((type) => 
                          DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _messageType = value);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a message type';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subject field
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'Brief description of your message',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Message field
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Enter your message here',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 8,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your message';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Anonymous checkbox
                      CheckboxListTile(
                        title: const Text('Send Anonymously'),
                        subtitle: const Text(
                          'Your personal information will not be shared with the government',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _isAnonymous,
                        onChanged: (value) {
                          setState(() => _isAnonymous = value ?? false);
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Send button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Send Message',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
} 