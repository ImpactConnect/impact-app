import 'package:flutter/material.dart';

class LibrarySearchBar extends StatefulWidget {
  const LibrarySearchBar({
    Key? key,
    required this.onSearch,
  }) : super(key: key);
  final Function(String) onSearch;

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    setState(() {}); // Update to show/hide clear button
    widget.onSearch(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search books...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _handleSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        ),
        onChanged: _handleSearch,
        textInputAction: TextInputAction.search,
        onSubmitted: _handleSearch,
      ),
    );
  }
}
