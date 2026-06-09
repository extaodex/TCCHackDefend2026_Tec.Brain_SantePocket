import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/theme/app_theme.dart';
import 'documents_provider.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickDocument() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory(p.join(appDir.path, 'scanned_docs'));
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      final imagePath = image.path;
      _showSaveDialog(imagePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la capture : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSaveDialog(String imagePath) {
    final typeController = TextEditingController(text: 'Examen Médical');
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Enregistrer le document', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Type de document', labelStyle: TextStyle(color: Colors.white70)),
            ),
            TextField(
              controller: commentController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Commentaire (optionnel)', labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final type = typeController.text;
              final comment = commentController.text;
              Navigator.pop(ctx);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final pdf = pw.Document();
                final image = pw.MemoryImage(File(imagePath).readAsBytesSync());
                pdf.addPage(pw.Page(build: (pw.Context context) => pw.Center(child: pw.Image(image))));

                final pdfPath = imagePath.replaceAll('.jpg', '.pdf');
                final pdfFile = File(pdfPath);
                await pdfFile.writeAsBytes(await pdf.save());

                await ref.read(documentsProvider.notifier).addDocument(type, pdfPath, comment);

                File(imagePath).deleteSync();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Document enregistré'), backgroundColor: AppTheme.validatedGreenLight),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Erreur : $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Mes Documents'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.blueGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlueLight)),
        error: (e, _) => Center(child: Text('Erreur : $e', style: const TextStyle(color: Colors.red))),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.document_scanner_rounded, size: 64,
                        color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 16),
                    const Text('Aucun document numérisé',
                        style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text(
                      'Appuyez sur le bouton "+" pour scanner une ordonnance ou un examen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white30, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final isOrdonnance = doc.type.toLowerCase().contains('ordonnance');
              final icon = isOrdonnance ? Icons.receipt_long_rounded : Icons.science_rounded;
              final color = isOrdonnance ? AppTheme.primaryBlueLight : AppTheme.validatedGreenLight;

              return GestureDetector(
                onTap: () async {
                  final file = File(doc.resultatPdfPath);
                  if (await file.exists()) {
                    final bytes = await file.readAsBytes();
                    await Printing.layoutPdf(
                      onLayout: (format) => bytes,
                      name: p.basename(doc.resultatPdfPath),
                    );
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fichier introuvable'), backgroundColor: Colors.orange),
                      );
                    }
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.type,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(doc.commentaire.isEmpty ? 'Aucun commentaire' : doc.commentaire,
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, size: 14, color: Colors.red),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(p.basename(doc.resultatPdfPath),
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white30),
                        onPressed: () {
                          if (doc.id != null) {
                            ref.read(documentsProvider.notifier).deleteDocument(doc.id!);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickDocument,
        backgroundColor: AppTheme.primaryBlueLight,
        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
        label: const Text('Scanner un doc médical', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
