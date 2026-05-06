import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/home/domain/leads_model.dart';
import 'package:user_app/features/home/presentation/widgets/lead_payment_bottom_bar.dart';

class LeadDetailsScreen extends StatelessWidget {
  final LeadModel lead; // ✅ Accept dynamic lead data

  const LeadDetailsScreen({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.r,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Leads Details',
          style: AppTextStyles.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 50.w,
                            width: 50.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFF534AB7),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.business,
                              color: Colors.white,
                              size: 28.r,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lead.title,
                                  style: AppTextStyles.poppins(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4.h),

                                Text(
                                  lead.address,
                                  style: AppTextStyles.poppins(
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // NEW Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8A4DFF),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8.r),
                                topRight: Radius.circular(8.r),
                                bottomLeft: Radius.circular(8.r),
                                bottomRight: Radius.zero,
                              ),
                            ),
                            child: Text(
                              'NEW',
                              style: AppTextStyles.poppins(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                    ),

                    // ── Stats ──
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Budget',
                                style: AppTextStyles.poppins(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              // ✅ Dynamic Price
                              Text(
                                '₹${lead.originalPrice.toInt()}',
                                style: AppTextStyles.poppins(
                                  fontSize: 20.sp,
                                  color: const Color(0xFF28A745),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Lead Id : ',
                                  children: [
                                    TextSpan(
                                      text: lead.leadId,
                                      style: TextStyle(
                                        color: AppColors.purple72,
                                      ),
                                    ),
                                  ],
                                ),
                                style: AppTextStyles.poppins(
                                  fontSize: 14.sp,
                                  color:
                                      Colors.grey.shade600, // Color for "Lead Id : "
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Vendors Joined',
                                style: AppTextStyles.poppins(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    color: Colors.grey.shade700,
                                    size: 20.r,
                                  ),
                                  SizedBox(width: 6.w),
                                  // Dynamic Sharing Count
                                  Text(
                                    '${lead.sharingCount} / 2',
                                    style: AppTextStyles.poppins(
                                      fontSize: 16.sp,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                    ),

                    // ── Description ──
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Discription',
                            style: AppTextStyles.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8.h),

                          Text(
                            lead.description.isNotEmpty
                                ? lead.description
                                : 'No description provided.',
                            style: AppTextStyles.poppins(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                    ),

                    // ── Info Grid ──
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            'Project Type',
                            lead.title.split(' ').first,
                          ), // Fallback approximation
                          _buildInfoRow('City', lead.city),
                          _buildInfoRow('Posted On', lead.date),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Integrated Razorpay Bottom Bar ──
          // Pass the discounted price down if your bottom bar needs to know what to charge
          LeadPaymentBottomBar(lead: lead),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.poppins(
                fontSize: 13.sp,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.poppins(
                fontSize: 13.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
