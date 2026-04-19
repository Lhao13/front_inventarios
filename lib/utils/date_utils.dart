class AppDateUtils {
  /// Formatea una fecha como YYYY-MM-DD sin dependencias externas
  static String formatYYYYMMDD(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
