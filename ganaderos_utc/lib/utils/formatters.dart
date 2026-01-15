import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _num2 = NumberFormat('#,##0.00', 'es_EC');
  static final NumberFormat _num0 = NumberFormat('#,##0', 'es_EC');

  static String num2(double v) => _num2.format(v);
  static String num0(num v) => _num0.format(v);

  static String litres(double v, {int decimals = 2}) {
    final f = decimals == 0 ? _num0 : _num2;
    return '${f.format(v)} L';
  }

  static String kg(double v, {int decimals = 2}) {
    final f = decimals == 0 ? _num0 : _num2;
    return '${f.format(v)} kg';
  }

  // Fallback: si intl no está inicializado, no rompe
  static String dayMonth(DateTime d) {
    try {
      return DateFormat('dd/MM', 'es_EC').format(d);
    } catch (_) {
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    }
  }
}
