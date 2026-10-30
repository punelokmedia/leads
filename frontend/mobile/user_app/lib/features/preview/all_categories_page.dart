import 'package:flutter/material.dart';

import 'category_leads_page.dart';
import 'home_dashboard.dart';
import 'preview_data.dart';

class CategoryPreview extends StatefulWidget {
  final PreviewStore store;
  final ValueChanged<int?> onSelect;
  const CategoryPreview({
    super.key,
    required this.store,
    required this.onSelect,
  });

  @override
  State<CategoryPreview> createState() => _CategoryPreviewState();
}

class _CategoryPreviewState extends State<CategoryPreview> {
  String query = '';

  List<int> get _shown =>
      List<int>.generate(widget.store.categories.length, (index) => index)
          .where(
            (index) => widget.store.categories[index].name
                .toLowerCase()
                .contains(query.toLowerCase()),
          )
          .toList();

  int _leadCount(int category) =>
      widget.store.leads.where((lead) => lead.category == category).length;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF9FBFF),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 14, 5),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: homeNavy),
                ),
                Image.asset(
                  'assets/branding/nextlead_wordmark.webp',
                  width: 150,
                  height: 49,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Categories',
                  style: TextStyle(
                    color: homeNavy,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find leads from various service categories\nand grow your business.',
                  style: TextStyle(
                    color: homeMuted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  style: const TextStyle(color: homeNavy, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'Search categories (e.g. painting, interior, plumbing...)',
                    hintStyle: const TextStyle(color: homeMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: homeNavy),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFDCE6F6)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFDCE6F6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _shown.isEmpty
                ? const Center(
                    child: Text(
                      'No categories found.',
                      style: TextStyle(color: homeMuted),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: _shown.length + (query.isEmpty ? 1 : 0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: .71,
                        ),
                    itemBuilder: (context, index) {
                      if (query.isEmpty && index == 0) {
                        return _allCard();
                      }
                      final itemIndex =
                          _shown[query.isEmpty ? index - 1 : index];
                      return _categoryCard(itemIndex);
                    },
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _allCard() => _card(
    title: 'All Categories',
    count: widget.store.leads.length,
    icon: Icons.home_rounded,
    tint: const Color(0xFFE3F0FF),
    onTap: () {
      widget.onSelect(null);
      Navigator.pop(context);
    },
  );

  Widget _categoryCard(int index) {
    final category = widget.store.categories[index];
    return _card(
      title: category.name,
      count: _leadCount(index),
      icon: category.icon,
      tint: Color.lerp(
        const Color(0xFFE3F0FF),
        const Color(0xFFFFEDE4),
        (index % 5) / 4,
      )!,
      asset: categoryArtwork(category.name),
      onTap: () {
        widget.onSelect(index);
        Navigator.pop(context);
      },
    );
  }

  Widget _card({
    required String title,
    required int count,
    required IconData icon,
    required Color tint,
    required VoidCallback onTap,
    String? asset,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7EDF8)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 68,
              height: 68,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: asset == null
                  ? Icon(icon, color: homeNavy, size: 35)
                  : Image.asset(
                      'assets/Nextlead Mobile  App Asetes/$asset',
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: homeNavy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$count Leads',
                  style: const TextStyle(color: homeMuted, fontSize: 11),
                ),
              ),
              const Icon(Icons.chevron_right, color: homeNavy, size: 19),
            ],
          ),
        ],
      ),
    ),
  );
}
