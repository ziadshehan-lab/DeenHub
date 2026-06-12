import 'dart:ui' show TextRange;

/// تبسيط النص العربي للمقارنة والبحث: إزالة التشكيل وعلامات المصحف
/// وتوحيد أشكال الألف والهمزة.
String normalizeArabic(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = _normalizeRune(rune);
    buffer.write(ch);
  }
  return buffer.toString().trim();
}

/// تحويل محرف واحد: يعيد '' للمحارف المحذوفة (تشكيل/علامات)،
/// أو المحرف المبسَّط.
String _normalizeRune(int rune) {
  // التشكيل والعلامات القرآنية (نطاقات يونيكود العربية الممتدة) والتطويل
  if ((rune >= 0x064B && rune <= 0x065F) ||
      rune == 0x0670 ||
      (rune >= 0x06D6 && rune <= 0x06ED) ||
      (rune >= 0x08D3 && rune <= 0x08FF) ||
      rune == 0x0640) {
    return '';
  }
  final ch = String.fromCharCode(rune);
  return switch (ch) {
    'أ' || 'إ' || 'آ' || 'ٱ' => 'ا',
    'ى' => 'ي',
    'ة' => 'ه',
    'ۥ' || 'ۦ' => '',
    _ => ch,
  };
}

/// إيجاد مواضع تطابق [query] داخل [text] مع تجاهل التشكيل وفروق
/// أشكال الحروف، وإعادة المدى بإحداثيات النص الأصلي (لأغراض الإبراز).
List<TextRange> findArabicMatches(String text, String query) {
  final normalizedQuery = normalizeArabic(query);
  if (normalizedQuery.isEmpty) return const [];

  // بناء النص المبسَّط مع خريطة من موضع كل محرف مبسَّط إلى موضعه الأصلي
  final normalized = StringBuffer();
  final originalIndices = <int>[];
  var originalIndex = 0;
  for (final rune in text.runes) {
    final ch = _normalizeRune(rune);
    if (ch.isNotEmpty) {
      normalized.write(ch);
      originalIndices.add(originalIndex);
    }
    originalIndex += String.fromCharCode(rune).length;
  }
  final haystack = normalized.toString();

  final ranges = <TextRange>[];
  var from = 0;
  while (true) {
    final at = haystack.indexOf(normalizedQuery, from);
    if (at < 0) break;
    final endNormalized = at + normalizedQuery.length;
    final start = originalIndices[at];
    final end = endNormalized < originalIndices.length
        ? originalIndices[endNormalized]
        : text.length;
    ranges.add(TextRange(start: start, end: end));
    from = endNormalized;
  }
  return ranges;
}
