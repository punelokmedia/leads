import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart'; // Make sure this is imported
import 'package:user_app/features/home/domain/leads_model.dart';
import 'package:user_app/features/home/presentation/screens/home_screen.dart';
import 'package:user_app/features/home/presentation/widgets/home_search_bar.dart';
import 'package:user_app/features/home/shared/home_providers.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart'; // Add your cart provider import

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

  // ✅ Added real add-to-cart logic handling the quantity parameter
  void _onAddToCart(LeadModel lead, int quantity) async {
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
      }
    }
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
                      onAddToCart: _onAddToCart, // ✅ Passed the actual function here
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ✅ Converted to StatefulWidget to handle quantity state
class _LeadTile extends StatefulWidget {
  final LeadModel lead;
  final void Function(LeadModel, int) onAddToCart;

  const _LeadTile({required this.lead, required this.onAddToCart});

  @override
  State<_LeadTile> createState() => _LeadTileState();
}

class _LeadTileState extends State<_LeadTile> {
  int _quantity = 0; // Local state to track cart quantity

  void _increment() {
    if (_quantity < widget.lead.sharingCount) {
      setState(() {
        _quantity++;
      });
      widget.onAddToCart(widget.lead, _quantity);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum sharing limit of ${widget.lead.sharingCount} reached for this lead.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _decrement() {
    if (_quantity > 0) {
      setState(() {
        _quantity--;
      });
      widget.onAddToCart(widget.lead, _quantity);
    }
  }

  // Helper method used in your original code
  String firstWords(String text, int count) {
    List<String> words = text.split(' ');
    if (words.length <= count) return text;
    return words.take(count).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isSoldOut = widget.lead.status == 'SOLD_OUT';
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
                widget.lead.imageUrl,
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
                  firstWords(widget.lead.title ?? "", 3),
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
                  widget.lead.address ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.poppins(
                    fontSize: 11.sp,
                    color: Colors.grey,
                  ),
                ),

                SizedBox(height: 6.h),

                /// PRICE & BUTTONS
                Row(
                  children: [
                    /// Price text
                    Text(
                      "₹ ${widget.lead.originalPrice ?? 0}",
                      style: AppTextStyles.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple72,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    
                    /// ✅ Add to Cart / Plus-Minus Toggle
                    Expanded(
                      child: _quantity == 0
                          ? GestureDetector(
                              onTap: isSoldOut
                                  ? null
                                  : () {
                                      setState(() {
                                        _quantity = 1;
                                      });
                                      widget.onAddToCart(widget.lead, _quantity);
                                    },
                              child: Container(
                                height: 28.h,
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
                            )
                          : Container(
                              height: 28.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: AppColors.purple72),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: _decrement,
                                    child: Container(
                                      width: 24.w,
                                      color: Colors.transparent,
                                      alignment: Alignment.center,
                                      child: Icon(Icons.remove, size: 14.r, color: AppColors.purple72),
                                    ),
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: AppTextStyles.poppins(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.purple72,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _increment,
                                    child: Container(
                                      width: 24.w,
                                      color: Colors.transparent,
                                      alignment: Alignment.center,
                                      child: Icon(Icons.add, size: 14.r, color: AppColors.purple72),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    SizedBox(width: 8.w),

                    /// View Leads
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.push(AppRouter.leadDetailsPath, extra: widget.lead);
                        },
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