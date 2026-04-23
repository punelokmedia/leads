// // auth/presentation/widgets/auth_widgets.dart

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
// import 'package:user_app/core/theme/app_colors.dart';
// import 'package:user_app/core/theme/app_text_styles.dart';

// // ── Logo ──────────────────────────────────────────────────────────────────────
// class AuthLogo extends StatelessWidget {
//   const AuthLogo({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Replace with Image.asset('assets/images/logo.png') if available
//         Container(
//           width: 296.w,
//           height: 99.h,
//           decoration: const BoxDecoration(
//             image: DecorationImage(
//               image: AssetImage('assets/Images/home/logo_leads.png'),
//               fit: BoxFit.contain,
//             ),
//           ),
//         ),
       
//       ],
//     );
//   }
// }

// // ── Auth text field ───────────────────────────────────────────────────────────
// class AuthTextField extends StatelessWidget {
//   final String label;
//   final String hint;
//   final TextEditingController controller;
//   final TextInputType keyboardType;
//   final bool obscureText;
//   final Widget? suffixIcon;
//   final String? Function(String?)? validator;
//   final TextInputAction textInputAction;
//   final List<TextInputFormatter>? inputFormatters;
  
//   const AuthTextField({
//     super.key,
//     required this.label,
//     required this.hint,
//     required this.controller,
//     this.keyboardType = TextInputType.text,
//     this.obscureText = false,
//     this.suffixIcon,
//     this.validator,
//     this.textInputAction = TextInputAction.next,
//     this.inputFormatters,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: AppTextStyles.poppins(
//             fontSize: 18.sp,
//             fontWeight: FontWeight.w500,
//             color: AppColors.grey77,
//             height: 20/18,
//             letterSpacing: 0.1
//           ),
//         ),
//         SizedBox(height: 6.h),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12.r),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: TextFormField(
//             controller: controller,
//             keyboardType: keyboardType,
//             obscureText: obscureText,
//             validator: validator,
//             textInputAction: textInputAction,
//             inputFormatters: inputFormatters,
//             style: AppTextStyles.poppins(
//               fontSize: 16.sp, 
//               color: AppColors.grey77,
//               fontWeight: FontWeight.w500,
//               height: 20/16,
//               letterSpacing: 0.1
//             ),
//             decoration: InputDecoration(
//               hintText: hint,
//               errorStyle: const TextStyle(height: 0, fontSize: 0),
//               hintStyle:  AppTextStyles.poppins(
//               fontSize: 16.sp, 
//               color: AppColors.grey77,
//               fontWeight: FontWeight.w500,
//               height: 20/16,
//               letterSpacing: 0.1
//             ),
//               suffixIcon: suffixIcon,
//               filled: true,
//               fillColor: Colors.transparent,
//               contentPadding:
//                   EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12.r),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12.r),
//                 borderSide: BorderSide.none,
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12.r),
//                 borderSide:
//                     const BorderSide(color: Color(0xFFFFC107), width: 1.5),
//               ),
//               errorBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12.r),
//                 borderSide: const BorderSide(color: Colors.red, width: 1),
//               ),
//               focusedErrorBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12.r),
//                 borderSide: const BorderSide(color: Colors.red, width: 1.5),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ── Password field wrapper ────────────────────────────────────────────────────
// class PasswordField extends StatefulWidget {
//   final String label;
//   final String hint;
//   final TextEditingController controller;
//   final String? Function(String?)? validator;
//   final TextInputAction textInputAction;

//   const PasswordField({
//     super.key,
//     this.label = 'Password',
//     this.hint = '••••••••',
//     required this.controller,
//     this.validator,
//     this.textInputAction = TextInputAction.done,
//   });

//   @override
//   State<PasswordField> createState() => _PasswordFieldState();
// }

// class _PasswordFieldState extends State<PasswordField> {
//   bool _obscure = true;

//   @override
//   Widget build(BuildContext context) {
//     return AuthTextField(
//       label: widget.label,
//       hint: widget.hint,
//       controller: widget.controller,
//       obscureText: _obscure,
//       validator: widget.validator,
//       textInputAction: widget.textInputAction,
//       suffixIcon: GestureDetector(
//         onTap: () => setState(() => _obscure = !_obscure),
//         child: Icon(
//           _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
//           size: 20.r,
//           color: Colors.grey[400],
//         ),
//       ),
//     );
//   }
// }

// // ── Primary amber button ──────────────────────────────────────────────────────
// class AuthPrimaryButton extends StatelessWidget {
//   final String label;
//   final VoidCallback? onTap;
//   final bool isLoading;

//   const AuthPrimaryButton({
//     super.key,
//     required this.label,
//     required this.onTap,
//     this.isLoading = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: isLoading ? null : onTap,
//       child: Container(
//         width: double.infinity,
//         height: 62.h,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color.fromRGBO(253,255,29,1),
//               Color.fromRGBO(248,176,32,1)
//               // AppColors.orange248,
//             ],
//           ),
//           borderRadius: BorderRadius.circular(14.r),
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFFFFC107).withOpacity(0.4),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Center(
//           child: isLoading
//               ? const CircularProgressIndicator(
//                   color: Colors.white, strokeWidth: 2)
//               : Text(
//                   label,
//                   style: AppTextStyles.poppins(
//                     fontSize: 24.sp,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.white,
//                     height: 20/24,
//                     letterSpacing: 0.1
//                   ),
//                 ),
//         ),
//       ),
//     );
//   }
// }

// // ── Google sign-in button ─────────────────────────────────────────────────────
// class GoogleSignInButton extends StatelessWidget {
//   final VoidCallback onTap;

//   const GoogleSignInButton({super.key, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
//         decoration: BoxDecoration(
//           color: AppColors.white239,
//           borderRadius: BorderRadius.circular(20.r),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 10,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset('assets/Images/login/google.png',
//                 height: 19.r,
//                 errorBuilder: (_, __, ___) => Icon(Icons.g_mobiledata_rounded,
//                     size: 19.r, color: Colors.red)),
//             SizedBox(width: 8.w),
//             Text(
//               'Google',
//               style: AppTextStyles.poppins(
//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.grey77,
//                 height: 20/16,
//                 letterSpacing: 0.1
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Divider with text ─────────────────────────────────────────────────────────
// class OrDivider extends StatelessWidget {
//   final String text;
//   const OrDivider({super.key, this.text = 'Or Sign in With'});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(child: Divider(color: Color.fromRGBO(176,176,176,1), thickness: 1)),
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 12.w),
//           child: Text(
//             text,
//             style: AppTextStyles.poppins(fontSize: 14.sp, color: AppColors.grey77,fontWeight: FontWeight.w400,height: 20/14,letterSpacing: 0.1),
//           ),
//         ),
//         Expanded(child: Divider(color: Color.fromRGBO(176,176,176,1), thickness: 1)),
//       ],
//     );
//   }
// }

// // ── Error banner ──────────────────────────────────────────────────────────────
// class AuthErrorBanner extends StatelessWidget {
//   final String message;
//   const AuthErrorBanner({super.key, required this.message});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
//       decoration: BoxDecoration(
//         color: Colors.red[50],
//         borderRadius: BorderRadius.circular(10.r),
//         border: Border.all(color: Colors.red[200]!),
//       ),
//       child: Text(
//         message,
//         style: AppTextStyles.poppins(
//             fontSize: 14.sp, 
//             color: AppColors.red223, 
//             fontWeight: FontWeight.w500,
//             height: 20/14,
//             letterSpacing: 0.1
//         ),
//       ),
//     );
//   }
// }