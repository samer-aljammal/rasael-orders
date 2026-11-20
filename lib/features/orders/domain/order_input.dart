import 'dart:math';

import 'gift_kind.dart';

/// Small, pure rules for turning what gets typed into storable values.
/// Kept together so they share one set of tests.
abstract final class OrderInput {
  static const _alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// «R-K3F9A». Same shape as the codes the order form makes, so orders
  /// from the app and from the form read the same in WhatsApp.
  static String newCode({Random? random}) {
    final r = random ?? Random.secure();
    final body = List.generate(5, (_) => _alphabet[r.nextInt(_alphabet.length)]);
    return 'R-${body.join()}';
  }

  /// Phone numbers as WhatsApp wants them: digits only, with the country
  /// code. «0933 123 456» → «963933123456», «+963…» and «00963…» likewise.
  /// Returns null when nothing usable is left.
  static String? whatsapp(String input) {
    var d = input.replaceAll(RegExp(r'[^0-9٠-٩]'), '');
    d = d.replaceAllMapped(
      RegExp('[٠-٩]'),
      (m) => '${m[0]!.codeUnitAt(0) - 0x0660}',
    );
    if (d.startsWith('00')) d = d.substring(2);
    if (RegExp(r'^09\d{8}$').hasMatch(d)) d = '963${d.substring(1)}';
    if (d.length < 8 || d.length > 15) return null;
    return d;
  }

  /// «@name», «instagram.com/name/» or «name» → «name».
  static String? instagram(String input) {
    var s = input.trim();
    final url = RegExp(r'instagram\.com/([A-Za-z0-9._]+)').firstMatch(s);
    if (url != null) s = url.group(1)!;
    s = s.replaceFirst(RegExp('^@'), '');
    if (!RegExp(r'^[A-Za-z0-9._]{1,30}$').hasMatch(s)) return null;
    return s.toLowerCase();
  }

  /// The package names and prices on the live price list, by kind.
  /// The first one is the default.
  static List<({String name, int price})> packagesFor(GiftKind kind) {
    if (kind.isInvitation) {
      return const [
        (name: 'أساسي', price: 1000),
        (name: 'الأكثر طلباً', price: 2000),
        (name: 'مميز', price: 3500),
      ];
    }
    if (kind == GiftKind.wrapped) {
      return const [(name: 'ملخّص حبّنا', price: 1500)];
    }
    return const [
      (name: 'الأكثر طلباً', price: 1000),
      (name: 'مميز', price: 1500),
    ];
  }
}
