import '../../orders/domain/order_status.dart';

/// The replies a new account starts with, taken from the messages actually
/// sent to Rasael customers. One per stage, plus a general follow-up.
///
/// `(title, stage, body)`; tokens like {السعر} are filled per order.
const defaultReplies = <(String, OrderStatus?, String)>[
  (
    'وصل الطلب',
    OrderStatus.newOrder,
    'وصلني طلبك 🤍 شكراً إلك!\n'
        'عم اشتغل عليه هلّق، وببعتلك فيديو للصفحة خلال ساعات.\n'
        'إذا بدك تغيّر أي شي قبل، قلّي.',
  ),
  (
    'مع فيديو المعاينة',
    OrderStatus.inProgress,
    'هاي معاينة رسالة {لمين} 💌 شوفها للآخر.\n\n'
        'إذا بدك تغيّر أي كلمة قلّي وبعدّلها فوراً 🤍\n\n'
        'بتحوّل {السعر} على شام كاش وببعتلك الرابط فوراً.',
  ),
  (
    'تذكير بالدفع',
    OrderStatus.previewSent,
    'مرحبا {الزبون} 🤍 بس حبيت اطمّن إذا شفت المعاينة؟\n'
        'إذا في أي شي بدك تغيّره قلّي.\n'
        'وإذا عجبتك، بتحوّل {السعر} على شام كاش وببعتلك الرابط فوراً.',
  ),
  (
    'الرابط بعد الدفع',
    OrderStatus.paid,
    'وصل، تسلم 🤍\n'
        'هاد رابط رسالة {لمين}:\n'
        '{الرابط}\n\n'
        'نصيحة: ابعتلها ياه بالليل، وقلّها تعلّي الصوت 🌙\n\n'
        'إذا عجبتك الشغلة، بتفرق معنا كتير تقلّنا رأيك أو تعملنا منشن @rasael.studio 🤍',
  ),
  (
    'شو كانت ردّة الفعل؟',
    OrderStatus.delivered,
    'مرحبا {الزبون} 🤍 كيف كانت ردّة الفعل لما فتحتها؟\n'
        'إذا حابب ابعتلي سكرين شوت من الرد (بلا أسامي)، بتساعدنا كتير 🙏',
  ),
  (
    'كود الطلب',
    null,
    'كود طلبك: {الكود}\nإذا سألت عن أي شي، ابعتلي ياه 🤍',
  ),
];
