//*************   © Copyrighted by Criterion Tech. *********************

import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Screens/calling_screen/pickup_layout.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PDFViewerCachedFromUrl extends StatelessWidget {
  const PDFViewerCachedFromUrl(
      {Key? key,
      required this.url,
      required this.title,
      required this.prefs,
      required this.isregistered})
      : super(key: key);
  final SharedPreferences prefs;
  final String? url;
  final String title;
  final bool isregistered;

  @override
  Widget build(BuildContext context) {
    return isregistered == false
        ? Scaffold(
            appBar: AppBar(
              elevation: 0.4,
              leading: IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  Icons.keyboard_arrow_left,
                  size: 30,
                  color: pickTextColorBasedOnBgColorAdvanced(
                      Thm.isDarktheme(prefs)
                          ? corncallAPPBARcolorDarkMode
                          : corncallAPPBARcolorLightMode),
                ),
              ),
              title: Text(
                title,
                style: TextStyle(
                    color: pickTextColorBasedOnBgColorAdvanced(
                        Thm.isDarktheme(prefs)
                            ? corncallAPPBARcolorDarkMode
                            : corncallAPPBARcolorLightMode),
                    fontSize: 18),
              ),
              backgroundColor: Thm.isDarktheme(prefs)
                  ? corncallAPPBARcolorDarkMode
                  : corncallAPPBARcolorLightMode,
            ),
            body: const PDF().cachedFromUrl(
              url!,
              placeholder: (double progress) =>
                  Center(child: Text('$progress %')),
              errorWidget: (dynamic error) =>
                  Center(child: Text(error.toString())),
            ),
          )
        : PickupLayout(
            prefs: prefs,
            scaffold: Corncall.getNTPWrappedWidget(Scaffold(
              appBar: AppBar(
                elevation: 0.4,
                leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.keyboard_arrow_left,
                    size: 30,
                    color: pickTextColorBasedOnBgColorAdvanced(
                        Thm.isDarktheme(prefs)
                            ? corncallAPPBARcolorDarkMode
                            : corncallAPPBARcolorLightMode),
                  ),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                      color: pickTextColorBasedOnBgColorAdvanced(
                          Thm.isDarktheme(prefs)
                              ? corncallAPPBARcolorDarkMode
                              : corncallAPPBARcolorLightMode),
                      fontSize: 18),
                ),
                backgroundColor: Thm.isDarktheme(prefs)
                    ? corncallAPPBARcolorDarkMode
                    : corncallAPPBARcolorLightMode,
              ),
              body: const PDF().cachedFromUrl(
                url!,
                placeholder: (double progress) =>
                    Center(child: Text('$progress %')),
                errorWidget: (dynamic error) =>
                    Center(child: Text(error.toString())),
              ),
            )));
  }
}
