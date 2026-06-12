/// طريقة حساب مواقيت الصلاة (معرّفات واجهة AlAdhan الرسمية).
class CalculationMethod {
  const CalculationMethod({required this.id, required this.nameArabic});

  final int id;
  final String nameArabic;
}

/// طرق الحساب المدعومة.
const List<CalculationMethod> calculationMethods = [
  CalculationMethod(id: 4, nameArabic: 'جامعة أم القرى — مكة المكرمة'),
  CalculationMethod(id: 3, nameArabic: 'رابطة العالم الإسلامي'),
  CalculationMethod(id: 5, nameArabic: 'الهيئة المصرية العامة للمساحة'),
  CalculationMethod(
      id: 13, nameArabic: 'رئاسة الشؤون الدينية التركية (ديانت)'),
  CalculationMethod(
      id: 2, nameArabic: 'الجمعية الإسلامية لأمريكا الشمالية (ISNA)'),
];

/// الطريقة الافتراضية: أم القرى.
const CalculationMethod defaultCalculationMethod = CalculationMethod(
  id: 4,
  nameArabic: 'جامعة أم القرى — مكة المكرمة',
);
