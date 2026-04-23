import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

// ── Status Badge ──────────────────────────────────────────────────────────────
class HistoryStatusBadge extends StatelessWidget {
  final String status;
  const HistoryStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status.toLowerCase() == 'paid';
    return Container(
      height: 28.h,
      width: 98.w,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: isPaid ?Color.fromRGBO(79,195,98,1) : Colors.orange,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        status,
        style: AppTextStyles.roboto(
          color: AppColors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          height: 1.48
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64.r, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your purchased leads will appear here.',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────
class HistoryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const HistoryErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56.r, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BC34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
              ),
              child: Text('Retry', style: TextStyle(fontSize: 14.sp)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer Loader ────────────────────────────────────────────────────────────
class HistoryShimmerList extends StatefulWidget {
  const HistoryShimmerList({super.key});

  @override
  State<HistoryShimmerList> createState() => _HistoryShimmerListState();
}

class _HistoryShimmerListState extends State<HistoryShimmerList>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box({double? width, required double height}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4.r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: ListView.builder(
          itemCount: 4,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, __) => Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _box(width: 54.w, height: 46.h),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(width: 140.w, height: 14.h),
                        SizedBox(height: 6.h),
                        _box(width: 90.w, height: 11.h),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _box(width: double.infinity, height: 11.h),
                SizedBox(height: 6.h),
                _box(width: 200.w, height: 11.h),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _box(width: 110.w, height: 11.h),
                    _box(width: 60.w, height: 26.h),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}