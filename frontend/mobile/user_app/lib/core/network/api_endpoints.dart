import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  // ── Base ───────────────────────────────────────────────
  static String get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';
  static String get razorpayKeySecret =>
      dotenv.env['RAZORPAY_KEY_SECRET'] ?? '';

  static const String _v = 'v1';
  static const String _api = 'api';
  static const String _apiV1 = '$_api/$_v';
  // static const String _apiV1 = _api;

  static const String _user = '$_apiV1/user';
  static const String _auth = '$_apiV1/auth';
  static const String _cart = '$_apiV1/cart';
  

  // ── Auth endpoints ─────────────────────────────────────────────────────────
  static const String register = '$_auth/register';
  static const String login = '$_auth/login';
  static const String googleAuth = '$_auth/google';
  static const String logout = '$_auth/logout';
  static const String forgotPassword = '$_auth/forgot-password';
  static const String sendOtp = '$_auth/send-otp';
  static const String verifyOtp = '$_auth/verify-otp';
  static const String changePassword = '$_auth/change-password';
  static const String addAddress='$_auth/add-address';
  static const String resetPassword='$_auth/reset-password';
  


  //
  static const String getAllLeads='$_apiV1/leads/get-all-leads';
  // ── Cart ───────────────────────────────────────
  static const String cart = '$_cart/get-cart';                     // GET all
  static const String deleteCartItem = '$_cart/delete-cart-item';
  static const String addToCart = '$_cart/add-cart';                // POST
  static const String checkoutCart = '$_cart/checkout'; // POST
  static const String history='$_apiV1/leads/history';
  

  //──Profile───────────────────────────────────────
  static const String fetchProfile='$_auth/profile';
  static const String editProfile='$_auth/update-profile';

   //──Razorpay───────────────────────────────────────
  static const String payCart = '$_apiV1/payments/create';  
  static const String verifyPayment = '$_apiV1/payments/verify';  
  static String downloadLead(String internalOrderId)=>'$_apiV1/leads/download/$internalOrderId';


}

