import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

setStatusBarColor(SharedPreferences prefs) {
  if (Thm.isDarktheme(prefs) == true) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: corncallAPPBARcolorDarkMode,
        statusBarIconBrightness: isDarkColor(corncallAPPBARcolorDarkMode)
            ? Brightness.light
            : Brightness.dark));
  } else {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: corncallAPPBARcolorLightMode,
        statusBarIconBrightness: isDarkColor(corncallAPPBARcolorLightMode)
            ? Brightness.light
            : Brightness.dark));
  }
}
