
class Flashcard {
  final String id;
  String question;
  String answer;
  List<String> options;
  String category;
  bool isFavorite;
  bool reviewed;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    List<String>? options,
    this.category = 'General',
    this.isFavorite = false,
    this.reviewed = false,
  }) : options = options ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'options': options,
      'category': category,
      'isFavorite': isFavorite,
      'reviewed': reviewed,
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      options: (json['options'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ??
          <String>[],
      category: json['category']?.toString() ?? 'General',
      isFavorite: json['isFavorite'] as bool? ?? false,
      reviewed: json['reviewed'] as bool? ?? false,
    );
  }

  Flashcard copyWith({
    String? question,
    String? answer,
    List<String>? options,
    String? category,
    bool? isFavorite,
    bool? reviewed,
  }) {
    return Flashcard(
      id: id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      options: options ?? List<String>.from(this.options),
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      reviewed: reviewed ?? this.reviewed,
    );
  }
}
