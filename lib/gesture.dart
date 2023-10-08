import 'package:flutter/material.dart' hide Ink;
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

class DigitalInkView extends StatefulWidget {
  const DigitalInkView({super.key});

  @override
  State<DigitalInkView> createState() => _DigitalInkViewState();
}

class _DigitalInkViewState extends State<DigitalInkView> {
  final DigitalInkRecognizerModelManager _modelManager =
      DigitalInkRecognizerModelManager();
  final _digitalInkRecognizer = DigitalInkRecognizer(languageCode: 'en');
  final Ink _ink = Ink();
  List<StrokePoint> _points = [];
  String _recognizedText = '';
  bool _modelDownloaded = false;

  @override
  void initState() {
    super.initState();
    _initModelDownload();
  }

  Future<void> _initModelDownload() async {
    final isModelDownloaded = await _modelManager.isModelDownloaded('en');
    if (!isModelDownloaded) {
      await _downloadModel();
    }
    setState(() {
      _modelDownloaded = true;
    });
  }

  @override
  void dispose() {
    _digitalInkRecognizer.close();
    super.dispose();
  }

  Future<void> _downloadModel() async {
    await _modelManager.downloadModel('en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(221, 94, 151, 251),
        title: const Text('Digital AI'),
        actions: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 16.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _modelDownloaded ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: GestureDetector(
                onPanStart: (DragStartDetails details) {
                  _ink.strokes.add(Stroke());
                },
                onPanUpdate: (DragUpdateDetails details) {
                  setState(() {
                    final RenderObject? object = context.findRenderObject();
                    final localPosition = (object as RenderBox?)
                        ?.globalToLocal(details.localPosition);
                    if (localPosition != null) {
                      _points = List.from(_points)
                        ..add(StrokePoint(
                          x: localPosition.dx,
                          y: localPosition.dy,
                          t: DateTime.now().millisecondsSinceEpoch,
                        ));
                    }
                    if (_ink.strokes.isNotEmpty) {
                      _ink.strokes.last.points = _points.toList();
                    }
                  });
                },
                onPanEnd: (DragEndDetails details) {
                  _points.clear();
                  setState(() {});
                },
                child: CustomPaint(
                  painter: Signature(ink: _ink),
                  size: Size.infinite,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _clearPad,
                    child: const Text('Clear'),
                  ),
                  ElevatedButton(
                    onPressed: _recogniseText,
                    child: const Text('Read Text'),
                  ),
                ],
              ),
            ),
            if (_recognizedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'Output: $_recognizedText',
                  style: const TextStyle(fontSize: 23),
                  textAlign: TextAlign.left,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _clearPad() {
    setState(() {
      _ink.strokes.clear();
      _points.clear();
      _recognizedText = '';
    });
  }

  Future<void> _recogniseText() async {
    final candidates = await _digitalInkRecognizer.recognize(_ink);
    _recognizedText = '';
    _recognizedText = '\n${candidates[0].text}';
    setState(() {});
  }
}

class Signature extends CustomPainter {
  Ink ink;

  Signature({required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (final stroke in ink.strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(Offset(p1.x.toDouble(), p1.y.toDouble()),
            Offset(p2.x.toDouble(), p2.y.toDouble()), paint);
      }
    }
  }

  @override
  bool shouldRepaint(Signature oldDelegate) => true;
}
