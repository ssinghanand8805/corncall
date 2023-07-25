//*************   © Copyrighted by Criterion Tech. *********************

import 'dart:math';
import 'package:corncall/Screens/calling_screen/audio_call.dart';
import 'package:corncall/Screens/calling_screen/video_call.dart';
import 'package:flutter/material.dart';
import 'package:corncall/Models/call.dart';
import 'package:corncall/Models/call_methods.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallUtils {
  static final CallMethods callMethods = CallMethods();

  static dial(
      {String? fromUID,
        String? fromFullname,
        String? fromDp,
        String? toFullname,
        String? toDp,
        String? toUID,
        bool? isvideocall,
        required String? currentuseruid,
        required SharedPreferences prefs,
        context}) async {
    print("##############");
    int timeepoch = DateTime.now().millisecondsSinceEpoch;
    Call call = Call(
        timeepoch: timeepoch,
        callerId: fromUID,
        callerName: fromFullname,
        callerPic: fromDp,
        receiverId: toUID,
        receiverName: toFullname,
        receiverPic: toDp,
        channelId: isvideocall! ? '116' : Random().nextInt(1000).toString(),
        isvideocall: isvideocall,
        agoraToken: ''
    );
    bool callMade = await callMethods.makeCall(
        call: call, isvideocall: isvideocall, timeepoch: timeepoch);

    call.hasDialled = true;
    if (isvideocall == false) {
      if (callMade) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioCall(
              prefs: prefs,
              currentuseruid: currentuseruid,
              call: call,
              channelName: call.channelId,
            ),
          ),
        );
      }
    } else {
      if (callMade) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCall(
              prefs: prefs,
              currentuseruid: currentuseruid!,
              call: call,
              channelName: call.channelId!,
            ),
          ),
        );
      }
    }
  }


  static dialDuringCall(
      {String? fromUID,
        String? fromFullname,
        String? fromDp,
        String? toFullname,
        String? toDp,
        String? toUID,
        bool? isvideocall,
        required String? currentuseruid,
        required SharedPreferences prefs,
        context}) async {
    print("##############");
    int timeepoch = DateTime.now().millisecondsSinceEpoch;
    Call call = Call(
        timeepoch: timeepoch,
        callerId: fromUID,
        callerName: fromFullname,
        callerPic: fromDp,
        receiverId: toUID,
        receiverName: toFullname,
        receiverPic: toDp,
        channelId: isvideocall! ? '116' : Random().nextInt(1000).toString(),
        isvideocall: isvideocall,
        agoraToken: ''
    );

    bool callMade = await callMethods.makeCallDuringCall(
        call: call, isvideocall: isvideocall, timeepoch: timeepoch);


  }


  static endCallForSpecficUser(
      {String? userId,
        context}) async {

    bool isCallEnd = await callMethods.endCallForSpecficUser(userId: userId!);


  }

}
