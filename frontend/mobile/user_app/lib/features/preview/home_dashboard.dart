import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../payments/presentation/widgets/wallet_card.dart';
import 'preview_data.dart';
import 'category_media.dart';

// ── Brand color tokens (new scheme) ──────────────────────────────────────────
const homeBlue = Color(0xFF0047FF); // was 0xFF0066FF  →  Primary Blue
const homeNavy = Color(0xFF0A2342); // was 0xFF07143D  →  Primary Navy
const homeMuted = Color(0xFF475569); // was 0xFF7886A5  →  Secondary Slate

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    bottom: false,
    child: RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          // ── Row 1: Logo | Wallet | Bell ──────────────────────────────
          Row(
            children: [
              Image.asset(
                'assets/branding/nextlead_wordmark.webp',
                width: 133,
                height: 47,
              ),
              const Spacer(),
              // Wallet balance chip
              Consumer(
                builder: (context, ref, _) {
                  final wallet = ref.watch(walletProvider);
                  final balanceText = wallet.when(
                    data: (data) {
                      final paise = data['balancePaise'] as num? ?? 0;
                      final rupees = (paise / 100).toStringAsFixed(0);
                      return '₹ $rupees';
                    },
                    loading: () => '...',
                    error: (_, _) => 'Wallet',
                  );
                  return OutlinedButton.icon(
                    onPressed: onWallet,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: homeBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: homeBlue,
                    ),
                    label: Text(
                      balanceText,
                      style: const TextStyle(
                        color: homeNavy,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 2),
              // Saved button beside wallet
              IconButton(
                tooltip: 'Saved leads',
                onPressed: onSaved,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.favorite_border_rounded,
                  color: homeNavy,
                  size: 22,
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: onNotifications,
                visualDensity: VisualDensity.compact,
                icon: Badge(
                  isLabelVisible: store.unread,
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: homeNavy,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          // ── Row 2: Location (aligned to far left) ──────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onFilters,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.location_on, size: 16, color: homeBlue),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    city,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: homeNavy,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: homeNavy,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onSearch,
                  style: const TextStyle(color: homeNavy, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search leads by service, location or keyword...',
                    hintStyle: const TextStyle(color: homeMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: homeMuted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(color: Color(0xFFD7DEEC)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  tooltip: 'Filter leads',
                  onPressed: onFilters,
                  icon: const Icon(Icons.tune, color: homeBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _category(
                  'All Categories',
                  Icons.home_rounded,
                  category == null,
                  () => onCategory(null),
                ),
                ...List.generate(
                  store.categories.length,
                  (i) => _category(
                    store.categories[i].name,
                    store.categories[i].icon,
                    category == i,
                    () => onCategory(i),
                  ),
                ),
                _category('More', Icons.grid_view_rounded, false, onCategories),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Home banner: new full-width image ──────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AspectRatio(
              aspectRatio: 2027 / 776, // matches the image's native ratio
              child: Image.asset(
                'assets/branding/home_banner.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Latest Leads',
                  style: TextStyle(
                    fontSize: 21,
                    color: homeNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onExplore,
                child: const Row(
                  children: [
                    Text('View All', style: TextStyle(color: homeBlue)),
                    Icon(Icons.chevron_right, color: homeBlue),
                  ],
                ),
              ),
            ],
          ),
          if (leads.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No leads match your filters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: homeMuted),
              ),
            ),
          ...leads.take(10).map((lead) => _leadCard(lead)),
        ],
      ),
    ),
  );

  Widget _category(
    String label,
    IconData icon,
    bool selected,
    VoidCallback action,
  ) => SizedBox(
    width: 70,
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 50,
              width: 56,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFDCE6F7)
                    : Colors.white, // was 0xFFE0EEFF → surfaceLight
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFB3CCEF) // was 0xFFBFDAFF
                      : const Color(0xFFEDF1F7),
                ),
              ),
              child: Icon(
                icon,
                color: selected ? homeBlue : homeNavy,
                size: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                color: selected ? homeBlue : homeMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _leadCard(PreviewLead lead) {
    final categoryName =
        lead.category >= 0 && lead.category < store.categories.length
            ? store.categories[lead.category].name
            : '';
    final leadImage = CategoryMedia.getLeadImage(categoryName, leadId: lead.id);
    final icon = lead.category >= 0 && lead.category < store.categories.length
        ? store.categories[lead.category].icon
        : Icons.home_work_outlined;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080A3A77),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 72,
              height: 92,
              color: const Color(0xFFDCE6F7),
              child: Image.asset(
                leadImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(icon, size: 36, color: homeBlue),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.title,
                  style: const TextStyle(
                    color: homeNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: homeBlue,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lead.city,
                        style: const TextStyle(color: homeMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10,
                  children: [
                    if (lead.propertyType.isNotEmpty)
                      Text(
                        lead.propertyType,
                        style: const TextStyle(color: homeMuted, fontSize: 10),
                      ),
                    if (lead.area.isNotEmpty)
                      Text(
                        lead.area,
                        style: const TextStyle(color: homeMuted, fontSize: 10),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  lead.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF536079),
                    fontSize: 11,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => onLead(lead),
                    style: FilledButton.styleFrom(
                      backgroundColor: homeBlue,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      shape: const StadiumBorder(),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Lead', style: TextStyle(fontSize: 11)),
                        SizedBox(width: 7),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
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
