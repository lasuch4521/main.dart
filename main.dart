import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  runApp(const MaterialApp(
    home: ImageToPdfScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  bool _isConverting = false;

  Future<void> _pickImages() async {
    final List<XFile> selected = await _picker.pickMultiImage();
    if (selected.isNotEmpty) {
      setState(() {
        _images = selected;
      });
    }
  }

  Future<void> _generatePdf() async {
    if (_images.isEmpty) return;

    setState(() => _isConverting = true);

    try {
      final pdf = pw.Document();

      for (var file in _images) {
        final imageBytes = await File(file.path).readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = "${dir.path}/skan_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final pdfFile = File(filePath);
      await pdfFile.writeAsBytes(await pdf.save());

      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd: $e')),
      );
    } finally {
      setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konwerter do PDF'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isConverting ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Wybierz zdjęcia'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
            ),
            const SizedBox(height: 12),
            Text('Wybrano: ${_images.length} zdjęć', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: _images.isEmpty
                  ? const Center(child: Text('Brak wybranych zdjęć'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(File(_images[index].path), fit: BoxFit.cover),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            if (_isConverting)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _images.isEmpty ? null : _generatePdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Scal do PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
