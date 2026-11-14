import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'preview_data.dart';
import 'figma_widgets.dart';
import '../home/presentation/widgets/home_banner_carousel.dart';

const homeBlue = figmaBlue;
const homeNavy = figmaInk;
const homeMuted = figmaMuted;

class NextLeadDashboard extends ConsumerWidget {
  final PreviewStore store;
  final List<PreviewLead> leads;
  final String city;
  final int? category;
  final ValueChanged<String> onSearch;
  final ValueChanged<int?> onCategory;
  final VoidCallback onFilters,
      onCategories,
      onNotifications,
      onExplore,
      onWallet,
      onSaved;
  final ValueChanged<PreviewLead> onLead;
  final VoidCallback? onMembership;
  const NextLeadDashboard({
    super.key,
    required this.store,
    required this.leads,
    required this.city,
    required this.category,
    required this.onSearch,
    required this.onCategory,
    required this.onFilters,
    required this.onCategories,
    required this.onNotifications,
    required this.onExplore,
    required this.onLead,
    required this.onWallet,
    required this.onSaved,
    this.onMembership,
  });

  int? _categoryIndex(String keyword) {
    final index = store.categories.indexWhere(
      (c) => c.name.toLowerCase().contains(keyword),
    );
    return index < 0 ? null : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    bottom: false,
    child: RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(homeBannersProvider);
        await store.refresh();
      },
      child: ListView.builder(
        key: const ValueKey('home-leads-scroll'),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: leads.length + 1,
        itemBuilder: (context, index) {
          if (index > 0) {
            final lead = leads[index - 1];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FigmaLeadCard(
                lead: lead,
                store: store,
                onTap: () => onLead(lead),
              ),
            );
          }
          return Column(
            children: [
              FigmaHeader(
                onWallet: onWallet,
                onNotifications: onNotifications,
                unread: store.unread,
                tagline: true,
                live: store.isLive,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: onFilters,
                      style: TextButton.styleFrom(
                        foregroundColor: homeNavy,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                      ),
                      icon: figmaSvg('home-imgSvg', size: 16),
                      label: Text(
                        '$city ⌄',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: onSearch,
                            style: const TextStyle(
                              fontSize: 16,
                              color: homeNavy,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search services or location',
                              hintStyle: const TextStyle(
                                color: Color(0xFF52647C),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 26,
                                color: Color(0xFF52647C),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: 'Filter leads',
                          onPressed: onFilters,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 52,
                            height: 56,
                          ),
                          icon: figmaSvg('home-imgSvg1', size: 36),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _category(
                          'AC Repair',
                          'home-imgLayer1',
                          _categoryIndex('ac service'),
                        ),
                        _category(
                          'Interiors',
                          'home-imgGroup15',
                          _categoryIndex('interior'),
                        ),
                        _category(
                          'Painting',
                          'home-imgVector3',
                          _categoryIndex('paint'),
                        ),
                        _category(
                          'Plumbing',
                          'home-imgVector5',
                          _categoryIndex('plumb'),
                        ),
                        _category('More', 'home-imgVector4', null, more: true),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 24, color: Color(0xFFD2DEF2)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    HomeBannerCarousel(
                      onTap: (target) => target == 'membership'
                          ? onMembership?.call()
                          : onExplore(),
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Latest Leads',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: homeNavy,
                              letterSpacing: -.5,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onExplore,
                          child: const Text(
                            'View All →',
                            style: TextStyle(color: homeBlue, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    if (leads.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No leads match your filters.',
                          style: TextStyle(color: homeMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _category(
    String label,
    String asset,
    int? index, {
    bool more = false,
  }) => Flexible(
    child: InkWell(
      onTap: more ? onCategories : () => onCategory(index),
      borderRadius: BorderRadius.circular(11),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 66,
            decoration: BoxDecoration(
              color: more ? const Color(0xFF0153FD) : Colors.white,
              borderRadius: BorderRadius.circular(11),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: figmaSvg(asset, size: label == 'AC Repair' ? 43 : 30),
            ),
          ),
          const SizedBox(height: 7),
          Text(label, style: const TextStyle(color: homeNavy, fontSize: 14)),
        ],
      ),
    ),
  );
}
