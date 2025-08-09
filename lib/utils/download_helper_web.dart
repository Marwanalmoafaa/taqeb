import 'dart:html' as html;

class DownloadHelper {
  // Trigger a browser download using an in-memory Blob
  static Future<String> saveBytes(
    List<int> bytes,
    String suggestedFileName,
  ) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = suggestedFileName
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return suggestedFileName;
  }
}
