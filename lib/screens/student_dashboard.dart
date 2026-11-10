
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';

const List<String> noticeCategories = [
  'General',
  'Examinations',
  'Events',
  'Holidays',
  'Results',
  'Announcements',
];

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('College Notice Board'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.indigo],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, Student! 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Welcome to your College Notice Board',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                dashboardCard(
                  context,
                  Icons.campaign,
                  'Latest Notices',
                  Colors.blue,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NoticesPage(),
                      ),
                    );
                  },
                ),

                dashboardCard(
                  context,
                  Icons.event,
                  'College Events',
                  Colors.orange,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NoticesPage(
                          category: 'Events',
                        ),
                      ),
                    );
                  },
                ),

                dashboardCard(
                  context,
                  Icons.category,
                  'Categories',
                  Colors.green,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoriesPage(),
                      ),
                    );
                  },
                ),

                dashboardCard(
                  context,
                  Icons.person,
                  'My Profile',
                  Colors.purple,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'Latest Notices',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const NoticesList(),
          ],
        ),
      ),
    );
  }

  Widget dashboardCard(
      BuildContext context,
      IconData icon,
      String title,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// LATEST NOTICES LIST

class NoticesList extends StatelessWidget {
  const NoticesList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Center(
                child: Text('No notices available yet.'),
              ),
            ),
          );
        }

        return Column(
          children: docs.take(5).map((doc) {
            final data = doc.data();

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(
                  Icons.notifications,
                  color: Colors.blue,
                ),
                title: Text(data['title'] ?? 'Untitled Notice'),
                subtitle: Text(data['category'] ?? 'General'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoticeDetailPage(data: data),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// NOTICES AND EVENTS PAGE

class NoticesPage extends StatelessWidget {
  final String? category;

  const NoticesPage({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query =
    FirebaseFirestore.instance.collection('notices');

    if (category != null) {
      query = query.where(
        'category',
        isEqualTo: category,
      );
    } else {
      query = query.orderBy(
        'createdAt',
        descending: true,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: Text(
          category == 'Events'
              ? 'College Events'
              : category ?? 'Latest Notices',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  'Unable to load notices.\n\n'
                      'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category == 'Events'
                        ? Icons.event_busy
                        : Icons.notifications_off,
                    size: 65,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category == 'Events'
                        ? 'No college events available yet.'
                        : 'No notices available.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: category == 'Events'
                        ? Colors.orange.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      category == 'Events'
                          ? Icons.event
                          : Icons.campaign,
                      color: category == 'Events'
                          ? Colors.orange
                          : Colors.blue,
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'Untitled Notice',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '${data['category'] ?? 'General'}\n'
                          '${data['description'] ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoticeDetailPage(data: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// NOTICE DETAILS PAGE WITH IMAGE AND PDF

class NoticeDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const NoticeDetailPage({
    super.key,
    required this.data,
  });

  Future<void> openPdf(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PDF link.'),
        ),
      );
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open PDF link.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title =
        data['title'] ?? 'Untitled Notice';

    final String category =
        data['category'] ?? 'General';

    final String description =
        data['description'] ?? 'No description available.';

    final String imageUrl =
    (data['imageUrl'] ?? '').toString().trim();

    final String pdfUrl =
    (data['pdfUrl'] ?? '').toString().trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('Notice Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Chip(
                  avatar: const Icon(
                    Icons.category,
                    size: 18,
                  ),
                  label: Text(category),
                ),

                const Divider(height: 30),

                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  description,
                  style: const TextStyle(fontSize: 17),
                ),

                // NOTICE IMAGE

                if (imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 25),

                  const Text(
                    'Notice Image',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      loadingBuilder: (
                          context,
                          child,
                          loadingProgress,
                          ) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return const SizedBox(
                          height: 180,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (
                          context,
                          error,
                          stackTrace,
                          ) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          color: Colors.grey.shade200,
                          child: const Column(
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 45,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text('Image could not be loaded.'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // PDF OPEN BUTTON

                if (pdfUrl.isNotEmpty) ...[
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        openPdf(context, pdfUrl);
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Open PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// CATEGORIES PAGE

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'General':
        return Icons.info_outline;
      case 'Examinations':
        return Icons.school;
      case 'Events':
        return Icons.event;
      case 'Holidays':
        return Icons.beach_access;
      case 'Results':
        return Icons.assessment;
      case 'Announcements':
        return Icons.campaign;
      default:
        return Icons.folder;
    }
  }

  Color getCategoryColor(String category) {
    switch (category) {
      case 'General':
        return Colors.blue;
      case 'Examinations':
        return Colors.red;
      case 'Events':
        return Colors.orange;
      case 'Holidays':
        return Colors.green;
      case 'Results':
        return Colors.purple;
      case 'Announcements':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('Notice Categories'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: noticeCategories.length,
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        itemBuilder: (context, index) {
          final category = noticeCategories[index];
          final color = getCategoryColor(category);

          return InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoticesPage(category: category),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(
                      getCategoryIcon(category),
                      color: color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// STUDENT PROFILE PAGE

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: user == null
          ? const Center(
        child: Text('Please login again.'),
      )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load profile: ${snapshot.error}',
              ),
            );
          }

          final data = snapshot.data?.data() ?? {};

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  child: Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 20),
                profileItem(
                  'Name',
                  data['name'] ?? 'Student',
                ),
                profileItem(
                  'Email',
                  user.email ?? '',
                ),
                profileItem(
                  'Roll Number',
                  data['rollNumber'] ?? '',
                ),
                profileItem(
                  'Role',
                  data['role'] ?? 'student',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget profileItem(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
        leading: const Icon(Icons.info_outline),
      ),
    );
  }
}
