import 'package:hive/hive.dart';

/// نموذج المعاملات
class TransactionModel extends HiveObject {
  String content;
  bool isDone;
  DateTime createdAt;

  TransactionModel({
    required this.content,
    this.isDone = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static TransactionModel fromMap(Map<String, dynamic> map) => TransactionModel(
    content: map['content'] ?? '',
    isDone: map['isDone'] ?? false,
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : DateTime.now(),
  );
}

class TransactionAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 1;

  @override
  TransactionModel read(BinaryReader reader) {
    return TransactionModel(
      content: reader.readString(),
      isDone: reader.readBool(),
      createdAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer.writeString(obj.content);
    writer.writeBool(obj.isDone);
    writer.writeString(obj.createdAt.toIso8601String());
  }
}
