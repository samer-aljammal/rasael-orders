import '../domain/gift_kind.dart';
import '../domain/order.dart';
import '../domain/order_source.dart';
import '../domain/order_status.dart';

/// Fictional orders for the demo. Every name, number and story is invented;
/// no real customer data ever ships in the app.
///
/// Dates are relative to [now] so the demo always looks like a live week:
/// something late, something due today, an unpaid preview to chase.
abstract final class DemoSeed {
  static List<Order> orders(DateTime now) {
    DateTime ago({int d = 0, int h = 0, int m = 0}) =>
        now.subtract(Duration(days: d, hours: h, minutes: m));
    DateTime today(int hour) => DateTime(now.year, now.month, now.day, hour);
    DateTime inDays(int d, int hour) =>
        DateTime(now.year, now.month, now.day + d, hour);

    var n = 0;
    Order o({
      required String code,
      required GiftKind kind,
      required String package,
      required int price,
      required OrderStatus status,
      required String customer,
      required DateTime created,
      String? from,
      String? to,
      DateTime? deadline,
      DateTime? previewSentAt,
      DateTime? paidAt,
      DateTime? deliveredAt,
      List<OrderDetail> details = const [],
      bool photos = false,
      bool music = false,
      String? notes,
    }) {
      n++;
      return Order(
        id: 'demo-$n',
        code: code,
        kind: kind,
        packageName: package,
        priceSyp: price,
        status: status,
        customerName: customer,
        customerWhatsapp: '963900000${(100 + n * 7).toString().padLeft(3, '0')}',
        senderName: from,
        recipientName: to,
        // Mostly chats from the bio page, like the real thing.
        source: switch (n % 5) {
          0 => OrderSource.form,
          1 || 3 => OrderSource.instagram,
          _ => OrderSource.whatsapp,
        },
        paymentMethod: paidAt == null
            ? null
            : n.isEven
            ? PaymentMethod.syriatelCash
            : PaymentMethod.shamCash,
        deadline: deadline,
        details: details,
        hasPhotos: photos,
        wantsMusic: music,
        notes: notes,
        pageUrl: status.index >= OrderStatus.previewSent.index &&
                status != OrderStatus.cancelled
            ? 'https://rasaelstudio.github.io/demo/${kind.id}/'
            : null,
        createdAt: created,
        updatedAt: deliveredAt ?? paidAt ?? previewSentAt ?? created,
        previewSentAt: previewSentAt,
        paidAt: paidAt,
        deliveredAt: deliveredAt,
      );
    }

    return [
      // -- New --------------------------------------------------------------
      o(
        code: 'R-M4Q7T',
        kind: GiftKind.letter,
        package: 'الأكثر طلباً',
        price: 1000,
        status: OrderStatus.newOrder,
        customer: 'كرم',
        from: 'كرم',
        to: 'جود',
        created: ago(m: 12),
        deadline: today(22),
        music: true,
        details: const [
          OrderDetail('اسم الدلع', 'جوجو'),
          OrderDetail('الرسالة', 'اكتبوها إنتو، تعرّفنا بالجامعة من سنتين'),
          OrderDetail('شو بتحب فيها', 'ضحكتها\nإنها بتفهمني من نظرة'),
        ],
      ),
      o(
        code: 'R-H2N8C',
        kind: GiftKind.cup,
        package: 'الأكثر طلباً',
        price: 1000,
        status: OrderStatus.newOrder,
        customer: 'نايا',
        from: 'نايا',
        to: 'يزن',
        created: ago(h: 1, m: 40),
        deadline: inDays(1, 20),
        details: const [
          OrderDetail('الحرفين', 'ن و ي'),
          OrderDetail('شو بدها يشوف', 'خاتم… وعرس قريب\nطريق أبيض'),
        ],
      ),
      o(
        code: 'R-W9E3K',
        kind: GiftKind.wedding,
        package: 'الأكثر طلباً',
        price: 2000,
        status: OrderStatus.newOrder,
        customer: 'أم سامر',
        from: 'سامر',
        to: 'لمى',
        created: ago(h: 3),
        deadline: inDays(3, 18),
        details: const [
          OrderDetail('الصالة والمدينة', 'صالة الياسمين، دمشق'),
          OrderDetail('الآية', 'وَمِنْ آيَاتِهِ أَنْ خَلَقَ لَكُم…'),
        ],
        notes: 'بدها الألوان أبيض وذهبي',
      ),

      // -- In progress ------------------------------------------------------
      o(
        code: 'R-B7L2P',
        kind: GiftKind.birthday,
        package: 'مميز',
        price: 1500,
        status: OrderStatus.inProgress,
        customer: 'تيم',
        from: 'تيم',
        to: 'ريم',
        created: ago(d: 1, h: 2),
        deadline: ago(h: 2),
        photos: true,
        music: true,
        details: const [
          OrderDetail('تاريخ الميلاد', '2004-11-21'),
          OrderDetail('تمنيات', 'ماما: الله يخليلي ياكِ\nسلمى: السنة الجاية منسافر سوا'),
        ],
      ),
      o(
        code: 'R-S5R1D',
        kind: GiftKind.sorry,
        package: 'الأكثر طلباً',
        price: 1000,
        status: OrderStatus.inProgress,
        customer: 'عمر',
        from: 'عمر',
        to: 'هبة',
        created: ago(h: 5),
        deadline: today(23),
        details: const [
          OrderDetail('شو صار', 'نسي عيد ميلادها'),
          OrderDetail('العروض', 'عشا\nكنافة\nمشوار عالربوة'),
        ],
      ),

      // -- Preview sent, waiting for payment ---------------------------------
      o(
        code: 'R-P8V6A',
        kind: GiftKind.proposal,
        package: 'مميز',
        price: 1500,
        status: OrderStatus.previewSent,
        customer: 'مجد',
        from: 'مجد',
        to: 'سارة',
        created: ago(d: 3, h: 4),
        previewSentAt: ago(d: 2, h: 20),
        music: true,
      ),
      o(
        code: 'R-Z3T9F',
        kind: GiftKind.wrapped,
        package: 'ملخّص حبّنا',
        price: 1500,
        status: OrderStatus.previewSent,
        customer: 'لين',
        from: 'لين',
        to: 'سامي',
        created: ago(d: 1, h: 6),
        previewSentAt: ago(h: 4),
        photos: true,
        music: true,
      ),

      // -- Paid -------------------------------------------------------------
      o(
        code: 'R-C6J4N',
        kind: GiftKind.engage,
        package: 'مميز',
        price: 3500,
        status: OrderStatus.paid,
        customer: 'آل النجّار',
        from: 'خالد',
        to: 'رهف',
        created: ago(d: 2, h: 3),
        previewSentAt: ago(d: 1, h: 8),
        paidAt: ago(h: 1),
        deadline: inDays(2, 19),
      ),

      // -- Delivered --------------------------------------------------------
      o(
        code: 'R-D1F5X',
        kind: GiftKind.letter,
        package: 'مميز',
        price: 1500,
        status: OrderStatus.delivered,
        customer: 'إياد',
        from: 'إياد',
        to: 'تالا',
        created: ago(d: 2, h: 9),
        previewSentAt: ago(d: 2, h: 5),
        paidAt: ago(d: 2, h: 3),
        deliveredAt: ago(d: 2, h: 2),
      ),
      o(
        code: 'R-K8G2Y',
        kind: GiftKind.reveal,
        package: 'الأكثر طلباً',
        price: 1000,
        status: OrderStatus.delivered,
        customer: 'ليلى',
        from: 'أحمد وليلى',
        created: ago(d: 4, h: 1),
        previewSentAt: ago(d: 3, h: 22),
        paidAt: ago(d: 3, h: 20),
        deliveredAt: ago(d: 3, h: 19),
      ),
      o(
        code: 'R-T4A7U',
        kind: GiftKind.birthday,
        package: 'الأكثر طلباً',
        price: 1000,
        status: OrderStatus.delivered,
        customer: 'رامي',
        from: 'رامي',
        to: 'ميرا',
        created: ago(d: 5, h: 6),
        previewSentAt: ago(d: 5, h: 2),
        paidAt: ago(d: 5, h: 1),
        deliveredAt: ago(d: 5),
      ),
      // -- Last month, so the history has more than one page ----------------
      for (final (i, (code, kind, price, from, to)) in const [
        ('R-Q7W2E', GiftKind.letter, 1500, 'باسل', 'نغم'),
        ('R-V3M8L', GiftKind.cup, 1000, 'دانة', 'وسيم'),
        ('R-J5T1R', GiftKind.birthday, 1000, 'سلمى', 'آدم'),
        ('R-G9C4H', GiftKind.wedding, 2000, 'مهند', 'رنا'),
        ('R-F6B3S', GiftKind.sorry, 1000, 'زياد', 'جنى'),
        ('R-E2K7P', GiftKind.letter, 1000, 'حسام', 'ليال'),
      ].indexed)
        o(
          code: code,
          kind: kind,
          package: price == 1500
              ? 'مميز'
              : price == 2000
              ? 'الأكثر طلباً'
              : 'الأكثر طلباً',
          price: price,
          status: OrderStatus.delivered,
          customer: from,
          from: from,
          to: to,
          created: ago(d: 24 + i * 3, h: 5),
          previewSentAt: ago(d: 24 + i * 3, h: 2),
          paidAt: ago(d: 24 + i * 3, h: 1),
          deliveredAt: ago(d: 24 + i * 3),
        ),
      o(
        code: 'R-N2X8B',
        kind: GiftKind.letter,
        package: 'الأكثر طلباً',
        price: 1000,
        status: OrderStatus.cancelled,
        customer: 'فادي',
        from: 'فادي',
        to: 'روان',
        created: ago(d: 6),
        notes: 'فكّرها مجانية، ما كمل',
      ),
    ];
  }
}
