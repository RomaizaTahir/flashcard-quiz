import 'dart:convert';
import 'dart:math';

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
  static const String _cardsKey = 'flashcard_quiz_cards_v2';
  static const String _historyKey = 'flashcard_quiz_history_v2';
  static const String _lastKey = 'flashcard_quiz_last_v2';
  static const String _bestKey = 'flashcard_quiz_best_v2';

  List<Flashcard> _cards = [];
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  bool _darkMode = false;
  bool _favoritesOnly = false;
  String _category = 'All';
  String _search = '';
  int _tab = 0;
  int _lastScore = 0;
  int _bestScore = 0;

  final TextEditingController _searchController =
  TextEditingController();

  Color get _purple => const Color(0xFF7654C8);
  Color get _pink => const Color(0xFFFF8DB7);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCards = prefs.getString(_cardsKey);
    final savedHistory = prefs.getString(_historyKey);

    if (savedCards != null) {
      try {
        _cards = (jsonDecode(savedCards) as List)
            .map((item) => Flashcard.fromJson(
          Map<String, dynamic>.from(item),
        ))
            .toList();
      } catch (_) {
        _cards = [];
      }
    } else {
      _cards = [
        Flashcard(
          id: 'sample1',
          question: 'What is Flutter?',
          answer: 'A UI toolkit for building applications.',
          options: [
            'A UI toolkit for building applications.',
            'A database',
            'A programming language',
            'An operating system',
          ],
          category: 'Programming',
        ),
        Flashcard(
          id: 'sample2',
          question: 'What is Dart?',
          answer: 'A programming language developed by Google.',
          options: [
            'A programming language developed by Google.',
            'A web browser',
            'A database',
            'A design tool',
          ],
          category: 'Programming',
        ),
        Flashcard(
          id: 'sample3',
          question: 'Which keyword creates a constant in Dart?',
          answer: 'const',
          options: ['const', 'var', 'print', 'return'],
          category: 'Dart',
        ),
      ];
      await _saveCards();
    }

    if (savedHistory != null) {
      try {
        _history = (jsonDecode(savedHistory) as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } catch (_) {
        _history = [];
      }
    }

    _lastScore = prefs.getInt(_lastKey) ?? 0;
    _bestScore = prefs.getInt(_bestKey) ?? 0;
    _darkMode = prefs.getBool('flashcard_dark_mode') ?? false;

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cardsKey,
      jsonEncode(_cards.map((card) => card.toJson()).toList()),
    );
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(_history));
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('flashcard_dark_mode', _darkMode);
  }

  List<String> get _categories {
    final values = _cards.map((card) => card.category).toSet().toList()
      ..sort();
    return ['All', ...values];
  }

  List<Flashcard> get _visibleCards {
    return _cards.where((card) {
      final matchesSearch =
          card.question.toLowerCase().contains(_search.toLowerCase()) ||
              card.answer.toLowerCase().contains(_search.toLowerCase());

      final matchesCategory =
          _category == 'All' || card.category == _category;

      final matchesFavorite = !_favoritesOnly || card.isFavorite;

      return matchesSearch && matchesCategory && matchesFavorite;
    }).toList();
  }

  Future<void> _addCard() async {
    final result = await Navigator.push<Flashcard>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditScreen(),
      ),
    );

    if (result != null) {
      setState(() => _cards.add(result));
      await _saveCards();
    }
  }

  Future<void> _editCard(Flashcard card) async {
    final result = await Navigator.push<Flashcard>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(flashcard: card),
      ),
    );

    if (result != null) {
      final index = _cards.indexWhere((item) => item.id == card.id);
      if (index != -1) {
        setState(() => _cards[index] = result);
        await _saveCards();
      }
    }
  }

  Future<void> _deleteCard(Flashcard card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete flashcard?'),
        content: const Text(
          'This flashcard will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _cards.removeWhere((item) => item.id == card.id));
      await _saveCards();
    }
  }

  Future<void> _toggleFavorite(Flashcard card) async {
    setState(() => card.isFavorite = !card.isFavorite);
    await _saveCards();
  }

  Future<void> _toggleReviewed(Flashcard card) async {
    setState(() => card.reviewed = !card.reviewed);
    await _saveCards();
  }

  void _openStudy() {
    if (_cards.isEmpty) {
      _message('Add a flashcard before studying.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudyScreen(
          cards: List<Flashcard>.from(_cards),
          onReviewed: _toggleReviewed,
        ),
      ),
    );
  }

  Future<void> _startQuiz() async {
    if (_cards.isEmpty) {
      _message('Add flashcards before starting a quiz.');
      return;
    }

    final nameController = TextEditingController();
    if (!mounted) return;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Who is taking the quiz?'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Enter your name',
            hintText: 'e.g. Romaiza',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = nameController.text.trim();
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Start Quiz'),
          ),
        ],
      ),
    );

    nameController.dispose();

    if (name == null || name.trim().isEmpty || !mounted) return;

    final questions = _cards
        .where((card) => card.options.length >= 2)
        .toList()
      ..shuffle(Random());

    if (questions.isEmpty) {
      _message('Add answer options to your flashcards first.');
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          name: name.trim(),
          questions: questions,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final now = DateTime.now();
    final entry = <String, dynamic>{
      'name': name.trim(),
      'score': result['score'] as int,
      'total': result['total'] as int,
      'percentage': result['percentage'] as int,
      'date': now.toIso8601String(),
    };

    setState(() {
      _history.insert(0, entry);
      _lastScore = entry['percentage'] as int;
      if (_lastScore > _bestScore) {
        _bestScore = _lastScore;
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastKey, _lastScore);
    await prefs.setInt(_bestKey, _bestScore);
    await _saveHistory();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _purple, size: 27),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _dashboard() {
    final reviewed = _cards.where((card) => card.reviewed).length;
    final progress = _cards.isEmpty ? 0.0 : reviewed / _cards.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_purple, _pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keep Learning ✨',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'One card at a time. One step closer to your goals.',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.20,
          children: [
            _statCard('Total Cards', '${_cards.length}', Icons.style),
            _statCard('Reviewed', '$reviewed', Icons.check_circle),
            _statCard('Last Quiz', '$_lastScore%', Icons.history),
            _statCard('Best Quiz', '$_bestScore%', Icons.emoji_events),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reviewed Progress',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(10),
                  color: _purple,
                  backgroundColor: _pink.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 8),
                Text('${(progress * 100).round()}% completed'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _actionButton(
          'Study Flashcards',
          Icons.menu_book,
          _openStudy,
        ),
        const SizedBox(height: 10),
        _actionButton(
          'Start a Quiz',
          Icons.quiz,
          _startQuiz,
        ),
        const SizedBox(height: 22),
        const Text(
          'Recent Flashcards',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_cards.isEmpty)
          const Text('No flashcards yet. Add your first one!')
        else
          ..._cards.take(3).map(
                (card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FlashcardCard(
                card: card,
                isReviewed: card.reviewed,
                onFavorite: () => _toggleFavorite(card),
                onEdit: () => _editCard(card),
                onDelete: () => _deleteCard(card),
                onReviewed: () => _toggleReviewed(card),
              ),
            ),
          ),
      ],
    );
  }

  Widget _actionButton(
      String title,
      IconData icon,
      VoidCallback action,
      ) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: action,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(title),
        ),
      ),
    );
  }

  Widget _flashcardsPage() {
    final cards = _visibleCards;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search questions or answers',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
                icon: const Icon(Icons.clear),
              ),
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            children: _categories.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(category),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Favorites only'),
            value: _favoritesOnly,
            onChanged: (value) => setState(() => _favoritesOnly = value),
          ),
        ),
        Expanded(
          child: cards.isEmpty
              ? const Center(child: Text('No matching flashcards found.'))
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            separatorBuilder: (_ , _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final card = cards[index];
              return FlashcardCard(
                card: card,
                isReviewed: card.reviewed,
                onFavorite: () => _toggleFavorite(card),
                onEdit: () => _editCard(card),
                onDelete: () => _deleteCard(card),
                onReviewed: () => _toggleReviewed(card),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _historyPage() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final entry in _history) {
      final name = entry['name']?.toString() ?? 'Unknown';
      grouped.putIfAbsent(name, () => []).add(entry);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Quiz History',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Results are grouped by the name entered before each quiz.'),
        const SizedBox(height: 16),
        if (_history.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearHistory,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear All History'),
            ),
          ),
        if (_history.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: Text('No quiz results yet.')),
          ),
        ...grouped.entries.map((group) {
          return Card(
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _pink.withValues(alpha: 0.25),
                child: Icon(Icons.person, color: _purple),
              ),
              title: Text(
                group.key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${group.value.length} quiz attempt(s)'),
              children: group.value.map((entry) {
                final date = DateTime.tryParse(
                  entry['date']?.toString() ?? '',
                );
                final dateText = date == null
                    ? 'Date unavailable'
                    : '${date.day}/${date.month}/${date.year} '
                    '${date.hour.toString().padLeft(2, '0')}:'
                    '${date.minute.toString().padLeft(2, '0')}';

                return ListTile(
                  title: Text(
                    '${entry['percentage']}% — '
                        '${entry['score']}/${entry['total']} correct',
                  ),
                  subtitle: Text(dateText),
                  trailing: IconButton(
                    tooltip: 'Delete result',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteHistoryEntry(entry),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _deleteHistoryEntry(
      Map<String, dynamic> entry,
      ) async {
    setState(() => _history.remove(entry));
    await _saveHistory();
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('All saved quiz records will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _history.clear());
      await _saveHistory();
    }
  }

  Widget _settingsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        Card(
          child: SwitchListTile(
            secondary: Icon(Icons.dark_mode, color: _purple),
            title: const Text('Dark Mode'),
            subtitle: const Text('Change the app appearance'),
            value: _darkMode,
            onChanged: (value) async {
              setState(() => _darkMode = value);
              await _saveTheme();
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.category, color: _purple),
            title: const Text('Categories'),
            subtitle: Text(
              _categories.where((item) => item != 'All').join(', ').isEmpty
                  ? 'No categories yet'
                  : _categories.where((item) => item != 'All').join(', '),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.favorite, color: _pink),
            title: const Text('Favorite Flashcards'),
            subtitle: Text(
              '${_cards.where((card) => card.isFavorite).length} favorites',
            ),
            onTap: () {
              setState(() {
                _favoritesOnly = true;
                _tab = 1;
              });
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.restart_alt, color: _purple),
            title: const Text('Reset Quiz Statistics'),
            subtitle: const Text('Reset best and last quiz scores'),
            onTap: _resetStats,
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About Flashcard Quiz'),
            subtitle: Text(
              'A learning app for flashcards, quizzes and progress tracking.',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _resetStats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset statistics?'),
        content: const Text(
          'This resets the last and best scores. Quiz history will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _lastScore = 0;
        _bestScore = 0;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastKey, 0);
      await prefs.setInt(_bestKey, 0);
    }
  }

  Future<bool> _handleBack() async {
    if (_tab != 0) {
      setState(() => _tab = 0);
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      _dashboard(),
      _flashcardsPage(),
      _historyPage(),
      _settingsPage(),
    ];

    return Theme(
      data: _darkMode
          ? ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _purple,
          brightness: Brightness.dark,
        ),
      )
          : Theme.of(context),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _handleBack().then((shouldExit) {
              if (shouldExit && mounted) {
                // Allow the platform to handle leaving the home screen.
                Navigator.maybePop(context);
              }
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Flashcard Quiz',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'Study',
                onPressed: _openStudy,
                icon: const Icon(Icons.menu_book),
              ),
              IconButton(
                tooltip: 'Start Quiz',
                onPressed: _startQuiz,
                icon: const Icon(Icons.play_circle_outline),
              ),
            ],
          ),
          body: IndexedStack(
            index: _tab,
            children: pages,
          ),
          floatingActionButton: _tab == 1
              ? FloatingActionButton.extended(
            onPressed: _addCard,
            icon: const Icon(Icons.add),
            label: const Text('Add Card'),
          )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (index) {
              setState(() => _tab = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.style_outlined),
                selectedIcon: Icon(Icons.style),
                label: 'Cards',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudyScreen extends StatefulWidget {
  final List<Flashcard> cards;
  final Future<void> Function(Flashcard) onReviewed;

  const StudyScreen({
    super.key,
    required this.cards,
    required this.onReviewed,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  int _index = 0;
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('Study Flashcards')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Card ${_index + 1} of ${widget.cards.length}'),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _showAnswer = !_showAnswer),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7654C8),
                          Color(0xFFFF8DB7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Center(
                      child: Text(
                        _showAnswer ? card.answer : card.question,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _showAnswer
                  ? 'Tap the card to see the question'
                  : 'Tap the card to reveal the answer',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                await widget.onReviewed(card);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review status saved')),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Mark Reviewed'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _index == 0
                        ? null
                        : () => setState(() {
                      _index--;
                      _showAnswer = false;
                    }),
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _index == widget.cards.length - 1
                        ? null
                        : () => setState(() {
                      _index++;
                      _showAnswer = false;
                    }),
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final String name;
  final List<Flashcard> questions;

  const QuizScreen({
    super.key,
    required this.name,
    required this.questions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _finished = false;

  late final List<Flashcard> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List<Flashcard>.from(widget.questions);
  }

  List<String> _options(Flashcard card) {
    final values = card.options.toSet().toList();
    if (!values.contains(card.answer)) values.insert(0, card.answer);
    return values;
  }

  void _choose(int index, List<String> options) {
    if (_answered) return;

    setState(() {
      _selected = index;
      _answered = true;

      if (options[index] == _questions[_index].answer) {
        _score++;
      }
    });
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    } else {
      setState(() => _finished = true);
    }
  }

  void _finish() {
    final percentage =
    ((_score / _questions.length) * 100).round();

    Navigator.pop<Map<String, dynamic>>(context, {
      'score': _score,
      'total': _questions.length,
      'percentage': percentage,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      final percentage =
      ((_score / _questions.length) * 100).round();

      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Results'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 75,
                  color: Color(0xFF7654C8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Well done, ${widget.name}!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7654C8),
                  ),
                ),
                Text('Correct answers: $_score / ${_questions.length}'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _finish,
                    child: const Text('Save Result & Return Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final card = _questions[_index];
    final options = _options(card);

    return Scaffold(
      appBar: AppBar(title: Text('Quiz — ${widget.name}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / _questions.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 12),
            Text('Question ${_index + 1} of ${_questions.length}'),
            const SizedBox(height: 24),
            Text(
              card.question,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(options.length, (index) {
              final isCorrect = options[index] == card.answer;
              Color? background;

              if (_answered && isCorrect) {
                background = Colors.green.withValues(alpha: 0.16);
              } else if (_answered && index == _selected) {
                background = Colors.red.withValues(alpha: 0.12);
              }

              return Card(
                color: background,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(String.fromCharCode(65 + index)),
                  ),
                  title: Text(options[index]),
                  trailing: _answered && isCorrect
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => _choose(index, options),
                ),
              );
            }),
            if (_answered) ...[
              const SizedBox(height: 12),
              Text(
                options[_selected!] == card.answer
                    ? 'Correct answer!'
                    : 'Correct answer: ${card.answer}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: options[_selected!] == card.answer
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _next,
                child: Text(
                  _index == _questions.length - 1
                      ? 'See Results'
                      : 'Next Question',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}