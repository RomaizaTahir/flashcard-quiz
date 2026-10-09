import 'package:shared_preferences/shared_preferences.dart';

class Flashcard {
  final String question;
  final String answer;

  Flashcard({required this.question, required this.answer});

  // Card ko Map/JSON mein badalne ke liye
  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
  };

  // JSON se wapas Card banane ke liye
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      question: json['question'],
      answer: json['answer'],
    );
  }
}
