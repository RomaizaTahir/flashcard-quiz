import 'package:flutter/material.dart';
import '../models/flashcard.dart';

class AddEditScreen extends StatefulWidget {
  final Flashcard? flashcard;

  const AddEditScreen({
    super.key,
    this.flashcard,
  });

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController questionController;
  late TextEditingController answerController;

  bool get isEditing => widget.flashcard != null;

  @override
  void initState() {
    super.initState();

    questionController = TextEditingController(
      text: widget.flashcard?.question ?? '',
    );

    answerController = TextEditingController(
      text: widget.flashcard?.answer ?? '',
    );
  }

  @override
  void dispose() {
    questionController.dispose();
    answerController.dispose();
    super.dispose();
  }

  void saveFlashcard() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final flashcard = Flashcard(
      question: questionController.text.trim(),
      answer: answerController.text.trim(),
    );

    Navigator.pop(context, flashcard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? "Edit Flashcard" : "Add Flashcard",
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Question",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E24AA),
                ),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: questionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Enter your question",
                  prefixIcon: const Icon(Icons.help_outline),
                  filled: true,
                  fillColor: const Color(0xFFF5E9FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter a question";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),

              const Text(
                "Answer",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E24AA),
                ),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: answerController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Enter the answer",
                  prefixIcon: const Icon(Icons.lightbulb_outline),
                  filled: true,
                  fillColor: const Color(0xFFFFEAF2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter an answer";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saveFlashcard,
                  icon: const Icon(Icons.save),
                  label: Text(
                    isEditing
                        ? "Update Flashcard"
                        : "Save Flashcard",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}