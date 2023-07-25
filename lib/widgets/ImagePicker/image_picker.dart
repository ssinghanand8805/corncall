//*************   © Copyrighted by Criterion Tech. *********************

import 'dart:io';
import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Screens/status/components/VideoPicker/VideoPicker.dart';
import 'package:corncall/Services/Providers/Observer.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/open_settings.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SingleImagePicker extends StatefulWidget {
  SingleImagePicker(
      {Key? key,
      required this.title,
      required this.prefs,
      required this.callback,
      this.profile = false})
      : super(key: key);

  final String title;
  final SharedPreferences prefs;
  final Function callback;
  final bool profile;

  @override
  _SingleImagePickerState createState() => new _SingleImagePickerState();
}

class _SingleImagePickerState extends State<SingleImagePicker> {
  File? _imageFile;
  ImagePicker picker = ImagePicker();
  bool isLoading = false;
  String? error;
  @override
  void initState() {
    super.initState();
  }

  void captureImage(ImageSource captureMode) async {
    final observer = Provider.of<Observer>(this.context, listen: false);
    error = null;
    try {
      XFile? pickedImage = await (picker.pickImage(source: captureMode));
      if (pickedImage != null) {
        _imageFile = File(pickedImage.path);
        setState(() {});
        if (_imageFile!.lengthSync() / 1000000 >
            observer.maxFileSizeAllowedInMB) {
          error =
              '${getTranslated(this.context, 'maxfilesize')} ${observer.maxFileSizeAllowedInMB}MB\n\n${getTranslated(this.context, 'selectedfilesize')} ${(_imageFile!.lengthSync() / 1000000).round()}MB';

          setState(() {
            _imageFile = null;
          });
        } else {
          setState(() {
            _imageFile = File(_imageFile!.path);
          });
        }
      }
    } catch (e) {}
  }

  Widget _buildImage() {
    if (_imageFile != null) {
      return new Image.file(_imageFile!);
    } else {
      return new Text(getTranslated(context, 'takeimage'),
          style: new TextStyle(
            fontSize: 18.0,
            color: corncallGrey,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Corncall.getNTPWrappedWidget(WillPopScope(
      child: Scaffold(
        backgroundColor: Thm.isDarktheme(widget.prefs)
            ? corncallBACKGROUNDcolorDarkMode
            : corncallBACKGROUNDcolorLightMode,
        appBar: new AppBar(
            elevation: 0.4,
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.keyboard_arrow_left,
                size: 30,
                color: pickTextColorBasedOnBgColorAdvanced(
                    Thm.isDarktheme(widget.prefs)
                        ? corncallAPPBARcolorDarkMode
                        : corncallAPPBARcolorLightMode),
              ),
            ),
            title: new Text(
              widget.title,
              style: TextStyle(
                fontSize: 18,
                color: pickTextColorBasedOnBgColorAdvanced(
                    Thm.isDarktheme(widget.prefs)
                        ? corncallAPPBARcolorDarkMode
                        : corncallAPPBARcolorLightMode),
              ),
            ),
            backgroundColor: Thm.isDarktheme(widget.prefs)
                ? corncallAPPBARcolorDarkMode
                : corncallAPPBARcolorLightMode,
            actions: _imageFile != null
                ? <Widget>[
                    IconButton(
                        icon: Icon(
                          Icons.check,
                          color: pickTextColorBasedOnBgColorAdvanced(
                              Thm.isDarktheme(widget.prefs)
                                  ? corncallAPPBARcolorDarkMode
                                  : corncallAPPBARcolorLightMode),
                        ),
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                          });
                          widget.callback(_imageFile).then((imageUrl) {
                            Navigator.pop(context, imageUrl);
                          });
                        }),
                    SizedBox(
                      width: 8.0,
                    )
                  ]
                : []),
        body: Stack(children: [
          new Column(children: [
            new Expanded(
                child: new Center(
                    child: error != null
                        ? fileSizeErrorWidget(error!)
                        : _buildImage())),
            _buildButtons()
          ]),
          Positioned(
            child: isLoading
                ? Container(
                    child: Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              corncallSECONDARYolor)),
                    ),
                    color: pickTextColorBasedOnBgColorAdvanced(
                            !Thm.isDarktheme(widget.prefs)
                                ? corncallCONTAINERboxColorDarkMode
                                : corncallCONTAINERboxColorLightMode)
                        .withOpacity(0.6),
                  )
                : Container(),
          )
        ]),
      ),
      onWillPop: () => Future.value(!isLoading),
    ));
  }

  Widget _buildButtons() {
    return new ConstrainedBox(
        constraints: BoxConstraints.expand(height: 80.0),
        child: new Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildActionButton(new Key('retake'), Icons.photo_library, () {
                Corncall.checkAndRequestPermission(Permission.storage)
                    .then((res) {
                  if (res) {
                    captureImage(ImageSource.gallery);
                  } else {
                    Corncall.showRationale(getTranslated(context, 'pgi'));
                    Navigator.pushReplacement(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => OpenSettings(
                                  prefs: widget.prefs,
                                )));
                  }
                });
              }),
              _buildActionButton(new Key('upload'), Icons.photo_camera, () {
                Corncall.checkAndRequestPermission(Permission.camera)
                    .then((res) {
                  if (res) {
                    captureImage(ImageSource.camera);
                  } else {
                    getTranslated(context, 'pci');
                    Navigator.pushReplacement(
                        context,
                        new MaterialPageRoute(
                            builder: (context) => OpenSettings(
                                  prefs: widget.prefs,
                                )));
                  }
                });
              }),
            ]));
  }

  Widget _buildActionButton(Key key, IconData icon, Function onPressed) {
    return new Expanded(
      child: new IconButton(
          key: key,
          icon: Icon(icon, size: 30.0),
          color: Thm.isDarktheme(widget.prefs)
              ? corncallAPPBARcolorDarkMode
              : corncallAPPBARcolorLightMode,
          onPressed: onPressed as void Function()?),
    );
  }
}
