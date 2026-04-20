import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> sharePngBytes(Uint8List pngBytes, {required String text}) async {
  final directory = await getTemporaryDirectory();
  final imagePath = '${directory.path}/clarity_report.png';
  final file = File(imagePath);
  await file.writeAsBytes(pngBytes);

  await Share.shareXFiles(
    [XFile(imagePath)],
    text: text,
  );
}

