import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corncall/Configs/Dbkeys.dart';
import 'package:corncall/Configs/Dbpaths.dart';
import 'package:corncall/Configs/Enum.dart';
import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Configs/optional_constants.dart';
import 'package:corncall/Models/DataModel.dart';
import 'package:corncall/Screens/call_history/callhistory.dart';
import 'package:corncall/Screens/chat_screen/chat.dart';
import 'package:corncall/Screens/recent_chats/RecentsChats.dart';
import 'package:corncall/Screens/recent_chats/widgets/getLastMessageTime.dart';
import 'package:corncall/Screens/recent_chats/widgets/getMediaMessage.dart';
import 'package:corncall/Services/Providers/SmartContactProviderWithLocalStoreData.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Utils/alias.dart';
import 'package:corncall/Utils/chat_controller.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:corncall/Utils/unawaited.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:corncall/Utils/late_load.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget getPersonalMessageTile(
    {required BuildContext context,
    required String currentUserNo,
    required SharedPreferences prefs,
    required DataModel cachedModel,
    var lastMessage,
    required var peer,
    required int unRead,
    peerSeenStatus,
    required var isPeerChatMuted,
    readFunction}) {
  //-- New context menu with Set Alias & Delete Chat tile
  showMenuForOneToOneChat(
      contextForDialog, Map<String, dynamic> targetUser, bool isMuted) {
    List<Widget> tiles = List.from(<Widget>[]);

    tiles.add(Builder(
        builder: (BuildContext popable) => ListTile(
            dense: true,
            leading: Icon(FontAwesomeIcons.userEdit, size: 18),
            title: Text(
              getTranslated(popable, 'setalias'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: pickTextColorBasedOnBgColorAdvanced(
                    Thm.isDarktheme(prefs)
                        ? corncallDIALOGColorDarkMode
                        : corncallDIALOGColorLightMode),
              ),
            ),
            onTap: () async {
              Navigator.of(popable).pop();

              showDialog(
                  context: context,
                  builder: (context) {
                    return AliasForm(targetUser, cachedModel, prefs);
                  });
            })));
    tiles.add(Builder(
        builder: (BuildContext popable) => ListTile(
            dense: true,
            leading:
                Icon(isMuted ? Icons.volume_up : Icons.volume_off, size: 22),
            title: Text(
              getTranslated(popable,
                  isMuted ? 'unmutenotifications' : 'mutenotifications'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: pickTextColorBasedOnBgColorAdvanced(
                    Thm.isDarktheme(prefs)
                        ? corncallDIALOGColorDarkMode
                        : corncallDIALOGColorLightMode),
              ),
            ),
            onTap: () async {
              Navigator.of(popable).pop();

              FirebaseFirestore.instance
                  .collection(DbPaths.collectionmessages)
                  .doc(Corncall.getChatId(currentUserNo, peer[Dbkeys.phone]))
                  .update({
                "$currentUserNo-muted": !isMuted,
              });
            })));
    if (IsShowDeleteChatOption == true) {
      tiles.add(Builder(
          builder: (BuildContext tilecontext) => ListTile(
              dense: true,
              leading: Icon(Icons.delete, size: 22),
              title: Text(
                getTranslated(tilecontext, 'deletethischat'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: pickTextColorBasedOnBgColorAdvanced(
                      Thm.isDarktheme(prefs)
                          ? corncallDIALOGColorDarkMode
                          : corncallDIALOGColorLightMode),
                ),
              ),
              onTap: () async {
                Navigator.of(tilecontext).pop();
                unawaited(showDialog(
                  builder: (BuildContext context) {
                    return Builder(
                        builder: (BuildContext popable) => AlertDialog(
                              backgroundColor: Thm.isDarktheme(prefs)
                                  ? corncallDIALOGColorDarkMode
                                  : corncallDIALOGColorLightMode,
                              title: new Text(
                                getTranslated(popable, 'deletethischat'),
                                style: TextStyle(
                                  color: pickTextColorBasedOnBgColorAdvanced(
                                      Thm.isDarktheme(prefs)
                                          ? corncallDIALOGColorDarkMode
                                          : corncallDIALOGColorLightMode),
                                ),
                              ),
                              content: new Text(
                                getTranslated(popable, 'suredelete'),
                                style: TextStyle(
                                  color: pickTextColorBasedOnBgColorAdvanced(
                                          Thm.isDarktheme(prefs)
                                              ? corncallDIALOGColorDarkMode
                                              : corncallDIALOGColorLightMode)
                                      .withOpacity(0.6),
                                ),
                              ),
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                  ),
                                  child: Text(
                                    getTranslated(popable, 'cancel'),
                                    style: TextStyle(
                                        color: corncallPRIMARYcolor,
                                        fontSize: 18),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                  ),
                                  child: Text(
                                    getTranslated(popable, 'delete'),
                                    style: TextStyle(
                                        color: corncallREDbuttonColor,
                                        fontSize: 18),
                                  ),
                                  onPressed: () async {
                                    Navigator.of(popable).pop();
                                    String chatId = Corncall.getChatId(
                                        currentUserNo,
                                        targetUser[Dbkeys.phone]);

                                    if (targetUser[Dbkeys.phone] != null) {

                                      await FirebaseFirestore.instance
                                          .collection(
                                              DbPaths.collectionmessages)
                                          .doc(chatId)
                                          .delete()
                                          .then((v) async {
                                        await FirebaseFirestore.instance
                                            .collection(DbPaths.collectionusers)
                                            .doc(currentUserNo)
                                            .collection(Dbkeys.chatsWith)
                                            .doc(Dbkeys.chatsWith)
                                            .set({
                                          targetUser[Dbkeys.phone]:
                                              FieldValue.delete(),
                                        }, SetOptions(merge: true));
                                        // print('DELETED CHAT DOC 1');

                                        await FirebaseFirestore.instance
                                            .collection(DbPaths.collectionusers)
                                            .doc(targetUser[Dbkeys.phone])
                                            .collection(Dbkeys.chatsWith)
                                            .doc(Dbkeys.chatsWith)
                                            .set({
                                          currentUserNo: FieldValue.delete(),
                                        }, SetOptions(merge: true));
                                      }).then((value) {});
                                    } else {
                                      Corncall.toast(
                                          'Error Occured. Could not delete !');
                                    }
                                  },
                                )
                              ],
                            ));
                  },
                  context: context,
                ));
              })));
    }
    showDialog(
        context: contextForDialog,
        builder: (contextForDialog) {
          return SimpleDialog(
              backgroundColor: Thm.isDarktheme(prefs)
                  ? corncallDIALOGColorDarkMode
                  : corncallDIALOGColorLightMode,
              children: tiles);
        });
  }

  return Column(
    children: [
      ListTile(
          contentPadding: EdgeInsets.fromLTRB(20, 0, 20, 0),
          onLongPress: () {
            showMenuForOneToOneChat(context, peer, isPeerChatMuted);
          },
          leading: Stack(
            children: [
              customCircleAvatar(url: peer[Dbkeys.photoUrl], radius: 22),
              peer[Dbkeys.lastSeen] == true ||
                      peer[Dbkeys.lastSeen] == currentUserNo
                  ? Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Thm.isDarktheme(prefs)
                            ? corncallCONTAINERboxColorDarkMode
                            : Colors.white,
                        radius: 8,
                        child: CircleAvatar(
                          backgroundColor: Color(0xff08cc8a),
                          radius: 6,
                        ),
                      ))
                  : SizedBox()
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              peer[Dbkeys.lastSeen] == currentUserNo
                  ? Text(
                      getTranslated(context, "typing"),
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: lightGrey,
                          fontSize: 14),
                    )
                  : lastMessage == null || lastMessage == {}
                      ? SizedBox(
                          width: 0,
                        )
                      : lastMessage![Dbkeys.from] != currentUserNo
                          ? SizedBox()
                          : lastMessage![Dbkeys.messageType] ==
                                  MessageType.text.index
                              ? readFunction == "" || readFunction == null
                                  ? SizedBox(
                                      width: 0,
                                    )
                                  : futureLoadString(
                                      future: readFunction,
                                      placeholder: SizedBox(
                                        width: 0,
                                      ),
                                      onfetchdone: (message) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
                                          child: Icon(
                                            Icons.done_all,
                                            size: 15,
                                            color: peerSeenStatus == null
                                                ? lightGrey
                                                : lastMessage == null ||
                                                        lastMessage == {}
                                                    ? lightGrey
                                                    : peerSeenStatus is bool
                                                        ? Colors.lightBlue
                                                        : peerSeenStatus >
                                                                lastMessage[Dbkeys
                                                                    .timestamp]
                                                            ? Colors.lightBlue
                                                            : lightGrey,
                                          ),
                                        );
                                      })
                              : Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.done_all,
                                    size: 15,
                                    color: peerSeenStatus == null
                                        ? lightGrey
                                        : lastMessage == null ||
                                                lastMessage == {}
                                            ? lightGrey
                                            : peerSeenStatus is bool
                                                ? Colors.lightBlue
                                                : peerSeenStatus >
                                                        lastMessage[
                                                            Dbkeys.timestamp]
                                                    ? Colors.lightBlue
                                                    : lightGrey,
                                  ),
                                ),
              peer[Dbkeys.lastSeen] == currentUserNo
                  ? SizedBox()
                  : lastMessage == null || lastMessage == {}
                      ? SizedBox()
                      : (currentUserNo == lastMessage[Dbkeys.from] &&
                                      lastMessage![Dbkeys.hasSenderDeleted]) ==
                                  true ||
                              (currentUserNo != lastMessage[Dbkeys.from] &&
                                  lastMessage![Dbkeys.hasRecipientDeleted])
                          ? Text(getTranslated(context, "msgdeleted"),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: unRead > 0
                                      ? Thm.isDarktheme(prefs)
                                          ? Color(0xff9aacb5)
                                          : darkGrey.withOpacity(0.4)
                                      : lightGrey.withOpacity(0.4),
                                  fontStyle: FontStyle.italic))
                          : lastMessage![Dbkeys.messageType] ==
                                  MessageType.text.index
                              ? readFunction == "" || readFunction == null
                                  ? SizedBox()
                                  : SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width / 3,
                                      child: futureLoadString(
                                          future: readFunction,
                                          placeholder: Text(""),
                                          onfetchdone: (message) {
                                            return Text(message,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: unRead > 0
                                                        ? FontWeight.w600
                                                        : FontWeight.normal,
                                                    color: unRead > 0
                                                        ? Thm.isDarktheme(prefs)
                                                            ? Color(0xff9aacb5)
                                                            : darkGrey
                                                        : lightGrey));
                                          }),
                                    )
                              : getMediaMessage(
                                  context, unRead > 0, lastMessage),
            ],
          ),
          title: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: IsShowUserFullNameAsSavedInYourContacts == false
                  ? Text(
                      Corncall.getNickname(peer) ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pickTextColorBasedOnBgColorAdvanced(
                            Thm.isDarktheme(prefs)
                                ? corncallBACKGROUNDcolorDarkMode
                                : corncallBACKGROUNDcolorLightMode),
                        fontWeight: FontWeight.w500,
                        fontSize: 16.4,
                        fontFamily: FONTFAMILY_NAME,
                      ),
                    )
                  : Consumer<SmartContactProviderWithLocalStoreData>(
                      builder: (context, availableContacts, _child) {
                      // _filtered = availableContacts.filtered;
                      return FutureBuilder<LocalUserData?>(
                          future:
                              availableContacts.fetchUserDataFromnLocalOrServer(
                                  prefs, peer[Dbkeys.phone]),
                          builder: (BuildContext context,
                              AsyncSnapshot<LocalUserData?> snapshot3) {
                            if (snapshot3.hasData && snapshot3.data != null) {
                              return Text(
                                snapshot3.data!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: pickTextColorBasedOnBgColorAdvanced(
                                      Thm.isDarktheme(prefs)
                                          ? corncallBACKGROUNDcolorDarkMode
                                          : corncallBACKGROUNDcolorLightMode),
                                 // fontWeight: FontWeight.w600,
                                  fontSize: 17.4,
                                  fontFamily: FONTFAMILY_NAME,
                                ),
                              );
                            }
                            return Text(
                              Corncall.getNickname(peer) ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: FONTFAMILY_NAME,
                                color: pickTextColorBasedOnBgColorAdvanced(
                                    Thm.isDarktheme(prefs)
                                        ? corncallBACKGROUNDcolorDarkMode
                                        : corncallBACKGROUNDcolorLightMode),
                                fontWeight: FontWeight.w500,
                                fontSize: 16.4,
                              ),
                            );
                          });
                    })),
          onTap: () {
            if (cachedModel.currentUser![Dbkeys.locked] != null &&
                cachedModel.currentUser![Dbkeys.locked]
                    .contains(peer[Dbkeys.phone])) {
              if (prefs.getString(Dbkeys.isPINsetDone) != currentUserNo ||
                  prefs.getString(Dbkeys.isPINsetDone) == null) {
                ChatController.unlockChat(
                    currentUserNo, peer[Dbkeys.phone] as String?);
                Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => new ChatScreen(
                            isSharingIntentForwarded: false,
                            prefs: prefs,
                            unread: unRead,
                            model: cachedModel,
                            currentUserNo: currentUserNo,
                            peerNo: peer[Dbkeys.phone] as String?)));
              } else {
                NavigatorState state = Navigator.of(context);
                ChatController.authenticate(
                    cachedModel, getTranslated(context, 'auth_neededchat'),
                    state: state,
                    shouldPop: false,
                    type: Corncall.getAuthenticationType(false, cachedModel),
                    prefs: prefs, onSuccess: () {
                  state.pushReplacement(new MaterialPageRoute(
                      builder: (context) => new ChatScreen(
                          isSharingIntentForwarded: false,
                          prefs: prefs,
                          unread: unRead,
                          model: cachedModel,
                          currentUserNo: currentUserNo,
                          peerNo: peer[Dbkeys.phone] as String?)));
                });
              }
            } else {
              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (context) => new ChatScreen(
                          isSharingIntentForwarded: false,
                          prefs: prefs,
                          unread: unRead,
                          model: cachedModel,
                          currentUserNo: currentUserNo,
                          peerNo: peer[Dbkeys.phone] as String?)));
            }
          },
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              lastMessage == {} || lastMessage == null
                  ? SizedBox()
                  : Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        getLastMessageTime(context, currentUserNo,
                            lastMessage[Dbkeys.timestamp]),
                        style: TextStyle(
                            color: unRead != 0 ? corncallOppositechatcolor : lightGrey,
                            fontWeight: FontWeight.w400,
                            fontFamily: FONTFAMILY_NAME,
                            fontSize: 11),
                      ),
                    ),
              SizedBox(
                height: 4,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  isPeerChatMuted
                      ? Icon(
                          Icons.volume_off,
                          size: 20,
                          color: lightGrey.withOpacity(0.5),
                        )
                      : Icon(
                          Icons.volume_up,
                          size: 20,
                          color: Colors.transparent,
                        ),
                  unRead == 0
                      ? SizedBox()
                      : Container(
                          margin:
                              EdgeInsets.only(left: isPeerChatMuted ? 7 : 0),
                          child: Text(unRead.toString(),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          padding: const EdgeInsets.all(7.0),
                          decoration: new BoxDecoration(
                            shape: BoxShape.circle,
                            color: corncallREDbuttonColor,
                          ),
                        ),
                ],
              ),
            ],
          )),
      Divider(
        height: 0,
      ),
    ],
  );
}
