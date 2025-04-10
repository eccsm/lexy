import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:docx_template/docx_template.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicenotes/database/app_database.dart';
import 'package:voicenotes/shared/utils/date_formatter.dart';
import 'package:voicenotes/shared/widgets/app_bar.dart';
import 'package:voicenotes/features/notes/notes_controller.dart';

/// The available export styles for both PDF and DOCX.
enum ExportStyle {
  modern,
  classic,
  minimal,
  colorful,
  academic,
}

/// Extension to get display name and icon for enum values.
extension ExportStyleExtension on ExportStyle {
  String get displayName {
    switch (this) {
      case ExportStyle.modern:
        return 'Modern';
      case ExportStyle.classic:
        return 'Classic';
      case ExportStyle.minimal:
        return 'Minimal';
      case ExportStyle.colorful:
        return 'Colorful';
      case ExportStyle.academic:
        return 'Academic';
    }
  }

  IconData get icon {
    switch (this) {
      case ExportStyle.modern:
        return Icons.trending_up;
      case ExportStyle.classic:
        return Icons.book;
      case ExportStyle.minimal:
        return Icons.minimize;
      case ExportStyle.colorful:
        return Icons.color_lens;
      case ExportStyle.academic:
        return Icons.school;
    }
  }
}

/// The Note detail screen which shows note content, audio, and export options.
class NoteDetailScreen extends ConsumerStatefulWidget {
  /// The note ID, parsed from a string parameter.
  final int noteId;

  NoteDetailScreen({
    super.key,
    required String noteIdStr,
  }) : noteId = int.parse(noteIdStr);

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlayerInitialized = false;

  late final StreamSubscription<PlayerState> _playerStateSub;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration?> _durationSub;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      if (!mounted) return;
      setState(() {
        _isPlaying = playerState.playing;
      });
    });

    _positionSub = _audioPlayer.positionStream.listen((position) {
      if (!mounted) return;
      setState(() {
        _position = position;
      });
    });

    _durationSub = _audioPlayer.durationStream.listen((duration) {
      if (!mounted) return;
      if (duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });
  }

  Future<void> _loadAudioFile(String path) async {
    try {
      await _audioPlayer.setFilePath(path);
      if (!mounted) return;
      setState(() {
        _isPlayerInitialized = true;
      });
    } catch (e) {
      debugPrint('Error loading audio file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playPauseAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  /// Builds the PDF preview based on the selected style.
  Widget _buildPdfPreview(ExportStyle style, String title, String content,
      String date, String? categoryName) {
    switch (style) {
      case ExportStyle.modern:
        return _modernPdfPreview(title, content, date, categoryName);
      case ExportStyle.classic:
        return _classicPdfPreview(title, content, date, categoryName);
      case ExportStyle.minimal:
        return _minimalPdfPreview(title, content, date, categoryName);
      case ExportStyle.colorful:
        return _colorfulPdfPreview(title, content, date, categoryName);
      case ExportStyle.academic:
        return _academicPdfPreview(title, content, date, categoryName);
    }
  }

  /// For DOCX we can use the same preview as PDF.
  Widget _buildDocxPreview(ExportStyle style, String title, String content,
      String date, String? categoryName) {
    return _buildPdfPreview(style, title, content, date, categoryName);
  }

  /// Modern PDF preview style.
  Widget _modernPdfPreview(
      String title, String content, String date, String? categoryName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isNotEmpty ? title : 'Untitled Note',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (categoryName != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(
                      red: Color(0xFF2563EB).r,
                      green: Color(0xFF2563EB).g,
                      blue: Color(0xFF2563EB).b,
                      alpha: 0.1
                  ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: const Color(0xFF2563EB).withValues(
                      red: Color(0xFF2563EB).r,
                      green: Color(0xFF2563EB).g,
                      blue: Color(0xFF2563EB).b,
                      alpha: 0.2
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  /// Classic PDF preview style.
  Widget _classicPdfPreview(
      String title, String content, String date, String? categoryName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isNotEmpty ? title : 'Untitled Note',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date + (categoryName != null ? ' • $categoryName' : ''),
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  /// Minimal PDF preview style.
  Widget _minimalPdfPreview(
      String title, String content, String date, String? categoryName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isNotEmpty ? title : 'Untitled Note',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date + (categoryName != null ? ' • $categoryName' : ''),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Colorful PDF preview style.
  Widget _colorfulPdfPreview(
      String title, String content, String date, String? categoryName) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title.isNotEmpty ? title : 'Untitled Note',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(
                      red: Color(0xFF6366F1).r,
                      green: Color(0xFF6366F1).g,
                      blue: Color(0xFF6366F1).b,
                      alpha: 0.3
                  ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF6366F1).withValues(
                      red: Color(0xFF6366F1).r,
                      green: Color(0xFF6366F1).g,
                      blue: Color(0xFF6366F1).b,
                      alpha: 0.2
                  ),
                    ),
                  ),
                  child: Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                if (categoryName != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(
                      red: Color(0xFF8B5CF6).r,
                      green: Color(0xFF8B5CF6).g,
                      blue: Color(0xFF8B5CF6).b,
                      alpha: 0.1
                  ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(
                      red: Color(0xFF8B5CF6).r,
                      green: Color(0xFF8B5CF6).g,
                      blue: Color(0xFF8B5CF6).b,
                      alpha: 0.1
                  )),
                    ),
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(
                      red: Colors.indigo.r,
                      green: Colors.indigo.g,
                      blue: Colors.indigo.b,
                      alpha: 0.1
                  ),
                    spreadRadius: 0,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  letterSpacing: 1.6,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Academic PDF preview style.
  Widget _academicPdfPreview(
      String title, String content, String date, String? categoryName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'RESEARCH NOTE',
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              title.isNotEmpty ? title : 'Untitled Note',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              date,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (categoryName != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  categoryName,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(16),
            child: Text(
              'Abstract: ${content.length > 200 ? '${content.substring(0, 200)}...' : content}',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'CONTENT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 1),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Enhanced PDF export with multiple styles.
  Future<void> _exportToPdf(String title, String content, String date,
      String? categoryName, ExportStyle style) async {
    try {
      final pdf = pw.Document();
      switch (style) {
        case ExportStyle.modern:
          await _createModernPdf(pdf, title, content, date, categoryName);
          break;
        case ExportStyle.classic:
          await _createClassicPdf(pdf, title, content, date, categoryName);
          break;
        case ExportStyle.minimal:
          await _createMinimalPdf(pdf, title, content, date, categoryName);
          break;
        case ExportStyle.colorful:
          await _createColorfulPdf(pdf, title, content, date, categoryName);
          break;
        case ExportStyle.academic:
          await _createAcademicPdf(pdf, title, content, date, categoryName);
          break;
      }
      final outputDir = await getTemporaryDirectory();
      final file = File('${outputDir.path}/note_export.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)],
          text:
              "Here's your exported note in ${style.displayName} style.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'PDF exported successfully in ${style.displayName} style'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting to PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// DOCX export implementation.
  Future<void> _exportToDocx(String title, String content, String date,
      String? categoryName, ExportStyle style) async {
    try {
      // Check and/or create the templates directory.
      final templatesDir = await _getOrCreateTemplatesDir();
      final templateFile = await _getOrCreateDocxTemplate(templatesDir, style);

      if (templateFile == null) {
        throw Exception('Failed to create DOCX template');
      }

      final docxTemplate =
          await DocxTemplate.fromBytes(await templateFile.readAsBytes());

      final contentMap = Content()
        ..add(TextContent("title", title.isNotEmpty ? title : "Untitled Note"))
        ..add(TextContent("date", date))
        ..add(TextContent("category", categoryName ?? ""))
        ..add(TextContent("content", content));

      final generatedBytes = await docxTemplate.generate(contentMap);

      if (generatedBytes == null) {
        throw Exception('Failed to generate DOCX document');
      }

      final outputDir = await getTemporaryDirectory();
      final file = File('${outputDir.path}/note_export.docx');
      await file.writeAsBytes(generatedBytes);

      await Share.shareXFiles([XFile(file.path)],
          text:
              "Here's your exported note in ${style.displayName} style.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'DOCX exported successfully in ${style.displayName} style'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting to DOCX: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating DOCX: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Creates the templates directory if it doesn't exist.
  Future<Directory> _getOrCreateTemplatesDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final templatesDir = Directory('${appDir.path}/templates');
    if (!await templatesDir.exists()) {
      await templatesDir.create(recursive: true);
    }
    return templatesDir;
  }

  /// Gets (or creates) the DOCX template for a given export style.
  Future<File?> _getOrCreateDocxTemplate(
      Directory templatesDir, ExportStyle style) async {
    final templateFileName = '${style.name}_template.docx';
    final templateFile = File('${templatesDir.path}/$templateFileName');
    if (await templateFile.exists()) {
      return templateFile;
    }
    try {
      final assetPath = 'assets/templates/$templateFileName';
      final assetData = await rootBundle.load(assetPath);
      await templateFile.writeAsBytes(assetData.buffer.asUint8List());
      return templateFile;
    } catch (e) {
      debugPrint(
          'Template not found in assets, creating basic template: $e');
      // Here you might either create a basic template programmatically
      // or instruct the user to include one.
      throw Exception(
          'DOCX template not found. Please add template files to assets/templates/');
    }
  }

  /// Helper to format duration in mm:ss.
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(notesControllerProvider)
                    .deleteNote(widget.noteId);
                if (mounted) {
                  context.pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting note: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteProvider(widget.noteId));
    final double durationMs = _duration.inMilliseconds.toDouble();
    final double positionMs = _position.inMilliseconds.toDouble();
    final double sliderMax = durationMs > 0 ? durationMs : 1.0;
    final double sliderValue = math.min(positionMs, sliderMax);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Note Details',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/notes/${widget.noteId}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context),
          ),
          // Keep the AppBar clean for monetization and personal operations
        ],
      ),
      body: noteAsync.when(
        data: (noteWithCategory) {
          final note = noteWithCategory.note;
          final category = noteWithCategory.category;

          if (note.audioPath != null && !_isPlayerInitialized) {
            _loadAudioFile(note.audioPath!);
          }

          return Stack(
            children: [
              // Main content with padding
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and metadata row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and category on the left
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.title.isNotEmpty ? note.title : 'Untitled Note',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    formatDate(note.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (category != null) ...[
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(category.name),
                                      backgroundColor: Color(category.color),
                                      padding: EdgeInsets.zero,
                                      labelStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showShareOptions(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withAlpha(1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.share,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Share',
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      note.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    if (note.audioPath != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(_isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow),
                                    onPressed: _isPlayerInitialized
                                        ? _playPauseAudio
                                        : null,
                                    iconSize: 36,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: sliderValue,
                                      min: 0,
                                      max: sliderMax,
                                      onChanged: (value) async {
                                        final newPosition =
                                            Duration(milliseconds: value.toInt());
                                        await _audioPlayer.seek(newPosition);
                                      },
                                    ),
                                  ),
                                  Text(_formatDuration(_position)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Total: ${_formatDuration(_duration)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('Error: $error')),
      ),
    );
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _createModernPdf(pw.Document pdf, String title, String content,
      String date, String? categoryName) async {
    try {
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title.isNotEmpty ? title : 'Untitled Note',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                      date,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 12,
                        color: PdfColors.grey600,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    if (categoryName != null) ...[
                      pw.SizedBox(width: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue100,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                        ),
                        child: pw.Text(
                          categoryName,
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 12,
                            color: PdfColors.blue700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Divider(color: PdfColors.blue200),
                pw.SizedBox(height: 24),
                pw.Text(
                  content,
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 16,
                    lineSpacing: 1.6,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.blue200),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Voice Notes App',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Page ${context.pageNumber} of ${context.pagesCount}',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title.isNotEmpty ? title : 'Untitled Note',
                  style:  pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                      date,
                      style:  pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    if (categoryName != null) ...[
                      pw.SizedBox(width: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue100,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                        ),
                        child: pw.Text(
                          categoryName,
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.blue700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Divider(color: PdfColors.blue200),
                pw.SizedBox(height: 24),
                pw.Text(
                  content,
                  style: const pw.TextStyle(
                    fontSize: 16,
                    lineSpacing: 1.6,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.blue200),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Voice Notes App',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Page ${context.pageNumber} of ${context.pagesCount}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }
  }

  Future<void> _createClassicPdf(pw.Document pdf, String title, String content,
      String date, String? categoryName) async {
    final fontData =
        await rootBundle.load("assets/fonts/Merriweather-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title.isNotEmpty ? title : 'Untitled Note',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                date + (categoryName != null ? ' • $categoryName' : ''),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 12,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                content,
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 16,
                  lineSpacing: 1.5,
                ),
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text(
                  '- ${context.pageNumber} -',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createMinimalPdf(pw.Document pdf, String title, String content,
      String date, String? categoryName) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title.isNotEmpty ? title : 'Untitled Note',
                style:  pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.normal,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                date + (categoryName != null ? ' • $categoryName' : ''),
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey500,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Text(
                content,
                style:  pw.TextStyle(
                  fontSize: 15,
                  lineSpacing: 1.7,
                  fontWeight: pw.FontWeight.normal,
                  letterSpacing: 0.3,
                ),
              ),
              pw.Spacer(),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 10),
                child: pw.Text(
                  context.pageNumber.toString(),
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createColorfulPdf(pw.Document pdf, String title, String content,
      String date, String? categoryName) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.grey100,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(24.0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      title.isNotEmpty ? title : 'Untitled Note',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.indigo100,
                          borderRadius: pw.BorderRadius.circular(20),
                          border: pw.Border.all(
                              color: PdfColors.indigo200),
                        ),
                        child: pw.Text(
                          date,
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.indigo,
                          ),
                        ),
                      ),
                      if (categoryName != null) ...[
                        pw.SizedBox(width: 8),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.purple100,
                            borderRadius: pw.BorderRadius.circular(20),
                            border: pw.Border.all(
                                color: PdfColors.purple200),
                          ),
                          child: pw.Text(
                            categoryName,
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.purple500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(12),
                      boxShadow: [
                      pw.BoxShadow(
                        offset: PdfPoint(0, 4),
                        color: PdfColor(
                          PdfColors.grey300.red,
                          PdfColors.grey300.green,
                          PdfColors.grey300.blue,
                          0.3,
                        ),
                        blurRadius: 5,
                      ),
                    ],
                    ),
                    child: pw.Text(
                      content,
                      style: pw.TextStyle(
                        fontSize: 16,
                        lineSpacing: 1.6,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                  ),
                  pw.Spacer(),
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo100,
                      borderRadius: pw.BorderRadius.circular(20),
                      border: pw.Border.all(
                          color: PdfColors.indigo200),
                    ),
                    child: pw.Text(
                      'Page ${context.pageNumber} of ${context.pagesCount}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createAcademicPdf(pw.Document pdf, String title, String content,
      String date, String? categoryName) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'RESEARCH NOTE',
                  style: pw.TextStyle(
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  title.isNotEmpty ? title : 'Untitled Note',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  date,
                  style:  pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              if (categoryName != null)
                pw.Center(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.only(top: 8),
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(2)),
                    ),
                    child: pw.Text(
                      categoryName,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              pw.SizedBox(height: 32),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  'Abstract: ${content.length > 200 ? '${content.substring(0, 200)}...' : content}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                    lineSpacing: 1.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'CONTENT',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 16),
              pw.Text(
                content,
                style: pw.TextStyle(
                  fontSize: 15,
                  lineSpacing: 1.6,
                  color: PdfColors.black,
                ),
              ),
              pw.Spacer(),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on ${DateTime.now().toString().split(' ')[0]}',
                    style:  pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    '${context.pageNumber}/${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

void _showShareOptions(BuildContext context) async {
  try {
    // Retrieve the NoteDao from your AppDatabase provider
    final noteDao = ref.read(databaseProvider).noteDao;
    // Fetch the note by its ID
    final noteWithCategory = await noteDao.getNoteWithCategory(widget.noteId);

    final note = noteWithCategory.note;
    final category = noteWithCategory.category;
    
    final title = note.title;
    final content = note.content;
    final date = formatDate(note.createdAt);
    final categoryName = category?.name;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with share options title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Share Options',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Quick Share Options
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Quick Share',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Quick Share Options Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 16.0,
                  runSpacing: 16.0,
                  children: [
                    _buildShareOption(
                      context, 
                      'Text', 
                      Icons.text_fields,
                      Colors.blue.shade700,
                      () async {
                        Navigator.pop(context);
                        final text = '$title\n\n$content';
                        await Share.share(text, subject: title);
                      }
                    ),
                    _buildShareOption(
                      context, 
                      'Copy', 
                      Icons.copy,
                      Colors.purple.shade700,
                      () {
                        Navigator.pop(context);
                        Clipboard.setData(ClipboardData(text: content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note copied to clipboard')),
                        );
                      }
                    ),
                    _buildShareOption(
                      context, 
                      'Save to Notes', 
                      Icons.note_add,
                      Colors.amber.shade800,
                      () {
                        // Implement system note taking app integration
                        Navigator.pop(context);
                        _saveToSystemNotes(title, content);
                      }
                    ),
                    _buildShareOption(
                      context, 
                      'Reminder', 
                      Icons.notification_add,
                      Colors.green.shade700,
                      () {
                        Navigator.pop(context);
                        _createReminderForNote(title, content);
                      }
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              const Divider(),
              
              // Export Options
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Export As Document',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Export Options List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _buildExportTile(
                      context, 
                      'PDF Document',
                      'Export with formatting and styles',
                      Icons.picture_as_pdf,
                      Colors.red.shade700,
                      () {
                        Navigator.pop(context);
                        _showExportPreview(context, title, content, date, categoryName, true);
                      }
                    ),
                    const SizedBox(height: 12),
                    _buildExportTile(
                      context, 
                      'Word Document (DOCX)',
                      'Export to Microsoft Word format',
                      Icons.description,
                      Colors.blue.shade700,
                      () {
                        Navigator.pop(context);
                        _showExportPreview(context, title, content, date, categoryName, false);
                      }
                    ),
                    const SizedBox(height: 12),
                    _buildExportTile(
                      context, 
                      'Plain Text (.txt)',
                      'Simple text without formatting',
                      Icons.text_snippet,
                      Colors.grey.shade700,
                      () async {
                        Navigator.pop(context);
                        await _exportToPlainText(title, content);
                      }
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  } catch (e) {
    debugPrint('Error fetching note for sharing: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error preparing share options: $e')),
    );
  }
}

Widget _buildShareOption(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: SizedBox( 
      width: MediaQuery.of(context).size.width * 0.2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(red: color.r,green: color.g,blue: color.b,alpha:0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// Build an export option list tile
Widget _buildExportTile(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(red:color.r,green:color.g,blue:color.b,alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    ),
  );
}

// Export to plain text file
Future<void> _exportToPlainText(String title, String content) async {
  try {
    final plainText = '$title\n\n$content';
    final outputDir = await getTemporaryDirectory();
    final file = File('${outputDir.path}/note_export.txt');
    await file.writeAsBytes(utf8.encode(plainText));
    await Share.shareXFiles([XFile(file.path)],
        text: "Here's your exported note as plain text.");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text file exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    debugPrint('Error exporting to text file: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating text file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Save to system notes (platform-specific implementation)
Future<void> _saveToSystemNotes(String title, String content) async {
  try {
    if (Platform.isIOS) {
      // iOS Notes app integration via URL scheme
      final encodedTitle = Uri.encodeComponent(title);
      final encodedContent = Uri.encodeComponent(content);
      final url = Uri.parse('mobilenotes://create?title=$encodedTitle&body=$encodedContent');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw Exception('Could not launch Notes app');
      }
    } else if (Platform.isAndroid) {
      // Android - use Intent to create a new note
      // This would typically be implemented using method channels
      // For this example, we'll just show a placeholder message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Integration with system notes app would be implemented here for Android'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      throw Exception('Platform not supported for system notes integration');
    }
  } catch (e) {
    debugPrint('Error saving to system notes: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not save to system notes: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Create a reminder for this note
Future<void> _createReminderForNote(String title, String content) async {
  try {
    // Show date/time picker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      // Show time picker if date was selected
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (pickedTime != null) {
        // Combine date and time
        final reminderDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        // Here you would typically integrate with a notification system
        // For this example, we'll just show a confirmation
        final formattedDateTime = DateFormat('MMM d, yyyy \'at\' h:mm a').format(reminderDateTime);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for "$title" on $formattedDateTime'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('Error creating reminder: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not create reminder: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Modify the existing _showExportPreview method to accept an isPdfSelected parameter
void _showExportPreview(BuildContext context, String title, String content,
    String date, String? categoryName, bool isPdfSelected) {
  ExportStyle selectedStyle = ExportStyle.modern;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with export preview title.
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Export Preview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Tabs for selecting PDF or DOCX.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('PDF'),
                          selected: isPdfSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                isPdfSelected = true;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('DOCX'),
                          selected: !isPdfSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                isPdfSelected = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Horizontal list for export style selection.
                SizedBox(
                  height: 90, // Increased from 80 to 90 to fix overflow
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: ExportStyle.values.length,
                    itemBuilder: (context, index) {
                      final style = ExportStyle.values[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedStyle = style;
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min, // Ensures the column takes minimum space needed
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selectedStyle == style
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  style.icon,
                                  color: selectedStyle == style
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                style.displayName,
                                style: TextStyle(
                                  color: selectedStyle == style
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade700,
                                  fontWeight: selectedStyle == style
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12, // Slightly reduced to avoid overflow
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Preview area.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300.withValues(red: Colors.grey.shade300.r,green: Colors.grey.shade300.g,blue: Colors.grey.shade300.b,alpha:0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: isPdfSelected
                          ? _buildPdfPreview(
                              selectedStyle, title, content, date, categoryName)
                          : _buildDocxPreview(
                              selectedStyle, title, content, date, categoryName),
                    ),
                  ),
                ),
                // Export button.
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      if (isPdfSelected) {
                        await _exportToPdf(
                            title, content, date, categoryName, selectedStyle);
                      } else {
                        await _exportToDocx(
                            title, content, date, categoryName, selectedStyle);
                      }
                    },
                    child: Text(
                      'Export as ${isPdfSelected ? 'PDF' : 'DOCX'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
}