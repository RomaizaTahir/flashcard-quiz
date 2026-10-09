import 'package:flutter/material.dart';
import '../models/flashcard.dart';

class FlashcardCard extends StatelessWidget {
  final Flashcard flashcard;
  final bool showAnswer;
  final VoidCallback onShowAnswer;

  const FlashcardCard({
    super.key,
    required this.flashcard,
    required this.showAnswer,
    required this.onShowAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 300,
      ),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE9D5FF),
            Color(0xFFFFD6E7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showAnswer
                ? Icons.lightbulb_rounded
                : Icons.help_outline_rounded,
            size: 55,
            color: const Color(0xFF9C27B0),
          ),

          const SizedBox(height: 25),

          Text(
            showAnswer ? "Answer" : "Question",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8E24AA),
            ),
          ),

          const SizedBox(height: 15),

          Text(
            showAnswer ? flashcard.answer : flashcard.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A235A),
            ),
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: onShowAnswer,
            icon: Icon(
              showAnswer
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            label: Text(
              showAnswer ? "Hide Answer" : "Show Answer",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}