-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

# Razorpay rules
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# ProGuard annotation rules
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers