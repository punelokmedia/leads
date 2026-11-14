import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../payments/presentation/widgets/wallet_card.dart';
import '../auth/shared/auth_providers.dart';
import 'preview_data.dart';
import 'category_media.dart';
import 'profile_design.dart';

const figmaBlue = Color(0xFF0066FF);
const figmaNavy = Color(0xFF072565);
const figmaInk = Color(0xFF0F172A);
const figmaMuted = Color(0xFF52647C);
const figmaBackground = Color(0xFFF0F5FF);

Widget figmaSvg(String name, {double size = 24, Color? color}) => SizedBox(
  width: size,
  height: size,
  child: SvgPicture.asset(
    'assets/figma/$name.svg',
    fit: BoxFit.contain,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color, BlendMode.srcIn),
  ),
);

class FigmaHeader extends ConsumerWidget {
  final VoidCallback onWallet, onNotifications;
  final bool unread, tagline, live;
  const FigmaHeader({
    super.key,
    required this.onWallet,
    required this.onNotifications,
    this.unread = false,
    this.tagline = false,
    this.live = true,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = live && ref.watch(isLoggedInProvider);
    final balance = signedIn
        ? ref
              .watch(walletProvider)
              .when(
                data: (data) =>
                    '₹ ${((data['balancePaise'] as num? ?? 0) / 100).toStringAsFixed(0)}',
                loading: () => '…',
                error: (_, _) => 'Wallet',
              )
        : 'Wallet';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD2DEF2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/figma/home-imgNextLeadRibbonArrowLogo3.png',
                  width: 130,
                  height: 43.35,
                  fit: BoxFit.cover,
                  semanticLabel: 'NextLead',
                ),
                if (tagline)
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "India's Premium Vendor Network",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: figmaInk,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onWallet,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFAFAFA),
              foregroundColor: figmaInk,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(86, 48),
              shape: const StadiumBorder(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                figmaSvg('home-img1650659670163548215245331', size: 24),
                const SizedBox(width: 6),
                Text(
                  balance,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: onNotifications,
            icon: Badge(
              isLabelVisible: unread,
              child: figmaSvg('home-imgVector', size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class FigmaBottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const FigmaBottomNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) =>
      ProfileBottomNav(selected: selected, onSelect: onSelect);
}

class FigmaLeadCard extends StatelessWidget {
  final PreviewLead lead;
  final PreviewStore store;
  final VoidCallback onTap;
  final bool purchased;
  const FigmaLeadCard({
    super.key,
    required this.lead,
    required this.store,
    required this.onTap,
    this.purchased = false,
  });
  @override
  Widget build(BuildContext context) {
    final category =
        lead.category >= 0 && lead.category < store.categories.length
        ? store.categories[lead.category].name
        : '';
    final posted = lead.postedAt;
    final elapsed = posted == null ? null : DateTime.now().difference(posted);
    final age = elapsed == null || elapsed.isNegative
        ? null
        : elapsed.inDays > 0
        ? '${elapsed.inDays}d ago'
        : elapsed.inHours > 0
        ? '${elapsed.inHours}h ago'
        : elapsed.inMinutes > 0
        ? '${elapsed.inMinutes}m ago'
        : 'Just now';
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      CategoryMedia.getLeadImage(category, leadId: lead.id),
                      width: 88,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
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
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: figmaInk,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            if (age != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      size: 12,
                                      color: Color(0xFFC77900),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      age,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFC77900),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _detail(Icons.location_on_outlined, lead.city),
                            _detail(Icons.home_outlined, lead.propertyType),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F6FF),
                            border: Border.all(color: const Color(0xFFD4E4FF)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            lead.budgetLabel ?? '\u20b9 ${lead.budget}',
                            style: const TextStyle(
                              color: figmaInk,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      purchased
                          ? lead.area
                          : '${lead.availableSlots} Vendor Required | Service',
                      semanticsLabel: purchased
                          ? lead.area
                          : '${lead.availableSlots} of ${lead.maxBuyers} vendor slots available',
                      style: const TextStyle(
                        color: figmaInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: figmaBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      purchased ? 'View Details \u2192' : 'View Lead \u2192',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: figmaMuted),
      const SizedBox(width: 3),
      Flexible(
        child: Text(
          value,
          style: const TextStyle(color: figmaMuted, fontSize: 13),
        ),
      ),
    ],
  );
}
