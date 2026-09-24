# Razorpay SDK keep rules
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !class/merging/vertical*,!class/merging/horizontal*

# Prevent shrinking of reflection-based models
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Flutter embedding keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google & Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
