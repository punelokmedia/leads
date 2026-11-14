import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'business_details_page.dart' show AccountPageHeader, accountText;
import 'profile_design.dart' show profileBackground;
import 'category_media.dart';

import 'preview_data.dart';
import 'home_dashboard.dart';

class SavedLeadsScreen extends StatefulWidget {
  final PreviewStore store;
  final Set<String> savedCategories;
  final VoidCallback onBack, onWallet, onNotifications, onCategoriesChanged;
  final ValueChanged<PreviewLead> onLead;
  final ValueChanged<String> onCategory;
  const SavedLeadsScreen({
    super.key,
    required this.store,
    required this.savedCategories,
    required this.onBack,
    required this.onWallet,
    required this.onNotifications,
    required this.onLead,
    required this.onCategory,
    required this.onCategoriesChanged,
  });
  @override
  State<SavedLeadsScreen> createState() => _SavedLeadsScreenState();
}

class _SavedLeadsScreenState extends State<SavedLeadsScreen> {
  String query = '';
  String? category;
  bool categoryTab = false;

  String _categoryName(PreviewLead lead) =>
      lead.category >= 0 && lead.category < widget.store.categories.length
      ? widget.store.categories[lead.category].name
      : '';

  Future<void> _manageCategories() async {
    final selected = Set<String>.of(widget.savedCategories);
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Saved categories',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: widget.store.categories
                        .map(
                          (item) => CheckboxListTile(
                            title: Text(item.name),
                            value: selected.contains(item.name),
                            activeColor: homeBlue,
                            onChanged: (value) => update(() {
                              if (value == true) {
                                selected.add(item.name);
                              } else {
                                selected.remove(item.name);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save categories'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      widget.savedCategories
        ..clear()
        ..addAll(selected);
      widget.onCategoriesChanged();
      setState(() {});
    }
  }

  Future<void> _filters() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('All categories'),
              onTap: () => Navigator.pop(context, ''),
            ),
            ...widget.store.categories.map(
              (item) => ListTile(
                title: Text(item.name),
                onTap: () => Navigator.pop(context, item.name),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => category = selected.isEmpty ? null : selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = query.toLowerCase();
    final saved = widget.store.leads.where((lead) => lead.saved).toList();
    final visible = saved
        .where(
          (lead) =>
              (category == null || _categoryName(lead) == category) &&
              '${lead.title} ${lead.city} ${_categoryName(lead)}'
                  .toLowerCase()
                  .contains(search),
        )
        .toList();
    final names = widget.savedCategories
        .where((name) => name.toLowerCase().contains(search))
        .toList();
    final count = categoryTab ? names.length : visible.length;
    return ColoredBox(
      color: profileBackground,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  AccountPageHeader(
                    store: widget.store,
                    onBack: widget.onBack,
                    onWallet: widget.onWallet,
                    onNotifications: widget.onNotifications,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 27, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Saved',
                          style: accountText(
                            24,
                            color: homeNavy,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your saved leads and categories, all in one place.',
                          style: accountText(
                            14,
                            color: const Color(0xFF9498A1),
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Row(
                              children: [
                                _tab('Leads (${saved.length})', false),
                                _tab(
                                  'Categories (${widget.savedCategories.length})',
                                  true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) =>
                                    setState(() => query = value),
                                style: accountText(14),
                                decoration: InputDecoration(
                                  hintText: categoryTab
                                      ? 'Search saved categories'
                                      : 'Search saved leads',
                                  hintStyle: accountText(
                                    14,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF94A3B8),
                                    size: 22,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton.filledTonal(
                                tooltip: 'Filter saved leads',
                                onPressed: _filters,
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                                icon: SvgPicture.asset(
                                  'assets/figma/saved-filter.svg',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (category != null && !categoryTab)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: InputChip(
                              label: Text(category!),
                              onDeleted: () => setState(() => category = null),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DecoratedSliver(
              decoration: BoxDecoration(
                color: const Color(0xFF072565),
                borderRadius: BorderRadius.circular(24),
              ),
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 20, 21, 18),
                sliver: count == 0
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            categoryTab
                                ? 'No saved categories found.'
                                : 'No saved leads found.',
                            style: accountText(14, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : SliverList.separated(
                        itemCount: count,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => categoryTab
                            ? Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                child: ListTile(
                                  leading: SvgPicture.asset(
                                    'assets/figma/saved-categories.svg',
                                    width: 24,
                                    height: 24,
                                  ),
                                  title: Text(
                                    names[index],
                                    style: accountText(
                                      14,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  onTap: () => widget.onCategory(names[index]),
                                  trailing: IconButton(
                                    tooltip: 'Remove category',
                                    onPressed: () =>
                                        _removeCategory(names[index]),
                                    icon: const Icon(
                                      Icons.close,
                                      color: homeBlue,
                                    ),
                                  ),
                                ),
                              )
                            : _card(visible[index]),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 21, 24),
                child: Material(
                  color: const Color(0xFFFFE57E),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: homeBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SizedBox(
                              width: 42,
                              height: 44,
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/figma/saved-categories.svg',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Saved categories',
                                      style: accountText(
                                        16,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _manageCategories,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 30),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Manage ›',
                                      style: accountText(
                                        13,
                                        color: homeBlue,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Quick access to your saved service categories.',
                                style: accountText(13, color: homeMuted),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: widget.savedCategories
                                    .map(
                                      (name) => InputChip(
                                        label: Text(name),
                                        onPressed: () =>
                                            widget.onCategory(name),
                                        onDeleted: () => _removeCategory(name),
                                        labelStyle: accountText(
                                          12,
                                          weight: FontWeight.w600,
                                        ),
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Color(0xFFBFDBFE),
                                        ),
                                        shape: const StadiumBorder(),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: homeBlue,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeCategory(String name) {
    widget.savedCategories.remove(name);
    widget.onCategoriesChanged();
    setState(() {});
  }

  Widget _tab(String label, bool categories) => Expanded(
    child: Material(
      color: categoryTab == categories ? homeBlue : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => categoryTab = categories),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 46),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: accountText(
                14,
                color: categoryTab == categories
                    ? Colors.white
                    : const Color(0xFF475569),
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _card(PreviewLead lead) {
    final name = _categoryName(lead), lower = _categoryName(lead).toLowerCase();
    final image = lower.contains('interior')
        ? 'assets/figma/saved-interior.png'
        : lower.contains('paint')
        ? 'assets/figma/saved-painting.png'
        : CategoryMedia.getLeadImage(name, leadId: lead.id);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    image,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    cacheWidth: (96 * MediaQuery.devicePixelRatioOf(context))
                        .ceil(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              lead.title,
                              style: accountText(
                                16,
                                color: const Color(0xFF0F172A),
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 24,
                            height: 28,
                            child: IconButton(
                              tooltip: 'Remove saved lead',
                              padding: EdgeInsets.zero,
                              onPressed: () => setState(
                                () => widget.store.toggleSaved(lead),
                              ),
                              icon: SvgPicture.asset(
                                'assets/figma/saved-bookmark.svg',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 80),
                            child: Text(
                              name,
                              style: accountText(13, color: homeMuted),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '· ',
                                style: accountText(13, color: homeMuted),
                              ),
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 3),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 95),
                                child: Text(
                                  lead.city,
                                  style: accountText(13, color: homeMuted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, bounds) {
                final budget = DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUDGET',
                          style: accountText(
                            10,
                            color: homeMuted,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lead.budgetLabel ??
                              (lead.budget > 0
                                  ? '₹${lead.budget}'
                                  : 'Not specified'),
                          style: accountText(
                            14,
                            color: const Color(0xFF0F172A),
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                final button = FilledButton(
                  onPressed: () => widget.onLead(lead),
                  style: FilledButton.styleFrom(
                    backgroundColor: homeBlue,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    minimumSize: const Size(114, 40),
                    textStyle: accountText(
                      13,
                      color: Colors.white,
                      weight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('View Lead'),
                );
                return MediaQuery.textScalerOf(context).scale(13) > 16 ||
                        bounds.maxWidth < 280
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [budget, const SizedBox(height: 8), button],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: budget),
                          const SizedBox(width: 12),
                          button,
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
