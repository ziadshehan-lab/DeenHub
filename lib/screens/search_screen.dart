import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../widgets/placeholder_content.dart';

/// شاشة البحث الموحد: ستبحث في القرآن والحديث والأذكار والمكتبة
/// عبر المستودعات.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.search)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: AppStrings.search,
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const Expanded(
            child: PlaceholderContent(icon: Icons.search),
          ),
        ],
      ),
    );
  }
}
