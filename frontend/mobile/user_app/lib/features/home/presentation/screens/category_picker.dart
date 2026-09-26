import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/features/home/infra/category_controller.dart';
import 'package:user_app/features/home/shared/home_providers.dart';

Future<void> showCategoryPicker(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => const _CategoryPicker(),
  );
}

class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(homeCategoryListProvider);
    final selected = ref.watch(homeControllerProvider).selectedCategoryId ?? '';
    void select(String id) {
      ref.read(homeControllerProvider.notifier).loadLeads(categoryId: id);
      Navigator.of(context).pop();
    }

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select category'),
            ),
            ListTile(
              title: const Text('All Categories'),
              selected: selected.isEmpty,
              onTap: () => select(''),
            ),
            Expanded(
              child: categories.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(homeCategoryListProvider),
                    child: const Text('Could not load categories. Retry'),
                  ),
                ),
                data: (items) => items.isEmpty
                    ? const Center(child: Text('No categories available'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) => ListTile(
                          title: Text(items[i].title),
                          selected: selected == items[i].id,
                          trailing: selected == items[i].id
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => select(items[i].id),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
