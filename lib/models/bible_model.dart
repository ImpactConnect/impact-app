import 'package:flutter/material.dart';

class Book {
  Book({
    required this.name,
    required this.chapters,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      name: json['name'] as String,
      chapters: (json['chapters'] as List)
          .asMap()
          .entries
          .map((entry) =>
              Chapter.fromJson(entry.value as List<dynamic>, entry.key + 1))
          .toList(),
    );
  }
  final String name;
  final List<Chapter> chapters;

  int get totalChapters => chapters.length;

  static Book fromVerses(List<BibleVerse> verses) {
    final bookName = verses.first.book;
    final chapterMap = <int, List<BibleVerse>>{};

    // Group verses by chapter
    for (var verse in verses) {
      final chapterNum = int.parse(verse.chapter);
      chapterMap.putIfAbsent(chapterNum, () => []);
      chapterMap[chapterNum]!.add(verse);
    }

    // Create chapters
    final chapters = chapterMap.entries
        .map((entry) => Chapter.fromVerses(entry.value))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    return Book(
      name: bookName,
      chapters: chapters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
    };
  }
}

class Chapter {
  Chapter({
    required this.number,
    required this.verses,
  });

  factory Chapter.fromJson(List<dynamic> json, int chapterNumber) {
    return Chapter(
      number: chapterNumber,
      verses: json
          .asMap()
          .entries
          .map((entry) => Verse.fromJson(entry.value as String, entry.key + 1))
          .toList(),
    );
  }
  final int number;
  final List<Verse> verses;

  static Chapter fromVerses(List<BibleVerse> verses) {
    final chapterNum = int.parse(verses.first.chapter);
    final versesList = verses
        .map((v) => Verse(
              number: int.parse(v.verse),
              text: v.text.trim(),
            ))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    return Chapter(
      number: chapterNum,
      verses: versesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'verses': verses.map((verse) => verse.toJson()).toList(),
    };
  }

  String getChapterText() {
    return verses.map((verse) => '${verse.number}. ${verse.text}').join('\n');
  }
}

class Verse {
  Verse({
    required this.number,
    required this.text,
    this.isBookmarked = false,
    this.bookmarkedDate,
    this.isHighlighted = false,
    this.highlightColor,
    this.note,
  });

  factory Verse.fromJson(String verseText, int verseNumber) {
    return Verse(
      number: verseNumber,
      text: verseText,
    );
  }
  final int number;
  final String text;
  bool isBookmarked;
  DateTime? bookmarkedDate;
  bool isHighlighted;
  Color? highlightColor;
  String? note;

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': text,
      if (isBookmarked) 'bookmarkedDate': bookmarkedDate?.toIso8601String(),
      if (isHighlighted && highlightColor != null)
        'highlightColor': highlightColor?.value,
      if (note != null) 'note': note,
    };
  }

  void toggleBookmark() {
    isBookmarked = !isBookmarked;
    bookmarkedDate = isBookmarked ? DateTime.now() : null;
  }

  void toggleHighlight([Color? color]) {
    isHighlighted = !isHighlighted;
    if (isHighlighted && color != null) {
      highlightColor = color;
    } else if (!isHighlighted) {
      highlightColor = null;
    }
  }

  void addNote(String newNote) {
    note = newNote.isEmpty ? null : newNote;
  }

  String getReference(String bookName, int chapterNumber) {
    return '$bookName $chapterNumber:$number';
  }

  String getFormattedText() {
    return '$number. $text';
  }
}

class BibleVerse {
  BibleVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      book: json['book'] as String,
      chapter: json['chapter'] as String,
      verse: json['verse'] as String,
      text: json['text'] as String,
    );
  }
  final String book;
  final String chapter;
  final String verse;
  final String text;
}
