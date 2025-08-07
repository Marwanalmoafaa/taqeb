import 'package:hive/hive.dart';

/// نموذج الشركة
class Company extends HiveObject {
  String name;
  String ownerId;
  String ownerPhone;
  List<Map<String, String>> ownerExtra;
  List<Map<String, dynamic>> companyData;
  List<Map<String, dynamic>> workers;
  bool isArchived;
  List<Map<String, dynamic>> companyAttachments;

  Company({
    required this.name,
    required this.ownerId,
    required this.ownerPhone,
    required this.ownerExtra,
    required this.companyData,
    required this.workers,
    this.isArchived = false,
    List<Map<String, dynamic>>? companyAttachments,
  }) : companyAttachments = companyAttachments ?? [];

  Map<String, dynamic> toMap() => {
    'name': name,
    'ownerId': ownerId,
    'ownerPhone': ownerPhone,
    'ownerExtra': ownerExtra,
    'companyData': companyData,
    'workers': workers,
    'isArchived': isArchived,
    'companyAttachments': companyAttachments,
  };

  static Company fromMap(Map<String, dynamic> map) => Company(
    name: map['name'] ?? '',
    ownerId: map['ownerId'] ?? '',
    ownerPhone: map['ownerPhone'] ?? '',
    ownerExtra: List<Map<String, String>>.from(
      (map['ownerExtra'] ?? []).map((e) => Map<String, String>.from(e)),
    ),
    companyData: List<Map<String, dynamic>>.from(
      (map['companyData'] ?? []).map((e) => Map<String, dynamic>.from(e)),
    ),
    workers: List<Map<String, dynamic>>.from(
      (map['workers'] ?? []).map((e) => Map<String, dynamic>.from(e)),
    ),
    isArchived: map['isArchived'] ?? false,
    companyAttachments: List<Map<String, dynamic>>.from(
      (map['companyAttachments'] ?? []).map(
        (e) => Map<String, dynamic>.from(e),
      ),
    ),
  );
}

class CompanyAdapter extends TypeAdapter<Company> {
  @override
  final int typeId = 0;

  @override
  Company read(BinaryReader reader) {
    try {
      final name = reader.readString();
      final ownerId = reader.readString();
      final ownerPhone = reader.readString();
      final ownerExtra = reader
          .readList()
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
      final companyData = reader
          .readList()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final workers = reader
          .readList()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final isArchived = reader.readBool();

      // قراءة مرفقات المؤسسة مع التعامل مع البيانات القديمة
      List<Map<String, dynamic>> companyAttachments = [];
      try {
        companyAttachments = reader
            .readList()
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (e) {
        // إذا لم تكن البيانات تحتوي على مرفقات المؤسسة، نترك القائمة فارغة
        companyAttachments = [];
      }

      return Company(
        name: name,
        ownerId: ownerId,
        ownerPhone: ownerPhone,
        ownerExtra: ownerExtra,
        companyData: companyData,
        workers: workers,
        isArchived: isArchived,
        companyAttachments: companyAttachments,
      );
    } catch (e) {
      // في حالة وجود خطأ، نرجع شركة افتراضية
      return Company(
        name: 'خطأ في القراءة',
        ownerId: '',
        ownerPhone: '',
        ownerExtra: [],
        companyData: [],
        workers: [],
        isArchived: false,
        companyAttachments: [],
      );
    }
  }

  @override
  void write(BinaryWriter writer, Company obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.ownerId);
    writer.writeString(obj.ownerPhone);
    writer.writeList(obj.ownerExtra);
    writer.writeList(obj.companyData);
    writer.writeList(obj.workers);
    writer.writeBool(obj.isArchived);
    writer.writeList(obj.companyAttachments);
  }
}
