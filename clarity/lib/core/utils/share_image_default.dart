import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> sharePngBytes(Uint8List pngBytes, {required String text}) async {
  await Share.shareXFiles(
    [
      XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: 'clarity_report.png',
      ),
    ],
    text: text,
  );
}

