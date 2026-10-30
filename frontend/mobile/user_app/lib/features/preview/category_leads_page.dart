import 'package:flutter/material.dart';
import 'preview_data.dart';
import 'home_dashboard.dart';

String? categoryArtwork(String name) {
  final value = name.toLowerCase();
  if (value.contains('paint')) return 'Painting.png';
  if (value.contains('civil') || value.contains('construction'))
    return 'Civil Work.png';
  if (value.contains('interior')) return 'interior-design.png';
  if (value.contains('plumb')) return 'Plumbing.png';
  if (value.contains('electric')) return 'Electrical Work.png';
  if (value.contains('cctv')) return 'CCTV Installation.png';
  if (value.contains('waterproof')) return 'Water Proofing.png';
  if (value.contains('aluminium') || value.contains('window'))
    return 'Aluminium & Windows.png';
  if (value.contains('ac service') || value.contains('air condition'))
    return 'AC Service & Repair.png';
  if (value.contains('real estate')) return 'Real State.png';
  if (value.contains('ceiling') || value == 'pop') return 'POP.jpg';
  return null;
}

class CategoryLeadsPage extends StatefulWidget {
  final PreviewStore store;
  final List<PreviewLead> leads;
  final int? category;
  final String city, query, tab;
  final VoidCallback onBack, onSaved, onNotifications, onFilters;
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
    if (selected != null && mounted)
      setState(() => apply(selected.isEmpty ? null : selected));
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
    if (sort != 'Default order')
      leads.sort(
        (a, b) => sort == 'Budget: Low to High'
            ? a.budget.compareTo(b.budget)
            : b.budget.compareTo(a.budget),
      );
    final count = widget.store.leads
        .where(
          (lead) => widget.category == null || lead.category == widget.category,
        )
        .length;
    final art = categoryArtwork(name);
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 6, 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.chevron_left, color: homeNavy),
                ),
                Image.asset(
                  'assets/branding/nextlead_wordmark.webp',
                  width: 133,
                  height: 46,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Saved',
                  onPressed: widget.onSaved,
                  icon: const Icon(Icons.favorite_border, color: homeNavy),
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 67,
                  height: 67,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: art == null
                      ? const Icon(
                          Icons.home_work_outlined,
                          color: homeBlue,
                          size: 34,
                        )
                      : Image.asset(
                          'assets/Nextlead Mobile  App Asetes/$art',
                          fit: BoxFit.contain,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: homeNavy,
                        ),
                      ),
                      Text(
                        '$count Leads Available',
                        style: const TextStyle(fontSize: 14, color: homeMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: widget.query,
                    onChanged: widget.onSearch,
                    style: const TextStyle(fontSize: 13, color: homeNavy),
                    decoration: InputDecoration(
                      hintText: 'Search in $name leads...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: homeMuted,
                      ),
                      prefixIcon: const Icon(Icons.search, color: homeNavy),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Color(0xFFDCE3F2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(color: Color(0xFFDCE3F2)),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Filter leads',
                  onPressed: widget.onFilters,
                  icon: Badge(
                    isLabelVisible:
                        budget != null ||
                        area != null ||
                        timeline != null ||
                        widget.city != 'All Cities',
                    child: const Icon(Icons.tune, color: homeBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
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
                  Icons.square_foot,
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${leads.length} Leads Found',
                    style: const TextStyle(color: homeMuted, fontSize: 12),
                  ),
                ),
                PopupMenuButton<String>(
                  initialValue: sort,
                  onSelected: (value) => setState(() => sort = value),
                  itemBuilder: (_) =>
                      [
                            'Default order',
                            'Budget: Low to High',
                            'Budget: High to Low',
                          ]
                          .map(
                            (item) =>
                                PopupMenuItem(value: item, child: Text(item)),
                          )
                          .toList(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_vert, size: 19, color: homeNavy),
                        Text(
                          sort,
                          style: const TextStyle(color: homeNavy, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: leads.isEmpty
                ? const Center(child: Text('No leads match your filters.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: leads.length,
                    itemBuilder: (_, i) => _card(leads[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    String text,
    IconData icon,
    VoidCallback action, {
    bool active = false,
  }) => Padding(
    padding: const EdgeInsets.only(right: 7),
    child: OutlinedButton.icon(
      onPressed: action,
      icon: Icon(icon, size: 17),
      label: Text(text, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? homeBlue : homeNavy,
        backgroundColor: active ? const Color(0xFFE6F1FF) : Colors.white,
        side: BorderSide(color: active ? homeBlue : const Color(0xFFDCE3F2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
  Widget _card(PreviewLead lead) {
    final category =
        lead.category >= 0 && lead.category < widget.store.categories.length
        ? widget.store.categories[lead.category]
        : null;
    final art = categoryArtwork(category?.name ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 97,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FC),
              borderRadius: BorderRadius.circular(9),
            ),
            child: art == null
                ? Icon(
                    category?.icon ?? Icons.home_work_outlined,
                    color: homeBlue,
                    size: 33,
                  )
                : Image.asset(
                    'assets/Nextlead Mobile  App Asetes/$art',
                    fit: BoxFit.contain,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (lead.propertyType.isNotEmpty)
                      Expanded(
                        child: Text(
                          lead.propertyType,
                          style: const TextStyle(fontSize: 11, color: homeBlue),
                        ),
                      ),
                    IconButton(
                      tooltip: lead.saved ? 'Unsave lead' : 'Save lead',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () => widget.store.toggleSaved(lead),
                      icon: Icon(
                        lead.saved ? Icons.bookmark : Icons.bookmark_border,
                        color: homeNavy,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                Text(
                  lead.title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: homeNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: homeNavy,
                      size: 14,
                    ),
                    Expanded(
                      child: Text(
                        lead.city,
                        style: const TextStyle(fontSize: 11, color: homeMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 9,
                  runSpacing: 4,
                  children: [
                    Text(
                      _budget(lead),
                      style: const TextStyle(color: homeNavy, fontSize: 11),
                    ),
                    if (lead.area.isNotEmpty)
                      Text(
                        lead.area,
                        style: const TextStyle(color: homeMuted, fontSize: 11),
                      ),
                    if (lead.timeline.isNotEmpty)
                      Text(
                        lead.timeline,
                        style: const TextStyle(color: homeMuted, fontSize: 11),
                      ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => widget.onLead(lead),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: homeBlue,
                      side: const BorderSide(color: homeBlue),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'View Lead',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
