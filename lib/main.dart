import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.camera});

  final CameraDescription camera;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SatrCam',
      theme: ThemeData(useMaterial3: true),
      home: TakePictureScreen(camera: camera),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.previewSize!.height,
                    height: _controller.value.previewSize!.width,
                    child: CameraPreview(_controller),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: FloatingActionButton(
                    onPressed: () async {
                      try {
                        await _initializeControllerFuture;
                        final image = await _controller.takePicture();
                        await GallerySaver.saveImage(image.path);
                        if (!mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                DisplayPictureScreen(imagePath: image.path),
                          ),
                        );
                      } catch (e) {
                        // Ignore errors for now.
                      }
                    },
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  const DisplayPictureScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Captured Image')),
      body: Center(child: Image.file(File(imagePath))),
    );
  }
}

