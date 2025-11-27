class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return "Email required";
    final regex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
    if (!regex.hasMatch(value)) return "Enter a valid email";
    return null;
  }


  static String? password(String? value) {
    if (value == null || value.isEmpty) return "Password required";
    if (value.length < 6) return "Password must be 6+ chars";
    return null;
  }


  static String? notEmpty(String? value, {String msg = "Required"}) {
    if (value == null || value.trim().isEmpty) return msg;
    return null;
  }
}