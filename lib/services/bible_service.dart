import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bible_model.dart';

class BibleService {
  BibleService(this._prefs);
  static const String BOOKMARKS_KEY = 'bible_bookmarks';
  static const String HIGHLIGHTS_KEY = 'bible_highlights';
  static const String NOTES_KEY = 'bible_notes';
  static const String LAST_VERSE_DATE_KEY = 'last_verse_date';
  static const String VERSE_OF_DAY_KEY = 'verse_of_day';

  // Bible books in correct order
  static const List<String> BIBLE_BOOKS_ORDER = [
    // Old Testament
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
    'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
    '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles',
    'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms',
    'Proverbs', 'Ecclesiastes', 'Song of Solomon', 'Isaiah',
    'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea',
    'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum',
    'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
    // New Testament
    'Matthew', 'Mark', 'Luke', 'John', 'Acts',
    'Romans', '1 Corinthians', '2 Corinthians', 'Galatians',
    'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians',
    '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus',
    'Philemon', 'Hebrews', 'James', '1 Peter', '2 Peter',
    '1 John', '2 John', '3 John', 'Jude', 'Revelation'
  ];

  List<Book> _bible = [];
  final List<Book> _searchResults = [];
  final SharedPreferences? _prefs;

  Future<void> loadBible() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/docs/kjv.json');
      final List<dynamic> versesJson = json.decode(jsonString) as List<dynamic>;

      // Convert JSON to BibleVerse objects
      final verses = versesJson
          .map((json) => BibleVerse.fromJson(json as Map<String, dynamic>))
          .toList();

      // Group verses by book
      final bookMap = <String, List<BibleVerse>>{};
      for (var verse in verses) {
        bookMap.putIfAbsent(verse.book, () => []);
        bookMap[verse.book]!.add(verse);
      }

      // Create Book objects and sort by biblical order
      _bible = bookMap.values
          .map((bookVerses) => Book.fromVerses(bookVerses))
          .toList()
        ..sort((a, b) {
          final aIndex = BIBLE_BOOKS_ORDER.indexOf(a.name);
          final bIndex = BIBLE_BOOKS_ORDER.indexOf(b.name);
          return aIndex.compareTo(bIndex);
        });

      // Load saved preferences only if not on web
      if (!kIsWeb) {
        await _loadSavedPreferences();
      }
    } catch (e) {
      print('Error loading Bible: $e');
      rethrow;
    }
  }

  Future<void> _loadSavedPreferences() async {
    try {
      if (_prefs == null) return;

      final bookmarksJson = _prefs!.getString(BOOKMARKS_KEY);
      final highlightsJson = _prefs!.getString(HIGHLIGHTS_KEY);
      final notesJson = _prefs!.getString(NOTES_KEY);

      if (bookmarksJson != null) {
        final bookmarks = json.decode(bookmarksJson) as Map<String, dynamic>;
        _applyBookmarks(bookmarks);
      }

      if (highlightsJson != null) {
        final highlights = json.decode(highlightsJson) as Map<String, dynamic>;
        _applyHighlights(highlights);
      }

      if (notesJson != null) {
        final notes = json.decode(notesJson) as Map<String, dynamic>;
        _applyNotes(notes);
      }
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  void _applyBookmarks(Map<String, dynamic> bookmarks) {
    for (var entry in bookmarks.entries) {
      final reference = entry.key.split(' ');
      if (reference.length >= 3) {
        final bookName = reference[0];
        final chapterNumber = int.tryParse(reference[1]);
        final verseNumber = int.tryParse(reference[2]);

        if (chapterNumber != null && verseNumber != null) {
          final verse = getVerse(bookName, chapterNumber, verseNumber);
          if (verse != null) {
            verse.isBookmarked = true;
            verse.bookmarkedDate = DateTime.tryParse(entry.value);
          }
        }
      }
    }
  }

  void _applyHighlights(Map<String, dynamic> highlights) {
    for (var entry in highlights.entries) {
      final reference = entry.key.split(' ');
      if (reference.length >= 3) {
        final bookName = reference[0];
        final chapterNumber = int.tryParse(reference[1]);
        final verseNumber = int.tryParse(reference[2]);

        if (chapterNumber != null && verseNumber != null) {
          final verse = getVerse(bookName, chapterNumber, verseNumber);
          if (verse != null && entry.value != null) {
            verse.isHighlighted = true;
            verse.highlightColor = Color(entry.value as int);
          }
        }
      }
    }
  }

  void _applyNotes(Map<String, dynamic> notes) {
    for (var entry in notes.entries) {
      final reference = entry.key.split(' ');
      if (reference.length >= 3) {
        final bookName = reference[0];
        final chapterNumber = int.tryParse(reference[1]);
        final verseNumber = int.tryParse(reference[2]);

        if (chapterNumber != null && verseNumber != null) {
          final verse = getVerse(bookName, chapterNumber, verseNumber);
          if (verse != null) {
            verse.note = entry.value;
          }
        }
      }
    }
  }

  Future<void> savePreferences() async {
    if (kIsWeb || _prefs == null) return;

    try {
      final bookmarks = <String, String>{};
      final highlights = <String, int>{};
      final notes = <String, String>{};

      for (var book in _bible) {
        for (var chapter in book.chapters) {
          for (var verse in chapter.verses) {
            final reference = verse.getReference(book.name, chapter.number);

            if (verse.isBookmarked && verse.bookmarkedDate != null) {
              bookmarks[reference] = verse.bookmarkedDate!.toIso8601String();
            }

            if (verse.isHighlighted && verse.highlightColor != null) {
              highlights[reference] = verse.highlightColor!.value;
            }

            if (verse.note != null) {
              notes[reference] = verse.note!;
            }
          }
        }
      }

      await _prefs!.setString(BOOKMARKS_KEY, json.encode(bookmarks));
      await _prefs!.setString(HIGHLIGHTS_KEY, json.encode(highlights));
      await _prefs!.setString(NOTES_KEY, json.encode(notes));
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }

  List<Book> get bible => _bible;
  SharedPreferences? get prefs => _prefs;

  List<Book> getAllBooks() => _bible;

  Book? getBookByName(String bookName) {
    try {
      return _bible.firstWhere(
          (book) => book.name.toLowerCase() == bookName.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  Chapter? getChapter(String bookName, int chapterNumber) {
    final book = getBookByName(bookName);
    if (book == null) return null;

    try {
      return book.chapters
          .firstWhere((chapter) => chapter.number == chapterNumber);
    } catch (e) {
      return null;
    }
  }

  Verse? getVerse(String bookName, int chapterNumber, int verseNumber) {
    final chapter = getChapter(bookName, chapterNumber);
    if (chapter == null) return null;

    try {
      return chapter.verses.firstWhere((verse) => verse.number == verseNumber);
    } catch (e) {
      return null;
    }
  }

  List<Book> searchBible(String query) {
    if (query.isEmpty) return [];

    final searchResults = <Book>[];
    final queryLower = query.toLowerCase();

    for (var book in _bible) {
      final matchingVerses = <Verse>[];

      for (var chapter in book.chapters) {
        for (var verse in chapter.verses) {
          if (verse.text.toLowerCase().contains(queryLower)) {
            matchingVerses.add(verse);
          }
        }
      }

      if (matchingVerses.isNotEmpty) {
        // Create a new book with only matching verses
        final matchingBook = Book(
          name: book.name,
          chapters: [Chapter(number: 1, verses: matchingVerses)],
        );
        searchResults.add(matchingBook);
      }
    }

    return searchResults;
  }

  Book? getNextChapter(Book currentBook, int currentChapterNumber) {
    final currentBookIndex =
        _bible.indexWhere((book) => book.name == currentBook.name);
    if (currentBookIndex == -1) return null;

    // Check if there's a next chapter in current book
    if (currentChapterNumber < currentBook.totalChapters) {
      return Book(
        name: currentBook.name,
        chapters: [currentBook.chapters[currentChapterNumber]],
      );
    }

    // If we're at the last chapter, move to next book
    if (currentBookIndex < _bible.length - 1) {
      final nextBook = _bible[currentBookIndex + 1];
      return Book(
        name: nextBook.name,
        chapters: [nextBook.chapters.first],
      );
    }

    return null;
  }

  Book? getPreviousChapter(Book currentBook, int currentChapterNumber) {
    final currentBookIndex =
        _bible.indexWhere((book) => book.name == currentBook.name);
    if (currentBookIndex == -1) return null;

    // Check if there's a previous chapter in current book
    if (currentChapterNumber > 1) {
      return Book(
        name: currentBook.name,
        chapters: [currentBook.chapters[currentChapterNumber - 2]],
      );
    }

    // If we're at the first chapter, move to previous book
    if (currentBookIndex > 0) {
      final prevBook = _bible[currentBookIndex - 1];
      return Book(
        name: prevBook.name,
        chapters: [prevBook.chapters.last],
      );
    }

    return null;
  }

  List<Verse> getBookmarkedVerses() {
    final bookmarkedVerses = <Verse>[];
    for (var book in _bible) {
      for (var chapter in book.chapters) {
        bookmarkedVerses
            .addAll(chapter.verses.where((verse) => verse.isBookmarked));
      }
    }
    return bookmarkedVerses;
  }

  List<Verse> getHighlightedVerses() {
    final highlightedVerses = <Verse>[];
    for (var book in _bible) {
      for (var chapter in book.chapters) {
        highlightedVerses
            .addAll(chapter.verses.where((verse) => verse.isHighlighted));
      }
    }
    return highlightedVerses;
  }

  List<Verse> getVersesWithNotes() {
    final versesWithNotes = <Verse>[];
    for (var book in _bible) {
      for (var chapter in book.chapters) {
        versesWithNotes
            .addAll(chapter.verses.where((verse) => verse.note != null));
      }
    }
    return versesWithNotes;
  }

  Future<Map<String, dynamic>> getVerseOfDay() async {
    if (!kIsWeb && _prefs != null) {
      final lastDate = _prefs!.getString(LAST_VERSE_DATE_KEY);
      final savedVerse = _prefs!.getString(VERSE_OF_DAY_KEY);
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Return saved verse if it's from today
      if (lastDate == today && savedVerse != null) {
        return json.decode(savedVerse);
      }

      // Generate new verse for today
      final verse = _getRandomVerse();
      if (verse != null) {
        final verseData = {
          'book': verse['book'],
          'chapter': verse['chapter'],
          'verse': verse['verse'],
          'text': verse['text'],
        };

        // Save new verse
        await _prefs!.setString(LAST_VERSE_DATE_KEY, today);
        await _prefs!.setString(VERSE_OF_DAY_KEY, json.encode(verseData));
        return verseData;
      }
    }

    // Fallback to random verse without saving
    return _getRandomVerse() ??
        {
          'book': 'John',
          'chapter': 3,
          'verse': 16,
          'text':
              'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.',
        };
  }

  Map<String, dynamic>? _getRandomVerse() {
    if (_bible.isEmpty) return null;

    final random = Random();
    final book = _bible[random.nextInt(_bible.length)];
    final chapter = book.chapters[random.nextInt(book.chapters.length)];
    final verse = chapter.verses[random.nextInt(chapter.verses.length)];

    return {
      'book': book.name,
      'chapter': chapter.number,
      'verse': verse.number,
      'text': verse.text,
    };
  }

  Future<void> clearVerseOfDay() async {
    if (!kIsWeb && _prefs != null) {
      await _prefs!.remove(LAST_VERSE_DATE_KEY);
    }
  }

  Verse? findVerse(String bookName, int chapterNumber, int verseNumber) {
    for (var book in _bible) {
      if (book.name == bookName) {
        for (var chapter in book.chapters) {
          if (chapter.number == chapterNumber) {
            for (var verse in chapter.verses) {
              if (verse.number == verseNumber) {
                return verse;
              }
            }
          }
        }
      }
    }
    return null;
  }
}
