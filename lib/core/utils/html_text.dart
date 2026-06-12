/// تحويل نص HTML (كما تعيده بعض واجهات التفسير) إلى نص خالص قابل للعرض.
String stripHtml(String input) {
  var text = input
      // فواصل الفقرات تتحول إلى أسطر جديدة
      .replaceAll(RegExp(r'<(br|/p|/h\d|/div)[^>]*>'), '\n')
      // إزالة بقية الوسوم
      .replaceAll(RegExp(r'<[^>]+>'), '');

  // فك ترميز أكثر كيانات HTML شيوعاً
  const entities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
    '&laquo;': '«',
    '&raquo;': '»',
  };
  entities.forEach((entity, char) {
    text = text.replaceAll(entity, char);
  });

  // ضبط المسافات والأسطر المتكررة
  text = text
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return text.trim();
}
