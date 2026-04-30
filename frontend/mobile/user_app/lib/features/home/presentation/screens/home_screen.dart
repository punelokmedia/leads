import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart';
import 'package:user_app/features/home/domain/leads_model.dart';
import 'package:user_app/features/home/presentation/screens/select_city_screen.dart';
import 'package:user_app/features/home/presentation/widgets/home_search_bar.dart';
import 'package:user_app/features/home/presentation/widgets/state_widgets.dart';
import 'package:user_app/features/home/shared/city_provider.dart';
import 'package:user_app/features/home/shared/home_providers.dart'
    hide cartCountProvider, isInCartProvider;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).loadLeads();
      ref.read(cartControllerProvider.notifier);
    });
  }

  void _onCartTap() => context.push(AppRouter.cartPath);

  void _onAddToCart(LeadModel lead) async {
    final message = await ref
        .read(cartControllerProvider.notifier)
        .addLeadToCart(lead);
    if (message != null && mounted) {
      final lower = message.toLowerCase();
      final isError =
          lower.contains('already') ||
          lower.contains('failed') ||
          lower.contains('sold') ||
          lower.contains('max') ||
          lower.contains('not') ||
          lower.contains('error');
      if (isError) {
        SnackbarHelper.showError(context, message);
      } else {
        SnackbarHelper.showSuccess(context, message);
        ref.read(homeControllerProvider.notifier).loadLeads();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: EdgeInsets.fromLTRB(0.w, 20.h, 0.w, 0.h),
        child: Column(
          children: [
            Material(
              color: Colors.white,
              elevation: 0.5,
              shadowColor: Colors.black12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NextLeadsAppBar(cartCount: cartCount, onCartTap: _onCartTap),
                  Padding(
                    padding: EdgeInsets.fromLTRB(6.w, 8.h, 0.w, 0.h),
                    child: const HomeSearchBar(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _HeroBanner()),
                  const SliverToBoxAdapter(child: _FilterRow()),
                  const SliverToBoxAdapter(child: _TopCategories()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0.h, 16.w, 0.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Top Leads",
                            style: AppTextStyles.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey77,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.go(AppRouter.leadsPath);
                            },
                            child: Text(
                              'View All',
                              style: AppTextStyles.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.purple72,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _HomeLeadSliver(onAddToCart: _onAddToCart),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextLeadsAppBar extends StatelessWidget {
  final int cartCount;
  final VoidCallback onCartTap;

  const _NextLeadsAppBar({required this.cartCount, required this.onCartTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: Row(
        children: [
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: AppColors.black19,
              size: 24.r,
            ),
            onPressed: () {},
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 32.h,
                child: Image.asset(
                  'assets/Icons/appIcon/nextLeads_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'NextLeads',
                style: AppTextStyles.poppins(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.production_quantity_limits_rounded,
                  color: AppColors.black,
                  size: 26.r,
                ),
                onPressed: () {},
              ),
              if (cartCount > 0)
                Positioned(
                  right: 8.w,
                  top: 8.h,
                  child: Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: const BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartCount',
                      style: AppTextStyles.poppins(
                        fontSize: 9.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 4.w),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 4.h, 12.w, 12.h),
      height: 138.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B0E7A), Color(0xFF5B34C9)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20.w,
            top: -20.h,
            child: Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 20.w,
            bottom: -30.h,
            child: Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          Positioned(right: 16.w, bottom: 16.h, child: _ChartIllustration()),

          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'High Quality Leads',
                  style: AppTextStyles.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'High Value Projects',
                  style: AppTextStyles.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      color: Colors.white70,
                      size: 14.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Only 2 Vendors per Lead',
                      style: AppTextStyles.poppins(
                        fontSize: 11.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 30.h, right: 4.w),
          child: Icon(
            Icons.trending_up_rounded,
            color: Colors.white,
            size: 32.r,
          ),
        ),
        // Bars
        _Bar(height: 28.h, color: Colors.amber),
        SizedBox(width: 4.w),
        _Bar(height: 44.h, color: Colors.orange),
        SizedBox(width: 4.w),
        _Bar(height: 60.h, color: Color(0xFFFF3E6C)),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final Color color;
  const _Bar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14.w,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCity = ref.watch(selectedCityProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              icon: Icons.location_on_rounded,
              label: selectedCity?.displayName ?? 'All Cities',
              isActive: selectedCity != null,
              onTap: () async {
                await showCityPickerSheet(context);
                // After closing, trigger a lead reload with the new city
                ref.read(homeControllerProvider.notifier).loadLeads();
              },
            ),
          ),
          SizedBox(width: 12.w),

          // ── Category filter chip (unchanged) ──────────────
          Expanded(
            child: _FilterChip(
              icon: Icons.grid_view_rounded,
              label: 'All Categories',
              isActive: false,
              onTap: () {
                // TODO: open category picker
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Whether a non-default selection is active (drives accent colour)
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44.h,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.purple72.withValues(alpha: 0.07)
              : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive ? AppColors.purple72 : Colors.grey.shade200,
            width: isActive ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 10.w),
            Icon(
              icon,
              color: isActive ? AppColors.purple72 : AppColors.purple86,
              size: 16.r,
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.poppins(
                  fontSize: 10.sp,
                  color: isActive ? AppColors.purple72 : AppColors.black,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isActive ? AppColors.purple72 : AppColors.grey94,
              size: 18.r,
            ),
            SizedBox(width: 6.w),
          ],
        ),
      ),
    );
  }
}

class _TopCategories extends StatelessWidget {
  const _TopCategories();

  static const _cats = [
    _CatItem('Interior\nDesign', Icons.chair_rounded, Color(0xFFFF6B2C)),
    _CatItem('Renovation\n/ Civil', Icons.home_work_rounded, Color(0xFFFF8C42)),
    _CatItem('Painting', Icons.format_paint_rounded, Color(0xFFE63946)),
    _CatItem('Plumbing', Icons.plumbing_rounded, Color(0xFF0099FF)),
    _CatItem('Electrical\nWork', Icons.bolt_rounded, Color(0xFFFFB800)),
    _CatItem('Carpentry', Icons.carpenter_rounded, Color(0xFF8B4513)),
    _CatItem('CCTV\nInstallation', Icons.videocam_rounded, Color(0xFF2DC653)),
    _CatItem('AC Service', Icons.ac_unit_rounded, Color(0xFF00B8D9)),
    _CatItem('Modular\nKitchen', Icons.kitchen_rounded, Color(0xFF7B2FBE)),
    _CatItem('False\nCeiling', Icons.layers_rounded, Color(0xFFE63946)),
    _CatItem('Home\nAutomation', Icons.smart_toy_rounded, Color(0xFF0072FF)),
    _CatItem('Waterproofing', Icons.water_drop_rounded, Color(0xFF1A1A7E)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12.w, 10.h, 16.w, 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Categories',
                style: AppTextStyles.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey77,
                ),
              ),
              Text(
                'View All',
                style: AppTextStyles.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple72,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300.h,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 2.h,
              crossAxisSpacing: 30.w,
              childAspectRatio: 0.85,
            ),
            itemCount: _cats.length,
            itemBuilder: (_, i) => _CategoryTile(item: _cats[i]),
          ),
        ),
      ],
    );
  }
}

class _CatItem {
  final String label;
  final IconData icon;
  final Color color;
  const _CatItem(this.label, this.icon, this.color);
}

class _CategoryTile extends StatelessWidget {
  final _CatItem item;
  const _CategoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(item.icon, color: item.color, size: 26.r),
          ),
          SizedBox(height: 5.h),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: AppTextStyles.poppins(
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.grey77,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeLeadSliver extends ConsumerWidget {
  final void Function(LeadModel) onAddToCart;
  const _HomeLeadSliver({required this.onAddToCart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingProvider);
    final errorMessage = ref.watch(errorMessageProvider);
    final leads = ref.watch(leadsProvider);

    if (isLoading && leads.isEmpty) {
      return const SliverFillRemaining(child: LeadListShimmer());
    }
    if (errorMessage != null) {
      return SliverFillRemaining(
        child: ErrorStateWidget(
          message: errorMessage,
          onRetry: () => ref.read(homeControllerProvider.notifier).loadLeads(),
        ),
      );
    }
    if (leads.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyStateWidget(message: 'No leads available'),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == leads.length) return SizedBox(height: 100.h);
        final lead = leads[index];
        return _LeadListItem(lead: lead, onAddToCart: onAddToCart);
      }, childCount: leads.length + 1),
    );
  }
}

class _LeadListItem extends ConsumerWidget {
  final LeadModel lead;
  final void Function(LeadModel) onAddToCart;

  const _LeadListItem({required this.lead, required this.onAddToCart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSoldOut = lead.status == 'SOLD_OUT';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Container(
        padding: EdgeInsets.fromLTRB(10.w, 4.h, 8.w, 0.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            /// ───── IMAGE ─────
            Padding(
              padding: EdgeInsets.fromLTRB(0.w, 0.h, 0.w, 4.h),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: SizedBox(
                  width: 107.w,
                  height: 78.h,
                  child: Image.network(lead.imageUrl, fit: BoxFit.cover),
                ),
              ),
            ),

            SizedBox(width: 12.w),

            /// ───── CONTENT ─────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Title + vendor count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lead.title ?? "1/2",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  /// Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14.r, color: Colors.grey),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          lead.address,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.poppins(
                            fontSize: 11.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 3.h),

                  /// Price

                  /// ───── BUTTONS ROW ─────
                  Row(
                    children: [
                      /// Add to Cart
                      Text(
                        "₹ ${lead.originalPrice ?? 0}",
                        style: AppTextStyles.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.purple72,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: isSoldOut ? null : () => onAddToCart(lead),
                          child: Container(
                            height: 28.h,

                            // padding: EdgeInsets.symmetric(vertical: 8.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: AppColors.purple72),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "Add to Cart",
                              style: AppTextStyles.poppins(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.purple72,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 8.w),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            height: 28.h,

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4A2CD9), Color(0xFF6A4DFF)],
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "View Leads",
                              style: AppTextStyles.poppins(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

String firstWords(String text, int count) {
  final words = text.trim().split(RegExp(r'\s+'));
  if (words.length <= count) return text;
  return '${words.take(count).join(' ')}...';
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;
  const _QtyControl({
    required this.qty,
    required this.onInc,
    required this.onDec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.purple72),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove, onTap: onDec),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Text(
              '$qty',
              style: AppTextStyles.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.purple72,
              ),
            ),
          ),
          _QtyBtn(icon: Icons.add, onTap: onInc),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.r),
        child: Icon(icon, size: 16.r, color: AppColors.purple72),
      ),
    );
  }
}
