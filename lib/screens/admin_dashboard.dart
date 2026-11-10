
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../services/auth_service.dart';

const List<String> noticeCategories = [
  'General',
  'Examinations',
  'Events',
  'Holidays',
  'Results',
  'Announcements',
];

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Notice'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddNoticePage(),
            ),
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Manage your college announcements',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Published Notices',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('notices')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No notices published yet'),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();

                      final hasAttachment =
                          (data['imageUrl'] ?? '').toString().isNotEmpty ||
                              (data['pdfUrl'] ?? '').toString().isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.campaign),
                          ),
                          title: Text(
                            data['title'] ?? 'Untitled Notice',
                          ),
                          subtitle: Text(
                            '${data['category'] ?? 'General'}'
                                '${hasAttachment ? '\nAttachment added' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddNoticePage(
                                      noticeId: doc.id,
                                      existingData: data,
                                    ),
                                  ),
                                );
                              }

                              if (value == 'delete') {
                                deleteNotice(context, doc.id);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteNotice(
      BuildContext context,
      String noticeId,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notice?'),
        content: const Text(
          'Are you sure you want to delete this notice?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('notices')
            .doc(noticeId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notice deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }
}

// ADD / EDIT NOTICE PAGE

class AddNoticePage extends StatefulWidget {
  final String? noticeId;
  final Map<String, dynamic>? existingData;

  const AddNoticePage({
    super.key,
    this.noticeId,
    this.existingData,
  });

  @override
  State<AddNoticePage> createState() => _AddNoticePageState();
}

class _AddNoticePageState extends State<AddNoticePage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String category = 'General';

  bool loading = false;

  Uint8List? selectedImageBytes;
  String? selectedImageName;

  Uint8List? selectedPdfBytes;
  String? selectedPdfName;

  String? existingImageUrl;
  String? existingPdfUrl;

  bool get isEditing => widget.noticeId != null;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final data = widget.existingData;

    if (data != null) {
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';

      existingImageUrl = data['imageUrl'];
      existingPdfUrl = data['pdfUrl'];

      if (noticeCategories.contains(data['category'])) {
        category = data['category'];
      }
    }
  }

  // SELECT IMAGE FROM GALLERY

  Future<void> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImageBytes = bytes;
        selectedImageName = image.name;
      });
    } catch (e) {
      showMessage('Image selection failed: $e');
    }
  }

  // SELECT PDF FROM PHONE FILES

  Future<void> pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        showMessage('Unable to read selected PDF.');
        return;
      }

      if (!mounted) return;

      setState(() {
        selectedPdfBytes = file.bytes;
        selectedPdfName = file.name;
      });
    } catch (e) {
      showMessage('PDF selection failed: $e');
    }
  }

  // UPLOAD IMAGE TO SUPABASE

  Future<String> uploadImage() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please login again.');
    }

    final extension = selectedImageName!
        .split('.')
        .last
        .toLowerCase();

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_image.$extension';

    final path = '${user.uid}/$fileName';

    await Supabase.instance.client.storage
        .from('notice-attachments')
        .uploadBinary(
      path,
      selectedImageBytes!,
      fileOptions: FileOptions(
        contentType: extension == 'png'
            ? 'image/png'
            : extension == 'webp'
            ? 'image/webp'
            : 'image/jpeg',
      ),
    );

    return Supabase.instance.client.storage
        .from('notice-attachments')
        .getPublicUrl(path);
  }

  // UPLOAD PDF TO SUPABASE

  Future<String> uploadPdf() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please login again.');
    }

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_notice.pdf';

    final path = '${user.uid}/$fileName';

    await Supabase.instance.client.storage
        .from('notice-attachments')
        .uploadBinary(
      path,
      selectedPdfBytes!,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
      ),
    );

    return Supabase.instance.client.storage
        .from('notice-attachments')
        .getPublicUrl(path);
  }

  // SAVE NOTICE

  Future<void> saveNotice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      String imageUrl = existingImageUrl ?? '';
      String pdfUrl = existingPdfUrl ?? '';

      if (selectedImageBytes != null) {
        imageUrl = await uploadImage();
      }

      if (selectedPdfBytes != null) {
        pdfUrl = await uploadPdf();
      }

      final collection =
      FirebaseFirestore.instance.collection('notices');

      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': category,
        'imageUrl': imageUrl,
        'pdfUrl': pdfUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await collection.doc(widget.noticeId).update(data);
      } else {
        await collection.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      showMessage(
        isEditing ? 'Notice updated!' : 'Notice published!',
      );

      Navigator.pop(context);
    } catch (e) {
      showMessage('Upload or publish failed: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Notice' : 'Add New Notice'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Notice Title',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Enter notice title'
                    : null,
              ),

              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: noticeCategories.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => category = value);
                  }
                },
              ),

              const SizedBox(height: 18),

              TextFormField(
                controller: _descriptionController,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Notice Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Enter notice description'
                    : null,
              ),

              const SizedBox(height: 25),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // IMAGE PICKER BUTTON

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Choose Image from Gallery'),
                ),
              ),

              if (selectedImageBytes != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    selectedImageBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                Text(selectedImageName ?? 'Selected image'),
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                    setState(() {
                      selectedImageBytes = null;
                      selectedImageName = null;
                    });
                  },
                  child: const Text('Remove selected image'),
                ),
              ] else if (existingImageUrl != null &&
                  existingImageUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('An image is already attached.'),
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                    setState(() {
                      existingImageUrl = '';
                    });
                  },
                  child: const Text('Remove existing image'),
                ),
              ],

              const SizedBox(height: 18),

              // PDF PICKER BUTTON

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : pickPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Choose PDF from Phone'),
                ),
              ),

              if (selectedPdfBytes != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedPdfName ?? 'Selected PDF',
                      ),
                    ),
                    IconButton(
                      onPressed: loading
                          ? null
                          : () {
                        setState(() {
                          selectedPdfBytes = null;
                          selectedPdfName = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ] else if (existingPdfUrl != null &&
                  existingPdfUrl!.isNotEmpty) ...[
                const Text('A PDF is already attached.'),
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                    setState(() {
                      existingPdfUrl = '';
                    });
                  },
                  child: const Text('Remove existing PDF'),
                ),
              ],

              const SizedBox(height: 12),

              const Text(
                'Selected files will be uploaded when you publish the notice.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : saveNotice,
                  icon: loading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.publish),
                  label: Text(
                    loading
                        ? 'Uploading... Please wait'
                        : isEditing
                        ? 'UPDATE NOTICE'
                        : 'PUBLISH NOTICE',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
