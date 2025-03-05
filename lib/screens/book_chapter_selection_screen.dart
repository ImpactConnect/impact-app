import 'package:flutter/material.dart';
import '../models/bible_model.dart';
import '../services/bible_service.dart';
import 'bible_screen.dart';

class BookChapterSelectionScreen extends StatefulWidget {
  const BookChapterSelectionScreen({
    Key? key,
    required this.bibleService,
    required this.books,
  }) : super(key: key);
  final BibleService? bibleService;
  final List<Book> books;

  @override
  State<BookChapterSelectionScreen> createState() =>
      _BookChapterSelectionScreenState();
}

class _BookChapterSelectionScreenState
    extends State<BookChapterSelectionScreen> {
  Book? selectedBook;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Book & Chapter'),
      ),
      body: Row(
        children: [
          // Books List (Left Column)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: ListView.builder(
                itemCount: widget.books.length,
                itemBuilder: (context, index) {
                  final book = widget.books[index];
                  final isSelected = book == selectedBook;
                  return ListTile(
                    dense: true,
                    title: Text(
                      book.name,
                      style: TextStyle(
                        color:
                            isSelected ? Theme.of(context).primaryColor : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
                    onTap: () {
                      setState(() {
                        selectedBook = book;
                      });
                    },
                  );
                },
              ),
            ),
          ),
          // Chapters Grid (Right Column)
          Expanded(
            flex: 4,
            child: selectedBook == null
                ? const Center(
                    child: Text('Select a book to view chapters'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: selectedBook!.chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = selectedBook!.chapters[index];
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BibleScreen(
                                bibleService: widget.bibleService,
                                initialBook: selectedBook,
                                initialChapter: chapter,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue[800],
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                chapter.number.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
