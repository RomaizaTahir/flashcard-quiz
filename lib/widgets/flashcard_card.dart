
import 'package:flutter/material.dart';
import '../models/flashcard.dart';

class FlashcardCard extends StatelessWidget {
  final Flashcard card;
  final bool isReviewed;
  final VoidCallback onFavorite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReviewed;

  const FlashcardCard({
    super.key,
    required this.card,
    required this.isReviewed,
    required this.onFavorite,
    required this.onEdit,
    required this.onDelete,
    required this.onReviewed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Chip(
                    label: Text(card.category),
                  ),
                ),
                IconButton(
                  onPressed: onFavorite,
                  icon: Icon(
                    card.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: Colors.pink,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              card.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Answer: ${card.answer}'),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  isReviewed
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: isReviewed ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isReviewed ? 'Reviewed' : 'Not reviewed',
                  ),
                ),
                TextButton(
                  onPressed: onReviewed,
                  child: Text(
                    isReviewed ? 'Mark again' : 'Mark reviewed',
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
