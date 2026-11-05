class Teacher {
  Teacher(this.id, this.name, this.bio, this.specialty, this.photoUrl);
  final String id, name;
  final String? bio, specialty, photoUrl;
  factory Teacher.fromJson(Map<String, dynamic> j) {
    final p = (j['profile'] as Map?) ?? {};
    return Teacher(j['id'] ?? '', j['fullName'] ?? '', p['bio'], p['specialty'], p['photoUrl']);
  }
}

class Progress {
  Progress(this.done, this.total);
  final int done, total;
  int get remaining => total - done;
  double get ratio => total == 0 ? 0 : done / total;
  static Progress? from(dynamic j) =>
      j is Map ? Progress((j['done'] ?? 0) as int, (j['total'] ?? 0) as int) : null;
}

class MySub {
  MySub(this.id, this.type, this.status, this.progress);
  final String id, type, status;
  final Progress? progress;
}

class Course {
  Course(this.json)
      : id = json['id'] as String,
        title = json['title'] as String? ?? '',
        description = json['description'] as String? ?? '',
        categoryId = (json['category'] as Map?)?['id'] as String?,
        categoryName = (json['category'] as Map?)?['name'] as String? ?? '',
        totalSessions = (json['totalSessions'] ?? 0) as int,
        price = _num(json['price']),
        pricePerSession = _num(json['pricePerSession']),
        trialPrice = _num(json['trialPrice']),
        trialAvailable = json['trialAvailable'] == true,
        packagesAvailable = json['packagesAvailable'] == true,
        trialUsed = json['trialUsed'] == true,
        currency = json['currency'] as String? ?? 'SAR',
        chatClosed = json['chatClosed'] == true,
        pendingConfirmation = json['pendingConfirmation'] == true,
        teacher = json['teacher'] is Map ? Teacher.fromJson(json['teacher']) : null,
        mySub = json['mySubscription'] is Map && json['mySubscription']['status'] != 'AWAITING_PAYMENT'
            ? MySub(json['mySubscription']['id'], json['mySubscription']['type'] ?? '',
                json['mySubscription']['status'] ?? '', Progress.from(json['mySubscription']['progress']))
            : null;

  final Map<String, dynamic> json;
  final String id, title, description, categoryName, currency;
  final String? categoryId;
  final int totalSessions;
  final double price, pricePerSession, trialPrice;
  final bool trialAvailable, packagesAvailable, trialUsed, chatClosed, pendingConfirmation;
  final Teacher? teacher;
  final MySub? mySub;

  static double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
}

class Subscription {
  Subscription(this.json)
      : id = json['id'] as String,
        courseId = json['courseId'] as String? ?? '',
        type = json['type'] as String? ?? '',
        status = json['status'] as String? ?? '',
        sessionsTotal = (json['sessionsTotal'] ?? 0) as int,
        amount = Course._num(json['amount']),
        courseTitle = (json['course'] as Map?)?['title'] as String? ?? '',
        progress = Progress.from(json['progress']);

  final Map<String, dynamic> json;
  final String id, courseId, type, status, courseTitle;
  final int sessionsTotal;
  final double amount;
  final Progress? progress;

  String get statusLabel => const {
        'AWAITING_PAYMENT': 'بانتظار الدفع',
        'PENDING': 'قيد مراجعة المشرف',
        'ACTIVE': 'فعّال',
        'REJECTED': 'مرفوض',
        'COMPLETED': 'مكتمل',
        'CANCELLED': 'ملغي',
      }[status] ?? status;

  String get typeLabel => const {'TRIAL': 'حصة تجريبية', 'FULL': 'الكورس كامل', 'PACKAGE': 'باقة'}[type] ?? type;
}

class Message {
  Message(this.json)
      : id = json['id'] as String,
        kind = json['kind'] as String? ?? 'TEXT',
        text = json['text'] as String?,
        fileUrl = json['fileUrl'] as String?,
        fileName = json['fileName'] as String?,
        deleted = json['deleted'] == true,
        senderId = (json['sender'] as Map?)?['id'] as String?,
        senderName = (json['sender'] as Map?)?['fullName'] as String?,
        createdAt = DateTime.tryParse(json['createdAt'] ?? '')?.toLocal() ?? DateTime.now();

  final Map<String, dynamic> json;
  final String id, kind;
  final String? text, fileUrl, fileName, senderId, senderName;
  final bool deleted;
  final DateTime createdAt;
}
