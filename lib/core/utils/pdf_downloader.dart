import 'dart:io';

import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

/// Saves a PDF straight into the device's Downloads folder.
///
/// Android 10 and above let an app write into the shared Downloads collection
/// with no storage permission, so the file lands where the user expects it
/// with no share sheet in the way. Older systems cannot reach that folder
/// without a runtime grant, so they fall back to the share sheet rather than
/// fail outright -- the goal is still met, just through the system UI.
class PdfDownloader {
  PdfDownloader._();

  static const MethodChannel _channel = MethodChannel('saiseeds/pdf_download');

  /// Writes [bytes] to Downloads as [filename].
  ///
  /// Returns true when the file was written directly to Downloads, and false
  /// when this platform could not do so and the share sheet was shown
  /// instead. Anything that fails on both paths throws.
  static Future<bool> download(Uint8List bytes, String filename) async {
    if (!Platform.isAndroid) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return false;
    }

    try {
      await _channel.invokeMethod<void>('saveToDownloads', <String, Object>{
        'filename': filename,
        'bytes': bytes,
      });
      return true;
    } on MissingPluginException {
      // The channel is absent -- an engine that has not registered the
      // activity's handler. The share sheet still gets the file out.
      await Printing.sharePdf(bytes: bytes, filename: filename);
      return false;
    } on PlatformException catch (e) {
      if (e.code == 'UNSUPPORTED') {
        await Printing.sharePdf(bytes: bytes, filename: filename);
        return false;
      }
      rethrow;
    }
  }
}
