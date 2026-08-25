
/// Производные дизайн-токены поверх [AppColors]/[AppTypography].
///
/// Цель — убрать разброс «магических» чисел по виджетам и дать
/// единую шкалу отступов и радиусов скругления, согласованную с
/// существующими значениями в коде (4/8/12/16/20 и 12/16/20/28).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Радиусы скругления для разных уровней поверхностей.
///
/// - `sm` — чипы, инпуты (было вразнобой 8/10).
/// - `md` — карточки, диалоги (было 14/16).
/// - `lg` — топ-бары, hero-элементы (было 20).
/// - `xl` — пилюли / FAB (было 28).
class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
}
