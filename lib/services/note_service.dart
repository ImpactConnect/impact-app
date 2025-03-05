import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

class NoteService {
  NoteService(SharedPreferences? prefs) {
    _prefs = prefs;
  }
  static const String _notesKey = 'user_notes';
  SharedPreferences? _prefs;

  static Future<NoteService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return NoteService(prefs);
  }

  Future<List<Note>> getAllNotes() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      final notesJson = _prefs!.getStringList(_notesKey) ?? [];
      print('Loaded notes: $notesJson'); // Debug print

      final notes = notesJson
          .map((noteStr) => Note.fromJson(json.decode(noteStr)))
          .toList();

      notes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return notes;
    } catch (e) {
      print('Error loading notes: $e');
      return [];
    }
  }

  Future<bool> saveNote(Note note) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      final notes = await getAllNotes();
      final existingIndex = notes.indexWhere((n) => n.id == note.id);

      if (existingIndex != -1) {
        notes[existingIndex] = note;
      } else {
        notes.add(note);
      }

      final notesJson =
          notes.map((note) => json.encode(note.toJson())).toList();
      print('Saving notes: $notesJson'); // Debug print

      final result = await _prefs!.setStringList(_notesKey, notesJson);
      print('Save result: $result'); // Debug print
      return result;
    } catch (e) {
      print('Error saving note: $e');
      return false;
    }
  }

  Future<bool> deleteNote(String noteId) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      final notes = await getAllNotes();
      notes.removeWhere((note) => note.id == noteId);

      final notesJson =
          notes.map((note) => json.encode(note.toJson())).toList();
      return await _prefs!.setStringList(_notesKey, notesJson);
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }
}
