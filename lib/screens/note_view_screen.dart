// ignore: avoid_web_libraries_in_flutter
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../models/note_model.dart';
import '../services/note_service.dart';
import 'note_editor_screen.dart';

class NoteViewScreen extends StatefulWidget {
  const NoteViewScreen({
    Key? key,
    required this.note,
    required this.noteService,
  }) : super(key: key);
  final Note note;
  final NoteService noteService;

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  Future<void> _shareAsText() async {
    if (kIsWeb) {
      // For web, create a temporary textarea to copy text
      final textarea = html.TextAreaElement()
        ..value = '${widget.note.title}\n\n${widget.note.content}'
        ..style.position = 'fixed'
        ..style.left = '-999px'
        ..style.top = '-999px';
      html.document.body?.append(textarea);
      textarea.select();
      html.document.execCommand('copy');
      textarea.remove();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text copied to clipboard')),
        );
      }
    } else {
      await Share.share(
        '${widget.note.title}\n\n${widget.note.content}',
        subject: widget.note.title,
      );
    }
  }

  Future<void> _shareAsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                widget.note.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                widget.note.content,
                style: const pw.TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );

    if (kIsWeb) {
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download = '${widget.note.title}.pdf';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } else {
      final output = await getTemporaryDirectory();
      final file = io.File('${output.path}/${widget.note.title}.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: widget.note.title,
      );
    }
  }

  Future<void> _shareAsDoc() async {
    final content = '${widget.note.title}\n\n${widget.note.content}';

    if (kIsWeb) {
      final bytes = content.codeUnits;
      final blob = html.Blob([bytes], 'application/msword');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download = '${widget.note.title}.doc';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } else {
      final output = await getTemporaryDirectory();
      final file = io.File('${output.path}/${widget.note.title}.doc');
      await file.writeAsString(content);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: widget.note.title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteEditorScreen(
                    noteService: widget.noteService,
                    note: widget.note,
                  ),
                ),
              );
              if (updated == true && mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'text':
                  await _shareAsText();
                  break;
                case 'pdf':
                  await _shareAsPdf();
                  break;
                case 'doc':
                  await _shareAsDoc();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'text',
                child: Row(
                  children: [
                    Icon(Icons.text_snippet_outlined),
                    SizedBox(width: 8),
                    Text(kIsWeb ? 'Copy as Text' : 'Share as Text'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'doc',
                child: Row(
                  children: [
                    Icon(Icons.description_outlined),
                    SizedBox(width: 8),
                    Text('Export as DOC'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.note.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last modified: ${_formatDate(widget.note.lastModified)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.note.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
