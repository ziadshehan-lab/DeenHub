/// تحويل الأرقام اللاتينية إلى أرقام عربية مشرقية (٠١٢٣٤٥٦٧٨٩).
String toArabicDigits(int number) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var result = number.toString();
  for (var i = 0; i < western.length; i++) {
    result = result.replaceAll(western[i], eastern[i]);
  }
  return result;
}

/// رقم الآية بصيغة المصحف: ﴿١٢﴾
String ayahNumberOrnament(int number) => '﴿${toArabicDigits(number)}﴾';

/// تحويل الأرقام داخل نص (مثل ساعة "04:10") إلى أرقام عربية مشرقية.
String toArabicDigitsInText(String input) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  var result = input;
  for (var i = 0; i < western.length; i++) {
    result = result.replaceAll(western[i], eastern[i]);
  }
  return result;
}

/// تنسيق وقت بصيغة ٢٤ ساعة بأرقام عربية: ٠٤:١٠.
String arabicTime(DateTime time) {
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  return toArabicDigitsInText('$hh:$mm');
}
