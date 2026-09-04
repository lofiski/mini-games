# flutter_soloud 通过 FFI 调用原生库，保留其入口避免被裁剪
-keep class com.soloud.** { *; }
-keep class **.SoLoud** { *; }

# Flutter 嵌入层
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
