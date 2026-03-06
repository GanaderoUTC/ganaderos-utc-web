class Validators {
  static String? requiredField(String? v, {String msg = 'Campo obligatorio'}) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }

  static String? name(String? v, {String msg = 'Nombre inválido'}) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    final s = v.trim();
    final reg = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ ]{2,60}$");
    if (!reg.hasMatch(s)) return msg;
    return null;
  }

  static String? email(String? v, {String msg = 'Correo inválido'}) {
    if (v == null || v.trim().isEmpty) return 'Ingrese correo';
    final s = v.trim();
    final reg = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$");
    if (!reg.hasMatch(s)) return msg;
    return null;
  }

  static String? cedulaEC(
    String? v, {
    String msg = 'Cédula ecuatoriana inválida',
  }) {
    if (v == null || v.trim().isEmpty) return 'Ingrese cédula';
    final s = v.trim();
    if (!RegExp(r"^\d{10}$").hasMatch(s)) return msg;

    final province = int.parse(s.substring(0, 2));
    if (province < 1 || province > 24) return msg;

    final third = int.parse(s[2]);
    if (third >= 6) return msg;

    final digits = s.split('').map(int.parse).toList();
    final verifier = digits[9];

    int sum = 0;
    for (int i = 0; i < 9; i++) {
      int d = digits[i];
      if (i % 2 == 0) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
    }

    final nextTen = ((sum + 9) ~/ 10) * 10;
    int check = nextTen - sum;
    if (check == 10) check = 0;

    if (check != verifier) return msg;
    return null;
  }

  static String? username(String? v, {String msg = 'Usuario inválido'}) {
    if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
    final s = v.trim();
    if (s.length < 3) return 'Mínimo 3 caracteres';
    // permite letras, números, punto y guion bajo
    if (!RegExp(r"^[a-zA-Z0-9._]{3,30}$").hasMatch(s)) return msg;
    return null;
  }

  static String? passwordStrong(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingrese contraseña';
    final s = v.trim();
    if (s.length < 6) return 'Mínimo 6 caracteres';
    if (!RegExp(r"[A-Za-z]").hasMatch(s)) return 'Debe contener letras';
    if (!RegExp(r"\d").hasMatch(s)) return 'Debe contener números';
    return null;
  }
}
