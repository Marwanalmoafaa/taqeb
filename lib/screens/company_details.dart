import 'package:flutter/material.dart';
import 'package:taqeb/models/company.dart';
import 'package:taqeb/services/database_service.dart';
import 'package:taqeb/utils/constants.dart';
import 'package:taqeb/widgets/common_widgets.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// صفحة عرض تفاصيل المؤسسة
class CompanyDetailsPage extends StatefulWidget {
  final Company company;
  final int index;

  const CompanyDetailsPage({
    super.key,
    required this.company,
    required this.index,
  });

  @override
  State<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  // دالة لنسخ النص عند الضغط المزدوج
  Widget copyableRow(String label, String value) {
    return GestureDetector(
      onDoubleTap: () {
        if (value.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('تم نسخ "$label"')));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.isNotEmpty ? value : '-',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Icon(Icons.copy, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // دالة لتوليد لون عشوائي بناءً على الاسم
  Color _avatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.brown,
    ];
    final hash = name.isNotEmpty ? name.codeUnitAt(0) : 0;
    return colors[hash % colors.length];
  }

  late Company _company;

  @override
  void initState() {
    super.initState();
    _company = widget.company;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: PageTitle(_company.name, icon: Icons.business),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 26),
            tooltip: 'حذف',
            onPressed: () async {
              final confirm = await showConfirmDialog(
                context: context,
                title: 'تأكيد الحذف',
                content: 'هل أنت متأكد من حذف هذه المؤسسة؟',
                confirmText: 'حذف',
                isDanger: true,
              );
              if (confirm == true) {
                await DatabaseService.archiveCompany(_company);
                Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 26),
            tooltip: 'تعديل',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewCompanyPage(
                    companyToEdit: _company,
                    companyIndex: widget.index,
                  ),
                ),
              );

              // إذا تم التعديل بنجاح، نحديث الواجهة
              if (result == true && mounted) {
                setState(() {
                  // سيتم إعادة بناء الواجهة مع البيانات المحدثة
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بيانات صاحب المؤسسة
            _sectionTitle('بيانات صاحب المؤسسة', Icons.person),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    copyableRow('اسم صاحب المؤسسة', _company.name),
                    copyableRow('هوية صاحب المؤسسة', _company.ownerId),
                    copyableRow('رقم الجوال', _company.ownerPhone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // بيانات إضافية للمالك (Absher)
            if (_company.ownerExtra.isNotEmpty) ...[
              _sectionTitle('بيانات دخول المؤسسة', Icons.verified_user),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _company.ownerExtra
                        .map(
                          (e) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              copyableRow(
                                'اسم جهة الدخول',
                                e['provider'] ?? '',
                              ),
                              copyableRow('اسم المستخدم', e['name'] ?? ''),
                              copyableRow('كلمة المرور', e['password'] ?? ''),
                              if (e != _company.ownerExtra.last)
                                const Divider(),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // بيانات المؤسسة
            if (_company.companyData.isNotEmpty) ...[
              _sectionTitle('بيانات المؤسسة', Icons.business),
              ...(_company.companyData.map(
                (e) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        copyableRow('نوع البيان', e['name'] ?? ''),
                        copyableRow('الرقم', e['number'] ?? ''),
                        copyableRow(
                          'تاريخ الانتهاء',
                          e['expiry'] != null
                              ? () {
                                  final expiry = e['expiry'];
                                  if (expiry is DateTime) {
                                    return '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}';
                                  } else {
                                    return expiry.toString().split(' ')[0];
                                  }
                                }()
                              : '',
                        ),
                      ],
                    ),
                  ),
                ),
              )).toList(),
              const SizedBox(height: 24),
            ],

            // مرفقات المؤسسة
            if (_company.companyAttachments.isNotEmpty) ...[
              _sectionTitle('مرفقات المؤسسة', Icons.attach_file),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_file,
                            color: AppColors.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'المرفقات المضافة (${_company.companyAttachments.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // عرض المرفقات في شبكة
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _company.companyAttachments.map((attachment) {
                          return _buildCompanyAttachmentThumbnail(
                            Map<String, dynamic>.from(attachment),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // بيانات العمال
            if (_company.workers.isNotEmpty) ...[
              _sectionTitle('بيانات العمال', Icons.people),
              ...(_company.workers.asMap().entries.map((entry) {
                final worker = entry.value;
                final workerName = worker['name'] ?? '';
                final workerAvatarColor = _avatarColor(workerName);
                final workerFirstLetter = workerName.isNotEmpty
                    ? workerName[0]
                    : '?';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: workerAvatarColor,
                              child: Text(
                                workerFirstLetter,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                workerName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        copyableRow(
                          'رقم الإقامة',
                          worker['iqama']?.toString() ?? '',
                        ),
                        copyableRow(
                          'رقم الجوال',
                          worker['phone']?.toString() ?? '',
                        ),
                        copyableRow(
                          'تاريخ انتهاء الإقامة',
                          worker['expiry'] != null
                              ? () {
                                  final expiry = worker['expiry'];
                                  if (expiry is DateTime) {
                                    return '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}';
                                  } else {
                                    return expiry.toString();
                                  }
                                }()
                              : '',
                        ),

                        // عرض الوثائق الإضافية
                        if (worker['documents'] != null &&
                            (worker['documents'] as List).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.description,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'الوثائق الإضافية',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...(worker['documents'] as List).map((document) {
                            // تحديد لون حالة الوثيقة
                            Color statusColor = Colors.green;
                            if (document['expiryDate'] != null) {
                              final expiryDate = DateTime.parse(
                                document['expiryDate'],
                              );
                              final difference = expiryDate
                                  .difference(DateTime.now())
                                  .inDays;

                              if (difference < 0) {
                                statusColor = Colors.red;
                              } else if (difference <= 30) {
                                statusColor = Colors.orange;
                              }
                            }

                            return GestureDetector(
                              onDoubleTap: () {
                                // نسخ بيانات الوثيقة
                                String copyText = '';
                                if ((document['name'] ?? '').isNotEmpty) {
                                  copyText +=
                                      'اسم الوثيقة: ${document['name']}\n';
                                }
                                if ((document['number'] ?? '').isNotEmpty) {
                                  copyText +=
                                      'رقم الوثيقة: ${document['number']}\n';
                                }
                                if (document['expiryDate'] != null) {
                                  final expiryDate = DateTime.parse(
                                    document['expiryDate'],
                                  );
                                  copyText +=
                                      'تاريخ الانتهاء: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
                                }

                                if (copyText.isNotEmpty) {
                                  Clipboard.setData(
                                    ClipboardData(text: copyText.trim()),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم نسخ بيانات الوثيقة'),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[600]!
                                        : Colors.grey[200]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.description,
                                      color: statusColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onDoubleTap: () {
                                              final docName =
                                                  document['name'] ??
                                                  'وثيقة بدون اسم';
                                              Clipboard.setData(
                                                ClipboardData(text: docName),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'تم نسخ اسم الوثيقة: $docName',
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              document['name'] ??
                                                  'وثيقة بدون اسم',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[100]
                                                    : Colors.grey[800],
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationStyle:
                                                    TextDecorationStyle.dotted,
                                              ),
                                            ),
                                          ),
                                          if ((document['number'] ?? '')
                                              .isNotEmpty)
                                            GestureDetector(
                                              onDoubleTap: () {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: document['number'],
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'تم نسخ رقم الوثيقة: ${document['number']}',
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                'الرقم: ${document['number']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.grey[300]
                                                      : Colors.grey[600],
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationStyle:
                                                      TextDecorationStyle
                                                          .dotted,
                                                ),
                                              ),
                                            ),
                                          if (document['expiryDate'] != null)
                                            GestureDetector(
                                              onDoubleTap: () {
                                                final expiryDate =
                                                    DateTime.parse(
                                                      document['expiryDate'],
                                                    );
                                                final dateText =
                                                    '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
                                                Clipboard.setData(
                                                  ClipboardData(text: dateText),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'تم نسخ تاريخ الانتهاء: $dateText',
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                'ينتهي: ${DateTime.parse(document['expiryDate']).day}/${DateTime.parse(document['expiryDate']).month}/${DateTime.parse(document['expiryDate']).year}',
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationStyle:
                                                      TextDecorationStyle
                                                          .dotted,
                                                ),
                                              ),
                                            ),
                                          if (document['expiryDate'] == null)
                                            Text(
                                              'لا يوجد تاريخ انتهاء',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],

                        // عرض المرفقات
                        if (worker['attachments'] != null &&
                            (worker['attachments'] as List).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_file,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'المرفقات',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // عرض المرفقات في شبكة
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (worker['attachments'] as List).map((
                              attachment,
                            ) {
                              // تحويل البيانات إلى النوع الصحيح
                              final attachmentMap = Map<String, dynamic>.from(
                                attachment,
                              );
                              return _buildAttachmentThumbnail(
                                attachmentMap,
                                entry.key,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              })).toList(),
            ],
          ],
        ),
      ),
    );
  }

  // بناء مصغرة مرفق المؤسسة
  Widget _buildCompanyAttachmentThumbnail(Map<String, dynamic> attachment) {
    final isImage = _isImageFile(attachment['extension'] ?? '');
    final fileName = attachment['name'] ?? 'مرفق';

    return GestureDetector(
      onTap: () => _showCompanyAttachmentOptions(attachment),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[600]!
                : Colors.grey[300]!,
          ),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]
              : Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(attachment['path']),
                  width: 50,
                  height: 35,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      _getFileIcon(attachment['extension'] ?? ''),
                      size: 30,
                      color: AppColors.accent,
                    );
                  },
                ),
              )
            else
              Icon(
                _getFileIcon(attachment['extension'] ?? ''),
                size: 30,
                color: AppColors.accent,
              ),
            const SizedBox(height: 4),
            Text(
              fileName,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[200]
                    : Colors.grey[800],
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // بناء مصغرة المرفق
  Widget _buildAttachmentThumbnail(
    Map<String, dynamic> attachment,
    int workerIndex,
  ) {
    final isImage = _isImageFile(attachment['extension'] ?? '');
    final fileName = attachment['name'] ?? 'مرفق';

    return GestureDetector(
      onTap: () => _showAttachmentOptions(attachment, workerIndex),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(attachment['path']),
                  width: 50,
                  height: 35,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      _getFileIcon(attachment['extension'] ?? ''),
                      size: 30,
                      color: AppColors.primary,
                    );
                  },
                ),
              )
            else
              Icon(
                _getFileIcon(attachment['extension'] ?? ''),
                size: 30,
                color: AppColors.primary,
              ),
            const SizedBox(height: 4),
            Text(
              fileName,
              style: const TextStyle(fontSize: 10),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // عرض خيارات مرفق المؤسسة
  void _showCompanyAttachmentOptions(Map<String, dynamic> attachment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              attachment['name'] ?? 'مرفق',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isImageFile(attachment['extension'] ?? '')) ...[
              ListTile(
                leading: const Icon(Icons.zoom_in),
                title: const Text('عرض الصورة'),
                onTap: () {
                  Navigator.pop(context);
                  _showImageViewer(attachment);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل الاسم'),
              onTap: () {
                Navigator.pop(context);
                _editCompanyAttachmentName(attachment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('مشاركة'),
              onTap: () {
                Navigator.pop(context);
                _shareAttachment(attachment);
              },
            ),
            if (_isImageFile(attachment['extension'] ?? '')) ...[
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('طباعة'),
                onTap: () {
                  Navigator.pop(context);
                  _printAttachment(attachment);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteCompanyAttachment(attachment);
              },
            ),
          ],
        ),
      ),
    );
  }

  // تعديل اسم مرفق المؤسسة
  void _editCompanyAttachmentName(Map<String, dynamic> attachment) {
    final controller = TextEditingController(text: attachment['name'] ?? '');

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل اسم المرفق'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'اسم المرفق',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  // تحديث اسم المرفق مباشرة في بيانات المؤسسة
                  final attachments = _company.companyAttachments;
                  for (int i = 0; i < attachments.length; i++) {
                    if (attachments[i]['path'] == attachment['path']) {
                      attachments[i]['name'] = controller.text.trim();
                      break;
                    }
                  }

                  // حفظ التغييرات
                  await _company.save();

                  setState(() {
                    // تحديث الواجهة
                  });

                  Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تعديل اسم المرفق بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  // حذف مرفق المؤسسة
  void _deleteCompanyAttachment(Map<String, dynamic> attachment) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف "${attachment['name']}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  // حذف الملف من النظام
                  final file = File(attachment['path']);
                  if (await file.exists()) {
                    await file.delete();
                  }

                  // تحديث بيانات المؤسسة
                  final attachments = _company.companyAttachments.toList();
                  attachments.removeWhere(
                    (att) => att['path'] == attachment['path'],
                  );
                  _company.companyAttachments = attachments;

                  // حفظ التغييرات
                  await _company.save();

                  setState(() {
                    // تحديث الواجهة
                  });

                  Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف المرفق بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ أثناء الحذف: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  // فحص إذا كان الملف صورة
  bool _isImageFile(String extension) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    return imageExtensions.contains(extension.toLowerCase());
  }

  // الحصول على أيقونة حسب نوع الملف
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.txt':
        return Icons.text_snippet;
      case '.zip':
      case '.rar':
        return Icons.archive;
      default:
        return Icons.attachment;
    }
  }

  // عرض خيارات المرفق (بدون نسخ إلى سطح المكتب)
  void _showAttachmentOptions(
    Map<String, dynamic> attachment,
    int workerIndex,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              attachment['name'] ?? 'مرفق',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isImageFile(attachment['extension'] ?? '')) ...[
              ListTile(
                leading: const Icon(Icons.zoom_in),
                title: const Text('عرض الصورة'),
                onTap: () {
                  Navigator.pop(context);
                  _showImageViewer(attachment);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل الاسم'),
              onTap: () {
                Navigator.pop(context);
                _editAttachmentName(attachment, workerIndex);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('مشاركة'),
              onTap: () {
                Navigator.pop(context);
                _shareAttachment(attachment);
              },
            ),
            if (_isImageFile(attachment['extension'] ?? '')) ...[
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('طباعة'),
                onTap: () {
                  Navigator.pop(context);
                  _printAttachment(attachment);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteAttachment(attachment, workerIndex);
              },
            ),
          ],
        ),
      ),
    );
  }

  // عرض الصورة بحجمها الكامل
  void _showImageViewer(Map<String, dynamic> attachment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(attachment['name'] ?? 'صورة'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.file(
                    File(attachment['path']),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تعديل اسم المرفق
  void _editAttachmentName(Map<String, dynamic> attachment, int workerIndex) {
    final controller = TextEditingController(text: attachment['name'] ?? '');

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل اسم المرفق'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'اسم المرفق',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  // تحديث اسم المرفق مباشرة في البيانات الحالية
                  final workers = _company.workers;
                  if (workerIndex < workers.length) {
                    final attachments =
                        workers[workerIndex]['attachments'] as List? ?? [];
                    for (int i = 0; i < attachments.length; i++) {
                      if (attachments[i]['path'] == attachment['path']) {
                        attachments[i]['name'] = controller.text.trim();
                        break;
                      }
                    }
                  }

                  // تحديث البيانات في الشركة الحالية
                  _company.workers = workers;

                  // حفظ التغييرات
                  await _company.save();

                  setState(() {
                    // تحديث الواجهة
                  });

                  Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تعديل اسم المرفق بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  // مشاركة المرفق (بدلاً من النسخ إلى سطح المكتب)
  Future<void> _shareAttachment(Map<String, dynamic> attachment) async {
    try {
      final file = File(attachment['path']);
      if (await file.exists()) {
        // نسخ الملف إلى مجلد مؤقت للمشاركة
        final tempDir = await getTemporaryDirectory();
        final fileName = '${attachment['name']}${attachment['extension']}';
        final tempFile = File('${tempDir.path}/$fileName');
        await file.copy(tempFile.path);

        // فتح مستكشف الملفات على المجلد المؤقت
        await Process.run('explorer', ['/select,', tempFile.path]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم فتح مجلد الملف: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الملف غير موجود'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء المشاركة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // طباعة المرفق
  Future<void> _printAttachment(Map<String, dynamic> attachment) async {
    try {
      final file = File(attachment['path']);
      if (await file.exists()) {
        // فتح الملف باستخدام التطبيق الافتراضي للطباعة
        await Process.run('rundll32', [
          'url.dll,FileProtocolHandler',
          file.path,
        ]);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم فتح الملف للطباعة: ${attachment['name']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الملف غير موجود'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الطباعة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // حذف المرفق
  void _deleteAttachment(Map<String, dynamic> attachment, int workerIndex) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف "${attachment['name']}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  // حذف الملف من النظام
                  final file = File(attachment['path']);
                  if (await file.exists()) {
                    await file.delete();
                  }

                  // تحديث بيانات العامل مباشرة
                  final workers = _company.workers;
                  if (workerIndex < workers.length) {
                    final attachments =
                        (workers[workerIndex]['attachments'] as List? ?? [])
                            .where((att) => att['path'] != attachment['path'])
                            .toList();
                    workers[workerIndex]['attachments'] = attachments;
                  }

                  // تحديث البيانات في الشركة الحالية
                  _company.workers = workers;

                  // حفظ التغييرات
                  await _company.save();

                  setState(() {
                    // تحديث الواجهة
                  });

                  Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم حذف المرفق بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ أثناء الحذف: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }
}

// عنوان قسم مع أيقونة
Widget _sectionTitle(String title, IconData icon) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 16),
  child: Row(
    children: [
      Icon(icon, color: AppColors.primary, size: 24),
      const SizedBox(width: 8),
      Text(title, style: AppTextStyles.sectionTitle),
    ],
  ),
);

/// صفحة موحدة لإضافة وتعديل مؤسسة
class NewCompanyPage extends StatefulWidget {
  final Company? companyToEdit;
  final int? companyIndex;

  const NewCompanyPage({super.key, this.companyToEdit, this.companyIndex});

  @override
  State<NewCompanyPage> createState() => _NewCompanyPageState();
}

class _NewCompanyPageState extends State<NewCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ownerIdController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();
  bool _isSaving = false;
  // قوائم البيانات المتعددة
  List<Map<String, String>> _ownerExtra = [];
  List<Map<String, dynamic>> _companyData = [];
  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _companyAttachments = [];

  @override
  void initState() {
    super.initState();
    // إذا كنا في وضع التعديل، نملأ الحقول من بيانات الشركة
    if (widget.companyToEdit != null) {
      final c = widget.companyToEdit!;
      _nameController.text = c.name;
      _ownerIdController.text = c.ownerId;
      _ownerPhoneController.text = c.ownerPhone;
      // deep copy and ensure proper field structure
      _ownerExtra = c.ownerExtra.map((e) {
        final map = Map<String, String>.from(e);
        // Handle old data structure where 'number' was used instead of 'password'
        if (map.containsKey('number') && !map.containsKey('password')) {
          map['password'] = map['number'] ?? '';
          map.remove('number');
        }
        // Ensure all required fields exist
        if (!map.containsKey('provider')) map['provider'] = '';
        if (!map.containsKey('name')) map['name'] = '';
        if (!map.containsKey('password')) map['password'] = '';
        return map;
      }).toList();
      _companyData = c.companyData
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _workers = c.workers.map((e) {
        final worker = Map<String, dynamic>.from(e);
        if (!worker.containsKey('documents')) {
          worker['documents'] = [];
        }
        // إصلاح نوع بيانات المرفقات
        if (worker.containsKey('attachments') &&
            worker['attachments'] != null) {
          worker['attachments'] = (worker['attachments'] as List)
              .map((attachment) => Map<String, dynamic>.from(attachment))
              .toList();
        }
        return worker;
      }).toList();
      _companyAttachments = c.companyAttachments
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.companyToEdit != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: PageTitle(
            isEditing ? 'تعديل مؤسسة' : 'إضافة مؤسسة جديدة',
            icon: isEditing ? Icons.edit : Icons.add_business,
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بيانات صاحب المؤسسة
                _sectionTitle('بيانات صاحب المؤسسة', Icons.person),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CustomTextField(
                          label: 'اسم صاحب المؤسسة',
                          controller: _nameController,
                          prefixIcon: Icons.person,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'هوية صاحب المؤسسة',
                          controller: _ownerIdController,
                          prefixIcon: Icons.credit_card,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'رقم الجوال',
                          controller: _ownerPhoneController,
                          prefixIcon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          isRequired: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // بيانات دخول المؤسسة
                _sectionTitle('بيانات دخول المؤسسة', Icons.verified_user),
                if (_ownerExtra.isNotEmpty) ..._buildOwnerExtraFields(),
                ActionButton(
                  label: 'إضافة بيانات دخول',
                  icon: Icons.add,
                  onPressed: _addOwnerExtraField,
                ),

                const SizedBox(height: 24),

                // بيانات المؤسسة
                _sectionTitle('بيانات المؤسسة', Icons.business),
                if (_companyData.isNotEmpty) ..._buildCompanyDataFields(),
                ActionButton(
                  label: 'إضافة بيانات للمؤسسة',
                  icon: Icons.add,
                  onPressed: _addCompanyDataField,
                ),

                const SizedBox(height: 24),

                // مرفقات المؤسسة
                _sectionTitle('مرفقات المؤسسة', Icons.attach_file),
                if (_companyAttachments.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[600]!
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.attach_file,
                              color: AppColors.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'المرفقات المضافة (${_companyAttachments.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // عرض المرفقات في شبكة صغيرة
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _companyAttachments.map((attachment) {
                            final attachmentMap = Map<String, dynamic>.from(
                              attachment,
                            );
                            final isImage = _isImageFile(
                              attachmentMap['extension'] ?? '',
                            );
                            final fileName = attachmentMap['name'] ?? 'مرفق';

                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[600]!
                                      : Colors.grey[300]!,
                                ),
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[700]
                                    : Colors.grey[100],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isImage)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.file(
                                        File(attachmentMap['path']),
                                        width: 35,
                                        height: 25,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                _getFileIcon(
                                                  attachmentMap['extension'] ??
                                                      '',
                                                ),
                                                size: 20,
                                                color: AppColors.accent,
                                              );
                                            },
                                      ),
                                    )
                                  else
                                    Icon(
                                      _getFileIcon(
                                        attachmentMap['extension'] ?? '',
                                      ),
                                      size: 20,
                                      color: AppColors.accent,
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fileName,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[200]
                                          : Colors.grey[800],
                                    ),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                ActionButton(
                  label: 'إضافة مرفقات للمؤسسة',
                  icon: Icons.attach_file,
                  onPressed: _addCompanyAttachments,
                ),

                const SizedBox(height: 24),

                // بيانات العمال
                _sectionTitle('بيانات العمال', Icons.people),
                if (_workers.isNotEmpty) ..._buildWorkersFields(),
                ActionButton(
                  label: 'إضافة عامل',
                  icon: Icons.person_add,
                  onPressed: _addWorkerField,
                ),

                const SizedBox(height: 32),

                // زر الحفظ
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ActionButton(
                    label: isEditing ? 'حفظ التعديلات' : 'إضافة المؤسسة',
                    icon: isEditing ? Icons.save : Icons.add_business,
                    onPressed: _saveCompany,
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // إنشاء حقول بيانات الدخول الإضافية
  List<Widget> _buildOwnerExtraFields() {
    return _ownerExtra.asMap().entries.map((entry) {
      final index = entry.key;
      final field = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: field['provider'],
                      decoration: const InputDecoration(
                        labelText: 'اسم جهة الدخول',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _ownerExtra[index]['provider'] = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _ownerExtra.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: field['name'],
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _ownerExtra[index]['name'] = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: field['password'],
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _ownerExtra[index]['password'] = value;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addOwnerExtraField() {
    setState(() {
      _ownerExtra.add({'provider': '', 'name': '', 'password': ''});
    });
  }

  // إنشاء حقول بيانات المؤسسة
  List<Widget> _buildCompanyDataFields() {
    return _companyData.asMap().entries.map((entry) {
      final index = entry.key;
      final field = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: field['name'],
                      decoration: const InputDecoration(
                        labelText: 'نوع البيان',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _companyData[index]['name'] = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _companyData.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: field['number'],
                decoration: const InputDecoration(
                  labelText: 'الرقم',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _companyData[index]['number'] = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: field['expiry'] != null
                        ? (field['expiry'] is DateTime
                              ? field['expiry']
                              : DateTime.parse(field['expiry'].toString()))
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _companyData[index]['expiry'] = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(
                        field['expiry'] != null
                            ? () {
                                final expiry = field['expiry'];
                                final date = expiry is DateTime
                                    ? expiry
                                    : DateTime.parse(expiry.toString());
                                return '${date.day}/${date.month}/${date.year}';
                              }()
                            : 'تاريخ الانتهاء (اختياري)',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addCompanyDataField() {
    setState(() {
      _companyData.add({'name': '', 'number': '', 'expiry': null});
    });
  }

  // إنشاء حقول العمال
  List<Widget> _buildWorkersFields() {
    return _workers.asMap().entries.map((entry) {
      final index = entry.key;
      final worker = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'عامل ${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _workers.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: worker['name'],
                decoration: const InputDecoration(
                  labelText: 'اسم العامل',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _workers[index]['name'] = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: worker['iqama']?.toString(),
                decoration: const InputDecoration(
                  labelText: 'رقم الإقامة',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _workers[index]['iqama'] = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: worker['phone']?.toString(),
                decoration: const InputDecoration(
                  labelText: 'رقم الجوال',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  setState(() {
                    _workers[index]['phone'] = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: worker['expiry'] != null
                        ? (worker['expiry'] is DateTime
                              ? worker['expiry']
                              : DateTime.parse(worker['expiry'].toString()))
                        : DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() {
                      _workers[index]['expiry'] = date.toIso8601String();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(
                        worker['expiry'] != null
                            ? () {
                                final expiry = worker['expiry'];
                                final date = expiry is DateTime
                                    ? expiry
                                    : DateTime.parse(expiry.toString());
                                return '${date.day}/${date.month}/${date.year}';
                              }()
                            : 'تاريخ انتهاء الإقامة (اختياري)',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // زر إضافة وثيقة للعامل
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addDocumentToWorker(index),
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  label: const Text(
                    'إضافة وثيقة للعامل',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              // عرض الوثائق المضافة للعامل
              if (worker['documents'] != null &&
                  (worker['documents'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[600]!
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.description,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'الوثائق المضافة (${(worker['documents'] as List).length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...(worker['documents'] as List)
                          .map(
                            (doc) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      doc['name'] ?? 'وثيقة',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[200]
                                            : Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                  if (doc['number'] != null &&
                                      doc['number'].toString().isNotEmpty)
                                    Text(
                                      '(${doc['number']})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                ),
              ],
              // عرض المرفقات المضافة للعامل
              if (worker['attachments'] != null &&
                  (worker['attachments'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[600]!
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_file,
                            color: AppColors.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'المرفقات المضافة (${(worker['attachments'] as List).length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // عرض المرفقات في شبكة صغيرة
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (worker['attachments'] as List).map((
                          attachment,
                        ) {
                          final attachmentMap = Map<String, dynamic>.from(
                            attachment,
                          );
                          final isImage = _isImageFile(
                            attachmentMap['extension'] ?? '',
                          );
                          final fileName = attachmentMap['name'] ?? 'مرفق';

                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[600]!
                                    : Colors.grey[300]!,
                              ),
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[700]
                                  : Colors.grey[100],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isImage)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.file(
                                      File(attachmentMap['path']),
                                      width: 35,
                                      height: 25,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              _getFileIcon(
                                                attachmentMap['extension'] ??
                                                    '',
                                              ),
                                              size: 20,
                                              color: AppColors.accent,
                                            );
                                          },
                                    ),
                                  )
                                else
                                  Icon(
                                    _getFileIcon(
                                      attachmentMap['extension'] ?? '',
                                    ),
                                    size: 20,
                                    color: AppColors.accent,
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  fileName,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[200]
                                        : Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // زر إضافة مرفقات للعامل
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addAttachmentsToWorker(index),
                  icon: const Icon(Icons.attach_file, color: AppColors.accent),
                  label: const Text(
                    'إضافة مرفقات للعامل',
                    style: TextStyle(color: AppColors.accent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // إضافة وثيقة للعامل في نموذج التعديل
  void _addDocumentToWorker(int workerIndex) {
    showDialog(
      context: context,
      builder: (context) => _AddDocumentDialog(
        onAdd: (document) {
          setState(() {
            if (_workers[workerIndex]['documents'] == null) {
              _workers[workerIndex]['documents'] = [];
            }
            (_workers[workerIndex]['documents'] as List).add(document);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة الوثيقة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  // إضافة مرفقات للعامل في نموذج التعديل
  Future<void> _addAttachmentsToWorker(int workerIndex) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowedExtensions: null,
      );

      if (result != null && result.files.isNotEmpty) {
        List<Map<String, dynamic>> newAttachments = [];

        // إنشاء مجلد للعامل إذا لم يكن موجوداً
        final directory = await getApplicationDocumentsDirectory();
        final workerName =
            _workers[workerIndex]['name'] ?? 'عامل_${workerIndex + 1}';
        final companyFolder = Directory(
          '${directory.path}/taqeb/${_nameController.text}',
        );
        final workerFolder = Directory('${companyFolder.path}/$workerName');

        if (!await workerFolder.exists()) {
          await workerFolder.create(recursive: true);
        }

        for (var file in result.files) {
          if (file.path != null) {
            // نسخ الملف إلى مجلد التطبيق
            final originalFile = File(file.path!);
            final fileName = path.basenameWithoutExtension(file.name);
            final fileExtension = path.extension(file.name);
            final newFileName =
                '${DateTime.now().millisecondsSinceEpoch}_$fileName$fileExtension';
            final newFile = File('${workerFolder.path}/$newFileName');

            await originalFile.copy(newFile.path);

            // إضافة معلومات المرفق
            newAttachments.add({
              'name': fileName, // اسم قابل للتعديل بدون الامتداد
              'originalName': file.name,
              'path': newFile.path,
              'size': file.size,
              'extension': fileExtension,
              'uploadedAt': DateTime.now().toIso8601String(),
            });
          }
        }

        if (newAttachments.isNotEmpty) {
          setState(() {
            if (_workers[workerIndex]['attachments'] == null) {
              _workers[workerIndex]['attachments'] = [];
            }
            (_workers[workerIndex]['attachments'] as List).addAll(
              newAttachments,
            );
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم رفع ${newAttachments.length} مرفق بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء رفع الملفات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // إضافة مرفقات للمؤسسة
  Future<void> _addCompanyAttachments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        allowedExtensions: null,
      );

      if (result != null && result.files.isNotEmpty) {
        List<Map<String, dynamic>> newAttachments = [];

        // إنشاء مجلد للمؤسسة إذا لم يكن موجوداً
        final directory = await getApplicationDocumentsDirectory();
        final companyFolder = Directory(
          '${directory.path}/taqeb/${_nameController.text}/company_attachments',
        );

        if (!await companyFolder.exists()) {
          await companyFolder.create(recursive: true);
        }

        for (var file in result.files) {
          if (file.path != null) {
            // نسخ الملف إلى مجلد التطبيق
            final originalFile = File(file.path!);
            final fileName = path.basenameWithoutExtension(file.name);
            final fileExtension = path.extension(file.name);
            final newFileName =
                '${DateTime.now().millisecondsSinceEpoch}_$fileName$fileExtension';
            final newFile = File('${companyFolder.path}/$newFileName');

            await originalFile.copy(newFile.path);

            // إضافة معلومات المرفق
            newAttachments.add({
              'name': fileName, // اسم قابل للتعديل بدون الامتداد
              'originalName': file.name,
              'path': newFile.path,
              'size': file.size,
              'extension': fileExtension,
              'uploadedAt': DateTime.now().toIso8601String(),
            });
          }
        }

        if (newAttachments.isNotEmpty) {
          setState(() {
            _companyAttachments.addAll(newAttachments);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم رفع ${newAttachments.length} مرفق للمؤسسة بنجاح',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء رفع ملفات المؤسسة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addWorkerField() {
    setState(() {
      _workers.add({
        'name': '',
        'iqama': '',
        'phone': '',
        'expiry': null,
        'documents': [],
        'attachments': [],
      });
    });
  }

  void _saveCompany() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.companyToEdit != null) {
        // تعديل شركة موجودة - تحديث البيانات مباشرة
        final existingCompany = widget.companyToEdit!;
        existingCompany.name = _nameController.text.trim();
        existingCompany.ownerId = _ownerIdController.text.trim();
        existingCompany.ownerPhone = _ownerPhoneController.text.trim();
        existingCompany.ownerExtra = _ownerExtra;
        existingCompany.companyData = _companyData;
        existingCompany.workers = _workers;
        existingCompany.companyAttachments = _companyAttachments;

        await DatabaseService.updateCompany(existingCompany);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تعديل المؤسسة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // إضافة شركة جديدة
        final company = Company(
          name: _nameController.text.trim(),
          ownerId: _ownerIdController.text.trim(),
          ownerPhone: _ownerPhoneController.text.trim(),
          ownerExtra: _ownerExtra,
          companyData: _companyData,
          workers: _workers,
          isArchived: false,
          companyAttachments: _companyAttachments,
        );

        await DatabaseService.addCompany(company);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة المؤسسة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // التحقق من نوع الملف إذا كان صورة
  bool _isImageFile(String extension) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(extension.toLowerCase());
  }

  // الحصول على أيقونة الملف حسب نوعه
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }
}

// Dialog لإضافة وثيقة جديدة
class _AddDocumentDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const _AddDocumentDialog({required this.onAdd});

  @override
  State<_AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends State<_AddDocumentDialog> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  DateTime? _expiryDate;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إضافة وثيقة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الوثيقة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'رقم الوثيقة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (date != null) {
                  setState(() {
                    _expiryDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(
                      _expiryDate != null
                          ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                          : 'تاريخ الانتهاء (اختياري)',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                final document = <String, dynamic>{
                  'name': _nameController.text.trim(),
                  'number': _numberController.text.trim(),
                };

                if (_expiryDate != null) {
                  document['expiryDate'] = _expiryDate!.toIso8601String();
                }

                Navigator.pop(context);
                widget.onAdd(document);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
