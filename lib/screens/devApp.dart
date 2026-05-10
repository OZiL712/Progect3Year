import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // ستحتاج إضافة مكتبة font_awesome_flutter في pubspec.yaml

class DevApp extends StatelessWidget {
  const DevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فريق التطوير'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.code, size: 80, color: Colors.blue),
            const SizedBox(height: 10),
            const Text(
              'تم تطوير هذا التطبيق بواسطة:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // قائمة المطورين
            _buildDevCard(
              name: 'رهيب اليوسفي',
              role: 'Lead Flutter Developer',
              icon: FontAwesomeIcons.codeBranch,
            ),
            _buildDevCard(
              name: 'عمرو الشرافي',
              role: 'UI/UX Designer & Developer',
              icon: FontAwesomeIcons.palette,
            ),
            _buildDevCard(
              name: 'عبدالسلام الأهدل',
              role: 'Backend & Firebase Specialist',
              icon: FontAwesomeIcons.database,
            ),
            
            const SizedBox(height: 40),
            const Text(
              '© 2026 Bareed+ App Team',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevCard({required String name, required String role, required IconData icon}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: FaIcon(icon, color: Colors.blue),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(role),
        trailing: Wrap(
          spacing: 12,
          children: [
            IconButton(
              icon: FaIcon(FontAwesomeIcons.github, size: 20, color: Colors.black87),
              onPressed: () { /* أضف رابط جيت هب هنا */ },
            ),
            IconButton(
              icon: FaIcon(FontAwesomeIcons.linkedin, size: 20, color: Colors.blueAccent),
              onPressed: () { /* أضف رابط لينكد إن هنا */ },
            ),
          ],
        ),
      ),
    );
  }
}