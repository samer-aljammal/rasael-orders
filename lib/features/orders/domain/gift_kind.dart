/// What the customer ordered. The [id]s match the `kind` values of the
/// order form on rasaelstudio.github.io/order, so a pasted order maps
/// straight onto one of these.
enum GiftKind {
  letter('letter', 'رسالة حب'),
  birthday('birthday', 'عيد ميلاد'),
  proposal('proposal', 'طلب زواج'),
  sorry('sorry', 'صالحها'),
  cup('cup', 'اقريلو فنجانو'),
  wrapped('wrapped', 'ملخّص حبّنا'),
  wedding('wedding', 'دعوة عرس'),
  engage('engage', 'خطوبة / كتب كتاب'),
  reveal('reveal', 'صبي ولا بنت؟'),
  gfday('gfday', 'عيد الحبيبة'),
  other('other', 'مناسبة تانية');

  const GiftKind(this.id, this.label);

  final String id;
  final String label;

  /// Invitations are sent to many guests; gifts go to one person.
  bool get isInvitation => this == wedding || this == engage;

  static GiftKind fromId(String? id) => GiftKind.values.firstWhere(
    (k) => k.id == id,
    orElse: () => GiftKind.other,
  );
}
