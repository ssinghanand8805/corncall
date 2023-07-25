import 'dart:io';

import 'package:better_open_file/better_open_file.dart';
import 'package:corncall/widgets/PhotoEditor/photoeditor.dart';
import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';
import 'package:path_provider/path_provider.dart';

class ImagePainterEditor extends StatefulWidget {
  final File imagePaintFile;
  const ImagePainterEditor({Key? key, required this.imagePaintFile}) : super(key: key);

  @override
  State<ImagePainterEditor> createState() => _ImagePainterEditorState();
}

class _ImagePainterEditorState extends State<ImagePainterEditor> {
  final _imageKey = GlobalKey<ImagePainterState>();
  void saveImage() async {
    final image = await _imageKey.currentState?.exportImage();
    print("Image full path ${image}");
    final directory = (await getApplicationDocumentsDirectory()).path;
    await Directory('$directory/sample').create(recursive: true);
    final fullPath =
        '$directory/sample/${DateTime.now().millisecondsSinceEpoch}.png';
    final imgFile = File('$fullPath');
    if (image != null) {
      // imgFile.writeAsBytesSync(image);
      widget.imagePaintFile.writeAsBytesSync(image);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.grey[700],
          padding: const EdgeInsets.only(left: 10),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Image Exported successfully.",
                  style: TextStyle(color: Colors.white)),
              // TextButton(
              //   onPressed: () => OpenFile.open("$fullPath"),
              //   child: Text(
              //     "Open",
              //     style: TextStyle(
              //       color: Colors.blue[200],
              //     ),
              //   ),
              // )
            ],
          ),
        ),
      );
      await Navigator.pushReplacement(
          context,
          new MaterialPageRoute(
              builder: (context) => PhotoEditor(
                isPNG: false,
                onImageEdit: (editedImage) {
                  // widget.onTakeFile(editedImage);
                },
                imageFilePreSelected: widget.imagePaintFile,
              )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(

            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await Navigator.pushReplacement(
                  context,
                  new MaterialPageRoute(
                      builder: (context) => PhotoEditor(
                        isPNG: false,
                        onImageEdit: (editedImage) {
                          // widget.onTakeFile(editedImage);
                        },
                        imageFilePreSelected: widget.imagePaintFile,
                      )));
            },
          ),
          title: const Text("Image Painter Example"),
          actions: [
            IconButton(

              icon: const Icon(Icons.check),
              onPressed: saveImage,
            )
          ],
        ),
        backgroundColor: Colors.black,
        body: ImagePainter.file(

            widget.imagePaintFile, key: _imageKey)
        // body: ImagePainter.asset(
        //   "assets/backgroundImage.png",
        //   key: _imageKey,
        //   scalable: true,
        //   initialStrokeWidth: 2,
        //   textDelegate: TextDelegate(),
        //   initialColor: Colors.green,
        //   initialPaintMode: PaintMode.line,
        // ),
      ),
    );
  }
}
