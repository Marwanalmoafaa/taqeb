import 'package:hive/hive.dart';

/// نموذج الوثيقة الإضافية للعامل
class Document {
  String name;
  String number;
  DateTime expiryDate;
  DateTime createdAt;

  Document({
    required this.name,
    required this.number,
    required this.expiryDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'number': number,
      'expiryDate': expiryDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static Document fromMap(Map<String, dynamic> map) => Document(
    name: map['name'] ?? '',
    number: map['number'] ?? '',
    expiryDate: map['expiryDate'] != null
        ? DateTime.parse(map['expiryDate'])
        : DateTime.now(),
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : DateTime.now(),
  );

  // للتحقق من قرب انتهاء الوثيقة (خلال 30 يوم)
  bool get isExpiringSoon {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    return difference.inDays <= 30 && difference.inDays >= 0;
  }

  // للتحقق من انتهاء الوثيقة
  bool get isExpired {
    return DateTime.now().isAfter(expiryDate);
  }
}

/// نموذج الحسابات
class AccountModel extends HiveObject {
  String name;
  double totalDue;
  double totalPaid;
  DateTime dueDate;
  List<Map<String, dynamic>> items;
  DateTime lastModified; // تاريخ آخر تعديل
  List<Document> documents; // الوثائق الإضافية

  AccountModel({
    required this.name,
    required this.totalDue,
    required this.totalPaid,
    required this.dueDate,
    this.items = const [],
    DateTime? lastModified,
    this.documents = const [],
  }) : lastModified = lastModified ?? DateTime.now();

  double get remaining => totalDue - totalPaid;

  // الحصول على الوثائق المنتهية
  List<Document> get expiredDocuments =>
      documents.where((doc) => doc.isExpired).toList();

  // الحصول على الوثائق القريبة من الانتهاء
  List<Document> get expiringSoonDocuments =>
      documents.where((doc) => doc.isExpiringSoon).toList();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'totalDue': totalDue,
      'totalPaid': totalPaid,
      'dueDate': dueDate.toIso8601String(),
      'items': items,
      'lastModified': lastModified.toIso8601String(),
      'documents': documents.map((doc) => doc.toMap()).toList(),
    };
  }

  static AccountModel fromMap(Map<String, dynamic> map) => AccountModel(
    name: map['name'] ?? '',
    totalDue: (map['totalDue'] ?? 0).toDouble(),
    totalPaid: (map['totalPaid'] ?? 0).toDouble(),
    dueDate: map['dueDate'] != null
        ? DateTime.parse(map['dueDate'])
        : DateTime.now(),
    items: List<Map<String, dynamic>>.from(
      (map['items'] ?? []).map((e) => Map<String, dynamic>.from(e)),
    ),
    lastModified: map['lastModified'] != null
        ? DateTime.parse(map['lastModified'])
        : DateTime.now(),
    documents: map['documents'] != null
        ? List<Document>.from(
            (map['documents'] as List).map((doc) => Document.fromMap(doc)),
          )
        : [],
  );
}

class AccountAdapter extends TypeAdapter<AccountModel> {
  @override
  final int typeId = 2;

  @override
  AccountModel read(BinaryReader reader) {
    try {
      final name = reader.readString();
      final totalDue = reader.readDouble();
      final totalPaid = reader.readDouble();
      final dueDate = DateTime.parse(reader.readString());
      final items = reader
          .readList()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // محاولة قراءة lastModified، إذا لم تكن موجودة نستخدم التاريخ الحالي
      DateTime lastModified;
      try {
        lastModified = DateTime.parse(reader.readString());
      } catch (e) {
        lastModified = DateTime.now();
      }

      // محاولة قراءة الوثائق، إذا لم تكن موجودة نستخدم قائمة فارغة
      List<Document> documents = [];
      try {
        final docsData = reader.readList();
        documents = docsData
            .map(
              (doc) => Document.fromMap(Map<String, dynamic>.from(doc as Map)),
            )
            .toList();
      } catch (e) {
        documents = [];
      }

      return AccountModel(
        name: name,
        totalDue: totalDue,
        totalPaid: totalPaid,
        dueDate: dueDate,
        items: items,
        lastModified: lastModified,
        documents: documents,
      );
    } catch (e) {
      // في حالة البيانات القديمة، نستخدم القيم الافتراضية
      return AccountModel(
        name: '',
        totalDue: 0.0,
        totalPaid: 0.0,
        dueDate: DateTime.now(),
        items: [],
        lastModified: DateTime.now(),
        documents: [],
      );
    }
  }

  @override
  void write(BinaryWriter writer, AccountModel obj) {
    writer.writeString(obj.name);
    writer.writeDouble(obj.totalDue);
    writer.writeDouble(obj.totalPaid);
    writer.writeString(obj.dueDate.toIso8601String());
    writer.writeList(obj.items);
    writer.writeString(obj.lastModified.toIso8601String());
    writer.writeList(obj.documents.map((doc) => doc.toMap()).toList());
  }
}
