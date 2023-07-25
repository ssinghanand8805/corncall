import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GalleryDownloader {
  static void saveNetworkVideoInGallery(
      BuildContext context,
      String url,
      bool isFurtherOpenFile,
      String fileName,
      GlobalKey keyloader,
      SharedPreferences prefs) async {
    String path = url + "&ext=.mp4";
    Dialogs.showLoadingDialog(context, keyloader, prefs);
    GallerySaver.saveVideo(path).then((success) async {
      if (success == true) {
        Navigator.of(keyloader.currentContext!, rootNavigator: true).pop();

        Corncall.toast("$fileName  " + getTranslated(context, "folder"));
      } else {
        Navigator.of(keyloader.currentContext!, rootNavigator: true).pop();
        Corncall.toast(getTranslated(context, 'failedtodownload'));
      }
    }).catchError((err) {
      Navigator.of(keyloader.currentContext!, rootNavigator: true).pop();
      Corncall.toast(err.toString());
    });
  }

  static void saveNetworkImage(
      BuildContext context,
      String url,
      bool isFurtherOpenFile,
      String fileName,
      GlobalKey keyloader,
      SharedPreferences prefs) async {
    // String path =
    //     'https://image.shutterstock.com/image-photo/montreal-canada-july-11-2019-600w-1450023539.jpg';

    String path = url + "&ext=.jpg";
    Dialogs.showLoadingDialog(context, keyloader, prefs);
    GallerySaver.saveImage(path, toDcim: true).then((success) async {
      if (success == true) {
        Navigator.of(keyloader.currentContext!, rootNavigator: true).pop();
        Corncall.toast(fileName == ""
            ? getTranslated(context, "folder")
            : "$fileName  " + getTranslated(context, "folder"));
      } else {
        Corncall.toast(getTranslated(context, 'failedtodownload'));
        Navigator.of(keyloader.currentContext!, rootNavigator: true).pop();
      }
    }).catchError((err) {
      Navigator.of(keyloader.currentContext!, rootNavigator: true).pop();
      Corncall.toast(err.toString());
    });
  }
}

class Dialogs {
  static Future<void> showLoadingDialog(
      BuildContext context, GlobalKey key, SharedPreferences prefs) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new WillPopScope(
              onWillPop: () async => false,
              child: SimpleDialog(
                  key: key,
                  backgroundColor: Thm.isDarktheme(prefs)
                      ? corncallDIALOGColorDarkMode
                      : corncallDIALOGColorLightMode,
                  children: <Widget>[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 18,
                              ),
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    corncallSECONDARYolor),
                              ),
                              SizedBox(
                                width: 23,
                              ),
                              Text(
                                getTranslated(context, "downloading"),
                                style: TextStyle(
                                  color: pickTextColorBasedOnBgColorAdvanced(
                                      Thm.isDarktheme(prefs)
                                          ? corncallDIALOGColorDarkMode
                                          : corncallDIALOGColorLightMode),
                                ),
                              )
                            ]),
                      ),
                    )
                  ]));
        });
  }
}
