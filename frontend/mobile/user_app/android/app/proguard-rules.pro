# Razorpay uses reflection and payment callbacks in release builds.
# https://github.com/razorpay/razorpay-flutter#proguard-rules
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/
-keepclasseswithmembers class * {
    public void onPayment*(...);
}
