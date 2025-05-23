import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatePollPage extends StatefulWidget {
  const CreatePollPage({super.key});

  @override
  State<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final _formKey = GlobalKey<FormState>();
  final questionController = TextEditingController();
  final List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  /// Adds a new option text field
  void addOption() {
    setState(() {
      optionControllers.add(TextEditingController());
    });
  }

  /// Removes an option text field if there are more than two
  void removeOption(int index) {
    if (optionControllers.length > 2) {
      setState(() {
        optionControllers.removeAt(index);
      });
    }
  }

  /// Submits the poll data to Firestore
  Future<void> submitPoll() async {
    if (!_formKey.currentState!.validate()) return;

    final question = questionController.text.trim();
    final options = optionControllers
        .map((controller) => controller.text.trim())
        .where((option) => option.isNotEmpty)
        .toList();

    if (options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least two options.')),
      );
      return;
    }

    // Initialize votes map with zero votes for each option
    final votes = {for (var option in options) option: 0};

    try {
      await FirebaseFirestore.instance.collection('polls').add({
        'question': question,
        'options': options,
        'votes': votes,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poll created successfully!')),
      );
      Navigator.pop(context); // Return to previous screen after successful creation
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating poll: $e')),
      );
    }
  }

  @override
  void dispose() {
    questionController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Poll')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Poll question input
              TextFormField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Poll Question',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter a question'
                        : null,
              ),
              const SizedBox(height: 20),

              const Text(
                'Options (at least 2):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // List of option inputs
              ...optionControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Please enter option'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                        onPressed: () => removeOption(index),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // Button to add new option input
              TextButton.icon(
                onPressed: addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),

              const SizedBox(height: 20),

              // Submit poll button
              ElevatedButton(
                onPressed: submitPoll,
                child: const Text('Create Poll'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}