//*************   © Copyrighted by Criterion Tech. *********************

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:corncall/Configs/Dbkeys.dart';
import 'package:corncall/Configs/Dbpaths.dart';
import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:corncall/widgets/MyElevatedButton/MyElevatedButton.dart';
import 'package:corncall/widgets/Passcode/passcode_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Security extends StatefulWidget {
  final String? phoneNo, answer, title;
  final bool setPasscode, shouldPop;
  final SharedPreferences prefs;
  final Function onSuccess;

  Security(this.phoneNo,
      {this.shouldPop = false,
      this.setPasscode = false,
      this.answer,
      required this.title,
      required this.prefs,
      required this.onSuccess});

  @override
  _SecurityState createState() => _SecurityState();
}

class _SecurityState extends State<Security> {
  final StreamController<bool> _verificationNotifier =
      StreamController<bool>.broadcast();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  String? _passCode;

  @override
  Widget build(BuildContext context) {
    return Corncall.getNTPWrappedWidget(Stack(children: [
      Scaffold(
          backgroundColor: Thm.isDarktheme(widget.prefs)
              ? corncallBACKGROUNDcolorDarkMode
              : corncallBACKGROUNDcolorLightMode,
          appBar: AppBar(
            leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back,
                  color: pickTextColorBasedOnBgColorAdvanced(
                      Thm.isDarktheme(widget.prefs)
                          ? corncallAPPBARcolorDarkMode
                          : corncallAPPBARcolorLightMode),
                )),
            elevation: 0.4,
            title: Text(
              widget.title!,
              style: TextStyle(
                  color: pickTextColorBasedOnBgColorAdvanced(
                      Thm.isDarktheme(widget.prefs)
                          ? corncallAPPBARcolorDarkMode
                          : corncallAPPBARcolorLightMode)),
            ),
          ),
          bottomSheet: Container(
            margin: EdgeInsets.only(bottom: Platform.isIOS ? 15 : 0),
            height: 67,
            width: MediaQuery.of(this.context).size.width,
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: myElevatedButton(
                  color: corncallPRIMARYcolor,
                  child: Text(
                    getTranslated(this.context, 'done'),
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    if (widget.setPasscode) {
                      if (_passCode == null)
                        Corncall.toast(
                            getTranslated(this.context, 'setpasscode'));
                      if (
                          // ignore: todo
                          //TODO://----REMOVE BELOW COMMENT TO ASK SECURITY QUESTION SET----
                          // _formKey.currentState.validate() &&

                          _passCode != null) {
                        var data = {

                          Dbkeys.passcode: Corncall.getHashedString(_passCode!)
                        };
                        setState(() {
                          isLoading = true;
                        });
                        widget.prefs.setInt(Dbkeys.passcodeTries, 0);
                        widget.prefs.setInt(Dbkeys.answerTries, 0);
                        FirebaseFirestore.instance
                            .collection(DbPaths.collectionusers)
                            .doc(widget.phoneNo)
                            .update(data)
                            .then((_) {

                          widget.onSuccess(this.context);
                        });
                      }
                      widget.prefs
                          .setString(Dbkeys.isPINsetDone, widget.phoneNo!);
                    } else {
                      if (_formKey.currentState!.validate()) {
                        var data = {
                          // ignore: todo
                          //TODO://----REMOVE BELOW COMMENT TO ASK SECURITY QUESTION SET----

                        };
                        setState(() {
                          isLoading = true;
                        });
                        widget.prefs.setInt(Dbkeys.passcodeTries, 0);
                        widget.prefs.setInt(Dbkeys.answerTries, 0);
                        FirebaseFirestore.instance
                            .collection(DbPaths.collectionusers)
                            .doc(widget.phoneNo)
                            .update(data as Map<String, Object?>)
                            .then((_) {
                          widget.onSuccess(this.context);
                          widget.prefs
                              .setString(Dbkeys.isPINsetDone, widget.phoneNo!);
                        });
                      }
                    }
                  },
                )),
          ),
          body: SingleChildScrollView(
              child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  widget.setPasscode
                      ? ListTile(
                          trailing: Icon(Icons.check_circle,
                              color: _passCode == null
                                  ? corncallGrey
                                  : corncallPRIMARYcolor,
                              size: 35),
                          title: myElevatedButton(
                            color: corncallPRIMARYcolor,
                            child: Text(
                              getTranslated(this.context, 'setpass'),
                              style: TextStyle(
                                color: pickTextColorBasedOnBgColorAdvanced(
                                    corncallPRIMARYcolor),
                              ),
                            ),
                            onPressed: _showLockScreen,
                          ))
                      : SizedBox(),
                  widget.setPasscode ? SizedBox(height: 20) : SizedBox(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ))),
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
    ]));
  }

  _onPasscodeEntered(String enteredPasscode) {
    bool isValid = enteredPasscode.length == 4;
    _verificationNotifier.add(isValid);
    _passCode = null;
    if (isValid)
      setState(() {
        _passCode = enteredPasscode;
      });
  }

  _showLockScreen() {
    Navigator.push(
        context,
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) =>
              PasscodeScreen(
            prefs: widget.prefs,
            onSubmit: null,
            wait: true,
            authentication: false,
            passwordDigits: 4,
            title: (getTranslated(this.context, 'enterpass')),
            passwordEnteredCallback: _onPasscodeEntered,
            cancelLocalizedText: getTranslated(this.context, 'cancel'),
            deleteLocalizedText: getTranslated(this.context, 'delete'),
            shouldTriggerVerification: _verificationNotifier.stream,
          ),
        ));
  }
}
