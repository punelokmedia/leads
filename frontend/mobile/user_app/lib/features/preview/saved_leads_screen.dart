import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../payments/presentation/widgets/wallet_card.dart';
import 'preview_data.dart';
import 'home_dashboard.dart';

class SavedLeadsScreen extends ConsumerStatefulWidget {
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
  ConsumerState<SavedLeadsScreen> createState() => _SavedLeadsScreenState();
}

class _SavedLeadsScreenState extends ConsumerState<SavedLeadsScreen> {
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
    final saved = widget.store.leads.where((lead) => lead.saved).toList();
    final visible = saved
        .where(
          (lead) =>
              (category == null || _categoryName(lead) == category) &&
              '${lead.title} ${lead.city} ${_categoryName(lead)}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    final names = widget.savedCategories
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: homeNavy),
              ),
              Image.asset(
                'assets/branding/nextlead_wordmark.webp',
                width: 132,
                height: 47,
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: widget.onWallet,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  side: const BorderSide(color: Color(0xFFDDE7F6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 19,
                      color: homeBlue,
                    ),
                    const SizedBox(width: 5),
                    if (widget.store.isLive)
                      ref
                          .watch(walletProvider)
                          .when(
                            data: (data) => Text(
                              '\u20b9${((data['balancePaise'] as num? ?? 0) / 100).toStringAsFixed(0)}',
                              style: const TextStyle(color: homeNavy),
                            ),
                            loading: () => const Text('...'),
                            error: (_, _) => const Text('Wallet'),
                          )
                    else
                      const Text('Wallet'),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 17,
                      color: homeNavy,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: widget.onNotifications,
                icon: Badge(
                  isLabelVisible: widget.store.unread,
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: homeNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Saved',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              color: homeNavy,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Your saved leads and categories, all in one place.',
            style: TextStyle(fontSize: 14, color: homeMuted),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FE),
              border: Border.all(color: const Color(0xFFDCE6F8)),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                _tab(
                  'Leads (${saved.length})',
                  !categoryTab,
                  () => setState(() => categoryTab = false),
                ),
                _tab(
                  'Categories (${widget.savedCategories.length})',
                  categoryTab,
                  () => setState(() => categoryTab = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    hintText: categoryTab
                        ? 'Search saved categories'
                        : 'Search saved leads',
                    hintStyle: const TextStyle(fontSize: 14, color: homeMuted),
                    prefixIcon: const Icon(Icons.search, color: homeMuted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(color: Color(0xFFDCE6F8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(color: Color(0xFFDCE6F8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Filter saved leads',
                onPressed: _filters,
                style: IconButton.styleFrom(backgroundColor: Colors.white),
                icon: const Icon(Icons.tune, color: homeBlue),
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
          const SizedBox(height: 12),
          if (!categoryTab) ...[
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'No saved leads found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: homeMuted),
                ),
              ),
            ...visible.map(_card),
          ] else ...[
            if (names.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No saved categories found.',
                  textAlign: TextAlign.center,
                ),
              ),
            ...names.map(
              (name) => Card(
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(
                    Icons.grid_view_outlined,
                    color: homeBlue,
                  ),
                  title: Text(name),
                  onTap: () => widget.onCategory(name),
                  trailing: IconButton(
                    tooltip: 'Remove category',
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeCategory(name),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFDEECFF),
                  child: Icon(Icons.grid_view_rounded, color: homeBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Saved categories',
                              style: TextStyle(
                                fontSize: 16,
                                color: homeNavy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _manageCategories,
                            child: const Text('Manage ›'),
                          ),
                        ],
                      ),
                      const Text(
                        'Quick access to your saved service categories.',
                        style: TextStyle(fontSize: 12, color: homeMuted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: widget.savedCategories
                            .map(
                              (name) => InputChip(
                                label: Text(
                                  name,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: const Color(0xFFE0EDFF),
                                onPressed: () => widget.onCategory(name),
                                onDeleted: () => _removeCategory(name),
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
        ],
      ),
    );
  }

  void _removeCategory(String name) {
    widget.savedCategories.remove(name);
    widget.onCategoriesChanged();
    setState(() {});
  }

  Widget _tab(String label, bool active, VoidCallback action) => Expanded(
    child: InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? homeBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF485D87),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    ),
  );

  Widget _card(PreviewLead lead) {
    final name = _categoryName(lead);
    final icon =
        lead.category >= 0 && lead.category < widget.store.categories.length
        ? widget.store.categories[lead.category].icon
        : Icons.home_work_outlined;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDF2FA)),
        boxShadow: const [BoxShadow(color: Color(0x060A3A77), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 86,
            height: 102,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: homeBlue, size: 37),
          ),
          const SizedBox(width: 12),
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
                        style: const TextStyle(
                          color: homeNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 26,
                      height: 29,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: 'Remove saved lead',
                        onPressed: () => widget.store.toggleSaved(lead),
                        icon: const Icon(Icons.bookmark, color: homeBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '$name · ${lead.city}',
                  style: const TextStyle(color: homeMuted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, size) {
                    final budget = Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F6FF),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Budget',
                            style: TextStyle(color: homeMuted, fontSize: 11),
                          ),
                          Text(
                            lead.budgetLabel ??
                                (lead.budget > 0
                                    ? '\u20b9${lead.budget}'
                                    : 'Not specified'),
                            style: const TextStyle(
                              color: homeNavy,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                    final button = OutlinedButton(
                      onPressed: () => widget.onLead(lead),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: homeBlue,
                        side: const BorderSide(color: homeBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'View Lead',
                        style: TextStyle(fontSize: 12),
                      ),
                    );
                    return size.maxWidth < 250
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [budget, button],
                          )
                        : Row(
                            children: [
                              Expanded(child: budget),
                              const SizedBox(width: 8),
                              button,
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
