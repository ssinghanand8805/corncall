// //*************   © Copyrighted by Criterion Tech. *********************

import 'package:corncall/Configs/Dbkeys.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:flutter/material.dart';

Map getTranslateNotificationStringsMap(BuildContext context) {
  Map map = {
    Dbkeys.notificationStringNewTextMessage: getTranslated(context, 'ntm'),
    Dbkeys.notificationStringNewImageMessage: getTranslated(context, 'nim'),
    Dbkeys.notificationStringNewVideoMessage: getTranslated(context, 'nvm'),
    Dbkeys.notificationStringNewAudioMessage: getTranslated(context, 'nam'),
    Dbkeys.notificationStringNewContactMessage: getTranslated(context, 'ncm'),
    Dbkeys.notificationStringNewDocumentMessage: getTranslated(context, 'ndm'),
    Dbkeys.notificationStringNewLocationMessage: getTranslated(context, 'nlm'),
    Dbkeys.notificationStringNewIncomingAudioCall:
        getTranslated(context, 'niac'),
    Dbkeys.notificationStringNewIncomingVideoCall:
        getTranslated(context, 'nivc'),
    Dbkeys.notificationStringCallEnded: getTranslated(context, 'ce'),
    Dbkeys.notificationStringMissedCall: getTranslated(context, 'mc'),
    Dbkeys.notificationStringAcceptOrRejectCall: getTranslated(context, 'aorc'),
    Dbkeys.notificationStringCallRejected: getTranslated(context, 'cr'),
  };
  return map;
}
