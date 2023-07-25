import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Configs/app_constants.dart';
import '../../../Services/localization/language_constants.dart';
import '../../../Utils/theme_management.dart';
import '../../meeting/meeting2.dart';

class InstantMeeting extends StatefulWidget {
  final String id;
  final String password;
  final SharedPreferences prefs;
  const InstantMeeting(
      {Key? key, required this.id, required this.password, required this.prefs})
      : super(key: key);

  @override
  State<InstantMeeting> createState() => _InstantMeetingState();
}

class _InstantMeetingState extends State<InstantMeeting> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setIntialValue();
  }

  bool isSwitched = true;
  bool check = true;
  bool isFresh = false;
  final rng = Random();
  random() {
    var randomNumber = rng.nextInt(100000000).toString();
    print("random number: $randomNumber");
    _idController = TextEditingController(text: randomNumber.toString());
  }

  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(rng.nextInt(_chars.length))));

  password() {
    final password = getRandomString(6);
    _pwController.text = password;
    print("password : $password");
  }

  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();
  TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  _shareTheMap() async {
    if (_idController.text.isEmpty) {
      return SnackBar(
        content: Text("Please enter valid id"),
      );
    }
    var id = '${_idController.text}_${_pwController.text}';
    var url = 'https://www.corncall.com/?userId=${id}';
    //var link = await _createDynamicLink(true, url);
    Share.share("");
  }

  void clearText() {
    isFresh = true;
    _idController.clear();
    _pwController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Thm.isDarktheme(widget.prefs)
            ? corncallCONTAINERboxColorDarkMode
            : Colors.white,
        appBar: AppBar(
            elevation: 0,
            backgroundColor: Thm.isDarktheme(widget.prefs)
                ? corncallAPPBARcolorDarkMode
                : corncallAPPBARcolorLightMode,
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon( Icons.arrow_back_ios,size: 20,),
            ),
            title:  Text(getTranslated(this.context, 'joinmeeting'))),
        body: Container(
          padding: EdgeInsets.all(15),
          child: Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _idController,
                  decoration:  InputDecoration(
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white38, width: 2.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white38, width: 2.0),
                      ),
                      hintText: getTranslated(this.context, 'Id')),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: _pwController,
                  decoration:  InputDecoration(
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white38, width: 2.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white38, width: 2.0),
                      ),
                      hintText: getTranslated(this.context, 'Password')),
                ),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  children: [
                     Text(getTranslated(this.context, 'joinwithvideo'),
                        style: TextStyle(
                            fontSize: 18,
                            fontFamily: FONTFAMILY_NAME_ONLY_LOGO)),
                    const Spacer(),
                    Switch(
                      value: isSwitched,
                      activeColor: SplashBackgroundSolidColor,
                      onChanged: (bool value) {
                        setState(() {
                          isSwitched = !isSwitched;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                     Text(getTranslated(this.context, 'Defaultmute'),
                        style: TextStyle(
                            fontSize: 18,
                            fontFamily: FONTFAMILY_NAME_ONLY_LOGO)),
                    const Spacer(),
                    SizedBox(
                      height: 70,
                      width: 70,
                      child: Checkbox(
                        value: check,
                        onChanged: (bool? value) {
                          setState(() {
                            check = !check;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _shareTheMap();
                    });
                  },
                  child: Container(
                    height: 40,
                    width: 90,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black26, width: 2),
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.transparent),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:  [
                        Icon(Icons.share, color: Colors.blue),
                        SizedBox(
                          width: 10,
                        ),
                        Text(getTranslated(this.context, 'Share'))
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Center(
                  child: MaterialButton(
                    color: corncallREDbuttonColor,
                    textColor: Colors.white,
                    child:  Text(getTranslated(this.context, 'cancel')),
                    onPressed: () {
                      setState(() {
                        Navigator.pop(context);
                        clearText();
                      });
                    },
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                RoundedLoadingButton(
                  color:Thm.isDarktheme(widget.prefs)
                    ? corncallAPPBARcolorDarkMode
                    : corncallAPPBARcolorLightMode,
                  controller: _btnController,
                  onPressed: () async {
                    if (_idController.value.text.isEmpty ||
                        _pwController.value.text.isEmpty) {
                      Fluttertoast.showToast(
                          msg: getTranslated(this.context, 'Pleasefillallfields'),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          textColor: Colors.white,
                          fontSize: 16.0);
                      _btnController.reset();
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => Meeting(
                          room: int.parse(_idController.text.toString()),
                          prefs: widget.prefs,
                          pin: _pwController.text,
                          isAudio: isSwitched,
                          defaultMute: check,
                        ),
                      ));
                      _btnController.reset();
                    }
                  },
                  child:  Text(getTranslated(this.context, 'createjoin'),
                      style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void setIntialValue() {
    _idController.text = widget.id;
    _pwController.text = widget.password;
    setState(() {});
  }
}
