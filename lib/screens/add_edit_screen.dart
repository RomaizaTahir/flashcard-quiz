
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

  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late final TextEditingController _option1Controller;
  late final TextEditingController _option2Controller;
  late final TextEditingController _option3Controller;
  late final TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();

    final card = widget.flashcard;

    _questionController =
        TextEditingController(text: card?.question ?? '');
    _answerController =
        TextEditingController(text: card?.answer ?? '');
    _option1Controller = TextEditingController(
      text: card != null && card.options.isNotEmpty
          ? card.options[0]
          : '',
    );
    _option2Controller = TextEditingController(
      text: card != null && card.options.length > 1
          ? card.options[1]
          : '',
    );
    _option3Controller = TextEditingController(
      text: card != null && card.options.length > 2
          ? card.options[2]
          : '',
    );
    _categoryController =
        TextEditingController(text: card?.category ?? 'General');
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final oldCard = widget.flashcard;

    final card = Flashcard(
      id: oldCard?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      question: _questionController.text.trim(),
      answer: _answerController.text.trim(),
      options: [
        _answerController.text.trim(),
        _option1Controller.text.trim(),
        _option2Controller.text.trim(),
        _option3Controller.text.trim(),
      ],
      category: _categoryController.text.trim().isEmpty
          ? 'General'
          : _categoryController.text.trim(),
      isFavorite: oldCard?.isFavorite ?? false,
      reviewed: oldCard?.reviewed ?? false,
    );

    Navigator.pop(context, card);
  }

  Widget _field(
      String label,
      TextEditingController controller, {
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.flashcard == null ? 'Add Flashcard' : 'Edit Flashcard',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _field('Question', _questionController, maxLines: 2),
              _field('Correct Answer', _answerController),
              _field('Wrong Option 1', _option1Controller),
              _field('Wrong Option 2', _option2Controller),
              _field('Wrong Option 3', _option3Controller),
              _field('Category', _categoryController),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Flashcard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
