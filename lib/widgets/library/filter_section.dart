import 'package:flutter/material.dart';
import '../../services/book_service.dart';

class FilterSection extends StatelessWidget {
  const FilterSection({
    Key? key,
    required this.onCategorySelected,
    required this.onAuthorSelected,
    required this.onTopicsSelected,
    required this.onClearFilters,
    required this.hasActiveFilters,
    this.selectedCategory,
    this.selectedAuthor,
    this.selectedTopics,
  }) : super(key: key);
  final Function(String?) onCategorySelected;
  final Function(String?) onAuthorSelected;
  final Function(List<String>?) onTopicsSelected;
  final VoidCallback onClearFilters;
  final bool hasActiveFilters;
  final String? selectedCategory;
  final String? selectedAuthor;
  final List<String>? selectedTopics;

  void _showCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Theology',
            'Christian Living',
            'Bible Study',
            'Ministry',
            'Biography',
          ].map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                onCategorySelected(category);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showAuthorDialog(BuildContext context) async {
    final BookService bookService = BookService();
    final authors = await bookService.getAuthors();

    if (context.mounted) {
      final selectedAuthor = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Author'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: authors.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(authors[index]),
                    onTap: () {
                      Navigator.of(context).pop(authors[index]);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      onAuthorSelected(selectedAuthor);
    }
  }

  Future<void> _showTopicsDialog(BuildContext context) async {
    final BookService bookService = BookService();
    final topics = await bookService.getTopics();
    final selectedTopics = <String>{};

    if (context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Select Topics'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return CheckboxListTile(
                        title: Text(topic),
                        value: selectedTopics.contains(topic),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedTopics.add(topic);
                            } else {
                              selectedTopics.remove(topic);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed == true) {
        onTopicsSelected(selectedTopics.toList());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 32, // Fixed height for filter buttons
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterButton(
                  context,
                  'Category',
                  selectedCategory,
                  () => _showCategoryDialog(context),
                ),
                const SizedBox(width: 8),
                _buildFilterButton(
                  context,
                  'Author',
                  selectedAuthor,
                  () => _showAuthorDialog(context),
                ),
                const SizedBox(width: 8),
                _buildFilterButton(
                  context,
                  'Topics',
                  selectedTopics?.isNotEmpty == true
                      ? '${selectedTopics!.length} selected'
                      : null,
                  () => _showTopicsDialog(context),
                ),
                if (hasActiveFilters) ...[
                  const SizedBox(width: 12),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasActiveFilters)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (selectedCategory != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildSelectedChip(
                          selectedCategory!, () => onCategorySelected(null)),
                    ),
                  if (selectedAuthor != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildSelectedChip(
                          selectedAuthor!, () => onAuthorSelected(null)),
                    ),
                  if (selectedTopics != null)
                    ...selectedTopics!.map((topic) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildSelectedChip(
                            topic,
                            () {
                              final newTopics =
                                  List<String>.from(selectedTopics!)
                                    ..remove(topic);
                              onTopicsSelected(
                                  newTopics.isEmpty ? null : newTopics);
                            },
                          ),
                        )),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedChip(String label, VoidCallback onDelete) {
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: const TextStyle(fontSize: 11),
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    String label,
    String? selectedValue,
    VoidCallback onTap,
  ) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        side: BorderSide(
          color: selectedValue != null
              ? Theme.of(context).primaryColor
              : Theme.of(context).dividerColor,
        ),
        backgroundColor: selectedValue != null
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 2),
          Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: selectedValue != null
                ? Theme.of(context).primaryColor
                : Theme.of(context).iconTheme.color,
          ),
        ],
      ),
    );
  }
}
