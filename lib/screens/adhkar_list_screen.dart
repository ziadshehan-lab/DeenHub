import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../data/repositories/adhkar_repository.dart';
import '../models/dhikr.dart';
import '../widgets/dhikr_card.dart';

/// وسيطات شاشة أذكار تصنيف.
class AdhkarListArgs {
  const AdhkarListArgs({required this.categoryId, this.categoryTitle});

  final String categoryId;
  final String? categoryTitle;
}

/// شاشة أذكار تصنيف محدد: بطاقات الأذكار بنصها وتكرارها وإسنادها.
class AdhkarListScreen extends StatefulWidget {
  const AdhkarListScreen({super.key, this.args});

  final AdhkarListArgs? args;

  @override
  State<AdhkarListScreen> createState() => _AdhkarListScreenState();
}

class _AdhkarListScreenState extends State<AdhkarListScreen> {
  late Future<List<DhikrModel>> _adhkarFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _adhkarFuture = context
        .read<AdhkarRepository>()
        .getAdhkar(widget.args?.categoryId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args?.categoryTitle ?? AppStrings.adhkar),
      ),
      body: FutureBuilder<List<DhikrModel>>(
        future: _adhkarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(AppStrings.loadError),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(_load),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            );
          }
          final adhkar = snapshot.data!;
          if (adhkar.isEmpty) {
            return const Center(child: Text(AppStrings.noContentYet));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: adhkar.length,
            itemBuilder: (context, index) =>
                DhikrCard(dhikr: adhkar[index]),
          );
        },
      ),
    );
  }
}
