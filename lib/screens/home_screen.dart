
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/flashcard.dart';
import '../widgets/flashcard_card.dart';
import 'add_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _storageKey = 'saved_flashcards';

  final List<Flashcard> flashcards = [];

  int currentIndex = 0;
  bool showAnswer = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFlashcards();
  }

  // Load saved flashcards from device
  Future<void> loadFlashcards() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_storageKey);

    if (savedData != null) {
      try {
        final List<dynamic> decodedData = jsonDecode(savedData);

        flashcards.addAll(
          decodedData.map(
                (item) => Flashcard(
              question: item['question'] as String,
              answer: item['answer'] as String,
            ),
          ),
        );
      } catch (_) {
        flashcards.clear();
      }
    }

    // Add default cards only on first launch or if no cards remain.
    if (savedData == null || flashcards.isEmpty) {
      flashcards.addAll([
        Flashcard(
          question: 'What is Dart?',
          answer: 'Dart is a programming language developed by Google.',
        ),
        Flashcard(
          question: 'What is Flutter?',
          answer:
          'Flutter is a UI toolkit used to build cross-platform applications.',
        ),
        Flashcard(
          question: 'What is a variable?',
          answer: 'A variable is used to store a value in a program.',
        ),
      ]);

      await saveFlashcards();
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // Save all flashcards permanently on the device
  Future<void> saveFlashcards() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedData = jsonEncode(
      flashcards
          .map(
            (card) => {
          'question': card.question,
          'answer': card.answer,
        },
      )
          .toList(),
    );

    await prefs.setString(_storageKey, encodedData);
  }

  void nextCard() {
    if (currentIndex < flashcards.length - 1) {
      setState(() {
        currentIndex++;
        showAnswer = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already on the last card.'),
        ),
      );
    }
  }

  void previousCard() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        showAnswer = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already on the first card.'),
        ),
      );
    }
  }

  // Add a new flashcard
  Future<void> addFlashcard() async {
    final result = await Navigator.push<Flashcard>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditScreen(),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      flashcards.add(result);
      currentIndex = flashcards.length - 1;
      showAnswer = false;
    });

    await saveFlashcards();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Flashcard saved successfully!'),
      ),
    );
  }

  // Edit the current flashcard
  Future<void> editFlashcard() async {
    if (flashcards.isEmpty) return;

    final oldCard = flashcards[currentIndex];

    final result = await Navigator.push<Flashcard>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditScreen(
          flashcard: oldCard,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      flashcards[currentIndex] = result;
      showAnswer = false;
    });

    await saveFlashcards();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Flashcard updated successfully!'),
      ),
    );
  }

  // Delete the current flashcard
  Future<void> deleteFlashcard() async {
    if (flashcards.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Flashcard?'),
          content: const Text(
            'Are you sure you want to delete this flashcard?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) return;

    setState(() {
      flashcards.removeAt(currentIndex);

      if (flashcards.isEmpty) {
        currentIndex = 0;
      } else if (currentIndex >= flashcards.length) {
        currentIndex = flashcards.length - 1;
      }

      showAnswer = false;
    });

    await saveFlashcards();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Flashcard deleted successfully!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flashcard Quiz',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading || flashcards.isEmpty
                ? null
                : editFlashcard,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: isLoading || flashcards.isEmpty
                ? null
                : deleteFlashcard,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFAB47BC),
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Flashcards',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                  Text(
                    flashcards.isEmpty
                        ? '0/0'
                        : '${currentIndex + 1}/${flashcards.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Expanded(
                child: Center(
                  child: flashcards.isEmpty
                      ? const Text(
                    'No flashcards available. Add one below!',
                    textAlign: TextAlign.center,
                  )
                      : FlashcardCard(
                    flashcard:
                    flashcards[currentIndex],
                    showAnswer: showAnswer,
                    onShowAnswer: () {
                      setState(() {
                        showAnswer = !showAnswer;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: currentIndex > 0
                          ? previousCard
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                        const Color(0xFF8E24AA),
                        side: const BorderSide(
                          color: Color(0xFFBA68C8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                      currentIndex < flashcards.length - 1
                          ? nextCard
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: addFlashcard,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Flashcard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFFAB47BC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
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