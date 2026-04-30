import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/home/domain/leads_model.dart';
import 'package:user_app/features/home/presentation/screens/home_screen.dart';
import 'package:user_app/features/home/presentation/widgets/home_search_bar.dart';
import 'package:user_app/features/home/shared/home_providers.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homeControllerProvider.notifier).loadLeads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final leads = ref.watch(leadsProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "All Leads",
          style: AppTextStyles.poppins(
            fontSize: 23.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
            child: const HomeSearchBar(),
          ),

          /// 📋 LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : leads.isEmpty
                ? const Center(child: Text("No Leads Found"))
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 20.h),
                    itemCount: leads.length,
                    itemBuilder: (_, i) => _LeadTile(
                      lead: leads[i],
                      onAddToCart: (LeadModel p1) {},
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LeadTile extends HookConsumerWidget {
  final LeadModel lead;
  final void Function(LeadModel) onAddToCart;

  const _LeadTile({required this.lead, required this.onAddToCart});

  @override
  Widget build(BuildContext context, WidgetRef rerf) {
    final isSoldOut = lead.status == 'SOLD_OUT';
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          /// IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: SizedBox(
              width: 90.w,
              height: 80.h,
              child: Image.network(
                lead.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
          ),

          SizedBox(width: 10.w),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ✅ SHORT TITLE (2–3 WORDS ONLY)
                Text(
                  firstWords(lead.title ?? "", 3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 4.h),

                /// LOCATION
                Text(
                  lead.address ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.poppins(
                    fontSize: 11.sp,
                    color: Colors.grey,
                  ),
                ),

                SizedBox(height: 6.h),

                /// PRICE
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
    );
  }
}
