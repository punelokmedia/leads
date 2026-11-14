import 'package:flutter/material.dart';
import 'preview_data.dart';
import 'home_dashboard.dart';
import 'business_details_page.dart' show AccountPageHeader, accountText;
import 'profile_design.dart' show profileBackground;
import 'category_media.dart';

String? categoryArtwork(String name) {
  final value = name.toLowerCase();
  if (value.contains('paint')) return 'Painting.png';
  if (value.contains('civil') || value.contains('construction')) {
    return 'Civil Work.png';
  }
  if (value.contains('interior')) return 'interior-design.png';
  if (value.contains('plumb')) return 'Plumbing.png';
  if (value.contains('electric')) return 'Electrical Work.png';
  if (value.contains('cctv')) return 'CCTV Installation.png';
  if (value.contains('waterproof')) return 'Water Proofing.png';
  if (value.contains('aluminium') || value.contains('window')) {
    return 'Aluminium & Windows.png';
  }
  if (value.contains('ac service') || value.contains('air condition')) {
    return 'AC Service & Repair.png';
  }
  if (value.contains('real estate')) return 'Real State.png';
  if (value.contains('ceiling') || value == 'pop') return 'POP.jpg';
  return null;
}

class CategoryLeadsPage extends StatefulWidget {
  final PreviewStore store;
  final List<PreviewLead> leads;
  final int? category;
  final String city, query, tab;
  final VoidCallback onBack, onSaved, onNotifications, onFilters, onWallet;
  final ValueChanged<String> onSearch, onTab;
  final ValueChanged<PreviewLead> onLead;
  const CategoryLeadsPage({
    super.key,
    required this.store,
    required this.leads,
    required this.category,
    required this.city,
    required this.query,
    required this.tab,
    required this.onBack,
    required this.onWallet,
    required this.onSaved,
    required this.onNotifications,
    required this.onFilters,
    required this.onSearch,
    required this.onTab,
    required this.onLead,
  });
  @override
  State<CategoryLeadsPage> createState() => _CategoryLeadsPageState();
}

class _CategoryLeadsPageState extends State<CategoryLeadsPage> {
  String? budget, area, timeline;
  String sort = 'Default order';
  String get name =>
      widget.category != null &&
          widget.category! >= 0 &&
          widget.category! < widget.store.categories.length
      ? widget.store.categories[widget.category!].name
      : 'All Leads';
  String _budget(PreviewLead lead) =>
      lead.budgetLabel ??
      (lead.budget > 0 ? '\u20b9 ${lead.budget}' : 'Not specified');

  Future<void> _pick(
    String title,
    List<String> choices,
    ValueChanged<String?> apply,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text('All $title'),
              onTap: () => Navigator.pop(context, ''),
            ),
            ...choices
                .toSet()
                .where((item) => item.isNotEmpty)
                .map(
                  (item) => ListTile(
                    title: Text(item),
                    onTap: () => Navigator.pop(context, item),
                  ),
                ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => apply(selected.isEmpty ? null : selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final leads = widget.leads
        .where(
          (lead) =>
              (budget == null || _budget(lead) == budget) &&
              (area == null || lead.area == area) &&
              (timeline == null || lead.timeline == timeline),
        )
        .toList();
    final order = {
      for (var i = 0; i < widget.leads.length; i++) widget.leads[i]: i,
    };
    final images = {
      for (var i = 0; i < widget.store.leads.length; i++)
        widget.store.leads[i].id: i % 5,
    };
    leads.sort((a, b) {
      if (a.closed != b.closed) return a.closed ? 1 : -1;
      final result = sort == 'Default order'
          ? 0
          : sort == 'Budget: Low to High'
          ? a.budget.compareTo(b.budget)
          : b.budget.compareTo(a.budget);
      return result != 0 ? result : order[a]!.compareTo(order[b]!);
    });
    final count = widget.store.leads
        .where(
          (lead) => widget.category == null || lead.category == widget.category,
        )
        .length;
    return ColoredBox(
      color: profileBackground,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountPageHeader(
                    store: widget.store,
                    showBack: false,
                    onBack: widget.onBack,
                    onWallet: widget.onWallet,
                    onNotifications: widget.onNotifications,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 5, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: accountText(
                            24,
                            color: const Color(0xFF0F172A),
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count Leads Available',
                          style: accountText(
                            14,
                            color: homeMuted,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Material(
                      color: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0x40000000),
                      borderRadius: BorderRadius.circular(24),
                      child: TextFormField(
                        initialValue: widget.query,
                        onChanged: widget.onSearch,
                        style: accountText(13),
                        decoration: InputDecoration(
                          hintText:
                              'Search in $name leads (e.g. house, wall, exterior...)',
                          hintStyle: accountText(
                            11,
                            color: const Color(0xFF94A3B8),
                            weight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 18,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFFDCE3F2),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFFDCE3F2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height:
                        32 +
                        (MediaQuery.textScalerOf(context).scale(12) - 12).clamp(
                          0,
                          20,
                        ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _chip(
                          widget.tab,
                          Icons.filter_alt_outlined,
                          () => _pick('statuses', [
                            'All',
                            'New',
                            'Joined',
                            'Closed',
                          ], (value) => widget.onTab(value ?? 'All')),
                          active: true,
                        ),
                        _chip(
                          widget.city,
                          Icons.location_on_outlined,
                          widget.onFilters,
                        ),
                        _chip(
                          budget ?? 'Budget',
                          Icons.currency_rupee,
                          () => _pick(
                            'budgets',
                            widget.leads.map(_budget).toList(),
                            (value) => budget = value,
                          ),
                        ),
                        _chip(
                          area ?? 'Area (sq ft)',
                          Icons.open_in_full,
                          () => _pick(
                            'areas',
                            widget.leads.map((lead) => lead.area).toList(),
                            (value) => area = value,
                          ),
                        ),
                        _chip(
                          timeline ?? 'Timeline',
                          Icons.calendar_month_outlined,
                          () => _pick(
                            'timelines',
                            widget.leads.map((lead) => lead.timeline).toList(),
                            (value) => timeline = value,
                          ),
                        ),
                        _chip('Saved', Icons.bookmark_border, widget.onSaved),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 20, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${leads.length} Leads Found',
                            style: accountText(13, color: homeMuted),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Sort leads',
                          initialValue: sort,
                          onSelected: (value) => setState(() => sort = value),
                          itemBuilder: (_) =>
                              [
                                    'Default order',
                                    'Budget: Low to High',
                                    'Budget: High to Low',
                                  ]
                                  .map(
                                    (value) => PopupMenuItem(
                                      value: value,
                                      child: Text(
                                        value == 'Default order'
                                            ? 'Latest First'
                                            : value,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.swap_vert,
                                  size: 16,
                                  color: Color(0xFF1E293B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  sort == 'Default order'
                                      ? 'Latest First'
                                      : sort,
                                  style: accountText(
                                    13,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(2, 0, 1, 0),
              sliver: DecoratedSliver(
                decoration: BoxDecoration(
                  color: const Color(0xFF072565),
                  borderRadius: BorderRadius.circular(24),
                ),
                sliver: SliverPadding(
                  padding: const EdgeInsets.fromLTRB(26.5, 25, 26.5, 20),
                  sliver: leads.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No leads match your filters.',
                              style: accountText(14, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : SliverList.separated(
                          itemCount: leads.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) =>
                              _card(leads[index], images[leads[index].id] ?? 0),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    String text,
    IconData icon,
    VoidCallback action, {
    bool active = false,
  }) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: OutlinedButton.icon(
      onPressed: action,
      icon: Icon(icon, size: 14),
      label: Text(
        text,
        style: accountText(
          12,
          color: active ? homeBlue : const Color(0xFF334155),
          weight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? homeBlue : const Color(0xFF64748B),
        backgroundColor: active ? const Color(0xFFE6F1FF) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        side: BorderSide(color: active ? homeBlue : const Color(0xFFE2E8F0)),
      ),
    ),
  );

  String _posted(PreviewLead lead) {
    if (lead.postedAt == null) return '';
    final age = DateTime.now().difference(lead.postedAt!);
    return age.inDays > 0
        ? 'Posted ${age.inDays} day${age.inDays == 1 ? '' : 's'} ago'
        : age.inHours > 0
        ? 'Posted ${age.inHours} hours ago'
        : 'Posted just now';
  }

  Widget _card(PreviewLead lead, int index) {
    final image = name.toLowerCase().contains('paint')
        ? 'assets/figma/painting-lead-$index.png'
        : CategoryMedia.getLeadImage(name, leadId: lead.id);
    final posted = _posted(lead);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.asset(
                    image,
                    width: 96,
                    height: 96,
                    fit: BoxFit.cover,
                    cacheWidth: (96 * MediaQuery.devicePixelRatioOf(context))
                        .ceil(),
                  ),
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xAA292524),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
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
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              child: Text(
                                lead.propertyType,
                                style: accountText(
                                  10,
                                  color: homeBlue,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: IconButton(
                          tooltip: lead.saved ? 'Unsave lead' : 'Save lead',
                          padding: EdgeInsets.zero,
                          onPressed: () =>
                              setState(() => widget.store.toggleSaved(lead)),
                          icon: Icon(
                            lead.saved ? Icons.bookmark : Icons.bookmark_border,
                            size: 16,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lead.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: accountText(
                      14,
                      color: const Color(0xFF0F172A),
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      children: [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        TextSpan(
                          text:
                              ' ${lead.city}${posted.isEmpty ? '' : ' | ◷ $posted'}',
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: accountText(10, color: const Color(0xFF7B8DA8)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 7),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _budget(lead),
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: [
                            if (lead.area.isNotEmpty) lead.area,
                            if (lead.timeline.isNotEmpty) lead.timeline,
                          ].map((value) => '  |  $value').join(),
                        ),
                      ],
                    ),
                    style: accountText(
                      11,
                      color: const Color(0xFF475569),
                      weight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => widget.onLead(lead),
                      style: FilledButton.styleFrom(
                        backgroundColor: homeBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(95, 26),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const StadiumBorder(),
                        textStyle: accountText(
                          11,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('View Lead'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
