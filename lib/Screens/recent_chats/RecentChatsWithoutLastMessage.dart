//*************   © Copyrighted by Criterion Tech. *********************

import 'dart:async';
import 'dart:core';
import 'package:corncall/Configs/optional_constants.dart';
import 'package:corncall/Screens/Broadcast/AddContactsToBroadcast.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/setStatusBarColor.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:corncall/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corncall/Configs/Dbkeys.dart';
import 'package:corncall/Configs/Dbpaths.dart';
import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Screens/Broadcast/BroadcastChatPage.dart';
import 'package:corncall/Screens/Groups/AddContactsToGroup.dart';
import 'package:corncall/Screens/Groups/GroupChatPage.dart';
import 'package:corncall/Screens/contact_screens/SmartContactsPage.dart';
import 'package:corncall/Services/Admob/admob.dart';
import 'package:corncall/Services/Providers/BroadcastProvider.dart';
import 'package:corncall/Services/Providers/GroupChatProvider.dart';
import 'package:corncall/Services/Providers/Observer.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Screens/chat_screen/utils/messagedata.dart';
import 'package:corncall/Screens/call_history/callhistory.dart';
import 'package:corncall/Screens/chat_screen/chat.dart';
import 'package:corncall/Models/DataModel.dart';
import 'package:corncall/Services/Providers/user_provider.dart';
import 'package:corncall/Utils/alias.dart';
import 'package:corncall/Utils/chat_controller.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:corncall/Utils/unawaited.dart';

class RecentChatsWithoutLastMessage extends StatefulWidget {
  RecentChatsWithoutLastMessage(
      {required this.currentUserNo,
      required this.isSecuritySetupDone,
      required this.prefs,
      key})
      : super(key: key);
  final String? currentUserNo;
  final SharedPreferences prefs;
  final bool isSecuritySetupDone;
  @override
  State createState() =>
      new RecentChatsWithoutLastMessageState(currentUserNo: this.currentUserNo);
}

class RecentChatsWithoutLastMessageState
    extends State<RecentChatsWithoutLastMessage> {
  RecentChatsWithoutLastMessageState({Key? key, this.currentUserNo}) {
    _filter.addListener(() {
      _userQuery.add(_filter.text.isEmpty ? '' : _filter.text);
    });
  }

  final TextEditingController _filter = new TextEditingController();
  bool isAuthenticating = false;

  List<StreamSubscription> unreadSubscriptions = [];

  List<StreamController> controllers = [];
  final BannerAd myBanner = BannerAd(
    adUnitId: getBannerAdUnitId()!,
    size: AdSize.banner,
    request: AdRequest(),
    listener: BannerAdListener(),
  );
  AdWidget? adWidget;

  @override
  void initState() {
    super.initState();
    Corncall.internetLookUp();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final observer = Provider.of<Observer>(this.context, listen: false);
      if (IsBannerAdShow == true && observer.isadmobshow == true) {
        myBanner.load();
        adWidget = AdWidget(ad: myBanner);
        setState(() {});
      }
    });
  }

  getuid(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    userProvider.getUserDetails(currentUserNo);
  }

  void cancelUnreadSubscriptions() {
    unreadSubscriptions.forEach((subscription) {
      subscription.cancel();
    });
  }

  DataModel? _cachedModel;
  bool showHidden = false, biometricEnabled = false;

  String? currentUserNo;

  bool isLoading = false;

  //-- New context menu with Set Alias & Delete Chat tile
  showMenuForOneToOneChat(
    contextForDialog,
    Map<String, dynamic> targetUser,
  ) {
    List<Widget> tiles = List.from(<Widget>[]);

    tiles.add(ListTile(
        dense: true,
        leading: Icon(FontAwesomeIcons.userEdit, size: 18),
        title: Text(
          getTranslated(contextForDialog, 'setalias'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: pickTextColorBasedOnBgColorAdvanced(
                Thm.isDarktheme(widget.prefs)
                    ? corncallDIALOGColorDarkMode
                    : corncallDIALOGColorLightMode),
          ),
        ),
        onTap: () async {
          Navigator.of(contextForDialog).pop();

          showDialog(
              context: context,
              builder: (context) {
                return AliasForm(targetUser, _cachedModel, widget.prefs);
              });
        }));
    if (IsShowDeleteChatOption == true) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.delete, size: 22),
          title: Text(
            getTranslated(contextForDialog, 'deletethischat'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: pickTextColorBasedOnBgColorAdvanced(
                  Thm.isDarktheme(widget.prefs)
                      ? corncallDIALOGColorDarkMode
                      : corncallDIALOGColorLightMode),
            ),
          ),
          onTap: () async {
            Navigator.of(contextForDialog).pop();
            unawaited(showDialog(
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Thm.isDarktheme(widget.prefs)
                      ? corncallDIALOGColorDarkMode
                      : corncallDIALOGColorLightMode,
                  title: new Text(
                    getTranslated(context, 'deletethischat'),
                    style: TextStyle(
                      color: pickTextColorBasedOnBgColorAdvanced(
                          Thm.isDarktheme(widget.prefs)
                              ? corncallDIALOGColorDarkMode
                              : corncallDIALOGColorLightMode),
                    ),
                  ),
                  content: new Text(
                    getTranslated(context, 'suredelete'),
                    style: TextStyle(
                      color: pickTextColorBasedOnBgColorAdvanced(
                              Thm.isDarktheme(widget.prefs)
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
                        getTranslated(context, 'cancel'),
                        style: TextStyle(
                            color: corncallPRIMARYcolor, fontSize: 18),
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
                        getTranslated(context, 'delete'),
                        style: TextStyle(
                            color: corncallREDbuttonColor, fontSize: 18),
                      ),
                      onPressed: () async {
                        String chatId = Corncall.getChatId(
                            currentUserNo!, targetUser[Dbkeys.phone]);

                        if (currentUserNo != null &&
                            targetUser[Dbkeys.phone] != null) {

                          await FirebaseFirestore.instance
                              .collection(DbPaths.collectionmessages)
                              .doc(chatId)
                              .delete()
                              .then((v) async {
                            await FirebaseFirestore.instance
                                .collection(DbPaths.collectionusers)
                                .doc(currentUserNo)
                                .collection(Dbkeys.chatsWith)
                                .doc(Dbkeys.chatsWith)
                                .set({
                              targetUser[Dbkeys.phone]: FieldValue.delete(),
                            }, SetOptions(merge: true));
                            // print('DELETED CHAT DOC 1');
                            await FirebaseFirestore.instance
                                .collection(DbPaths.collectionusers)
                                .doc(targetUser[Dbkeys.phone])
                                .collection(Dbkeys.chatsWith)
                                .doc(Dbkeys.chatsWith)
                                .set({
                              currentUserNo!: FieldValue.delete(),
                            }, SetOptions(merge: true));
                          }).then((value) {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushAndRemoveUntil(
                              // the new route
                              MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    CorncallWrapper(),
                              ),

                              (Route route) => false,
                            );
                            // unawaited(Navigator.pushReplacement(
                            //     this.context,
                            //     MaterialPageRoute(
                            //         builder: (newContext) =>
                            //             Homepage(
                            //               currentUserNo:
                            //                   currentUserNo,
                            //               isSecuritySetupDone: true,
                            //               prefs: widget.prefs,
                            //             ))));
                          });
                        } else {
                          Corncall.toast('Error Occured. Could not delete !');
                        }
                      },
                    )
                  ],
                );
              },
              context: context,
            ));
          }));
    }
    showDialog(
        context: contextForDialog,
        builder: (contextForDialog) {
          return SimpleDialog(
              backgroundColor: Thm.isDarktheme(widget.prefs)
                  ? corncallDIALOGColorDarkMode
                  : corncallDIALOGColorLightMode,
              children: tiles);
        });
  }

  showMenuForBroadcastChat(
    contextForDialog,
    var broadcastDoc,
  ) {
    List<Widget> tiles = List.from(<Widget>[]);

    tiles.add(ListTile(
        dense: true,
        leading: Icon(Icons.delete, size: 22),
        title: Text(
          getTranslated(contextForDialog, 'deletebroadcast'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: pickTextColorBasedOnBgColorAdvanced(
                Thm.isDarktheme(widget.prefs)
                    ? corncallDIALOGColorDarkMode
                    : corncallDIALOGColorLightMode),
          ),
        ),
        onTap: () async {
          Navigator.of(contextForDialog).pop();
          unawaited(showDialog(
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Thm.isDarktheme(widget.prefs)
                    ? corncallDIALOGColorDarkMode
                    : corncallDIALOGColorLightMode,
                title: new Text(
                  getTranslated(context, 'deletebroadcast'),
                  style: TextStyle(
                    color: pickTextColorBasedOnBgColorAdvanced(
                        Thm.isDarktheme(widget.prefs)
                            ? corncallDIALOGColorDarkMode
                            : corncallDIALOGColorLightMode),
                  ),
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                    ),
                    child: Text(
                      getTranslated(context, 'cancel'),
                      style:
                          TextStyle(color: corncallPRIMARYcolor, fontSize: 18),
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
                      getTranslated(context, 'delete'),
                      style: TextStyle(
                          color: corncallREDbuttonColor, fontSize: 18),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();

                      Future.delayed(const Duration(milliseconds: 500),
                          () async {
                        await FirebaseFirestore.instance
                            .collection(DbPaths.collectionbroadcasts)
                            .doc(broadcastDoc[Dbkeys.broadcastID])
                            .get()
                            .then((doc) async {
                          await doc.reference.delete();
                          //No need to delete the media data from here as it will be deleted automatically using Cloud functions deployed in Firebase once the .doc is deleted .
                        });
                      });
                    },
                  )
                ],
              );
            },
            context: context,
          ));
        }));

    showDialog(
        context: contextForDialog,
        builder: (contextForDialog) {
          return SimpleDialog(
              backgroundColor: Thm.isDarktheme(widget.prefs)
                  ? corncallDIALOGColorDarkMode
                  : corncallDIALOGColorLightMode,
              children: tiles);
        });
  }

  showMenuForGroupChat(contextForDialog, var groupDoc) {
    List<Widget> tiles = List.from(<Widget>[]);

    if (groupDoc[Dbkeys.groupCREATEDBY] == widget.currentUserNo) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.delete, size: 22),
          title: Text(
            getTranslated(context, 'deletegroup'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: pickTextColorBasedOnBgColorAdvanced(
                  Thm.isDarktheme(widget.prefs)
                      ? corncallDIALOGColorDarkMode
                      : corncallDIALOGColorLightMode),
            ),
          ),
          onTap: () async {
            Navigator.of(contextForDialog).pop();
            unawaited(showDialog(
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Thm.isDarktheme(widget.prefs)
                      ? corncallDIALOGColorDarkMode
                      : corncallDIALOGColorLightMode,
                  title: new Text(
                    getTranslated(context, 'deletegroup'),
                    style: TextStyle(
                      color: pickTextColorBasedOnBgColorAdvanced(
                          Thm.isDarktheme(widget.prefs)
                              ? corncallDIALOGColorDarkMode
                              : corncallDIALOGColorLightMode),
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        getTranslated(context, 'cancel'),
                        style: TextStyle(
                            color: corncallPRIMARYcolor, fontSize: 18),
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
                        getTranslated(context, 'delete'),
                        style: TextStyle(
                            color: corncallREDbuttonColor, fontSize: 18),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();

                        Future.delayed(const Duration(milliseconds: 500),
                            () async {
                          await FirebaseFirestore.instance
                              .collection(DbPaths.collectiongroups)
                              .doc(groupDoc[Dbkeys.groupID])
                              .get()
                              .then((doc) async {
                            await doc.reference.delete();
                            await FirebaseFirestore.instance
                                .collection(
                                    DbPaths.collectiontemptokensforunsubscribe)
                                .doc(groupDoc[Dbkeys.groupID])
                                .delete();
                          });

                          //No need to delete the media data from here as it will be deleted automatically using Cloud functions deployed in Firebase once the .doc is deleted .
                        });
                      },
                    )
                  ],
                );
              },
              context: context,
            ));
          }));
    } else {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.remove_circle_outlined, size: 22),
          title: Text(
            getTranslated(context, 'leavegroup'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: pickTextColorBasedOnBgColorAdvanced(
                  Thm.isDarktheme(widget.prefs)
                      ? corncallDIALOGColorDarkMode
                      : corncallDIALOGColorLightMode),
            ),
          ),
          onTap: () async {
            Navigator.of(contextForDialog).pop();
            unawaited(showDialog(
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Thm.isDarktheme(widget.prefs)
                      ? corncallDIALOGColorDarkMode
                      : corncallDIALOGColorLightMode,
                  title: new Text(
                    getTranslated(context, 'leavegroup'),
                    style: TextStyle(
                      color: pickTextColorBasedOnBgColorAdvanced(
                          Thm.isDarktheme(widget.prefs)
                              ? corncallDIALOGColorDarkMode
                              : corncallDIALOGColorLightMode),
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        getTranslated(context, 'cancel'),
                        style: TextStyle(
                            color: corncallPRIMARYcolor, fontSize: 18),
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
                        getTranslated(context, 'leave'),
                        style: TextStyle(
                            color: corncallREDbuttonColor, fontSize: 18),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        Future.delayed(const Duration(milliseconds: 300),
                            () async {
                          DateTime time = DateTime.now();
                          try {
                            await FirebaseFirestore.instance
                                .collection(
                                    DbPaths.collectiontemptokensforunsubscribe)
                                .doc(widget.currentUserNo)
                                .delete();
                          } catch (err) {}
                          await FirebaseFirestore.instance
                              .collection(
                                  DbPaths.collectiontemptokensforunsubscribe)
                              .doc(widget.currentUserNo)
                              .set({
                            Dbkeys.groupIDfiltered:
                                '${groupDoc[Dbkeys.groupID].replaceAll(RegExp('-'), '').substring(1, groupDoc[Dbkeys.groupID].replaceAll(RegExp('-'), '').toString().length)}',
                            Dbkeys.notificationTokens: _cachedModel!
                                    .currentUser![Dbkeys.notificationTokens] ??
                                [],
                            'type': 'unsubscribe'
                          }).then((value) async {
                            await FirebaseFirestore.instance
                                .collection(DbPaths.collectiongroups)
                                .doc(groupDoc[Dbkeys.groupID])
                                .update(groupDoc[Dbkeys.groupADMINLIST]
                                        .contains(widget.currentUserNo)
                                    ? {
                                        Dbkeys.groupADMINLIST:
                                            FieldValue.arrayRemove(
                                                [widget.currentUserNo]),
                                        Dbkeys.groupMEMBERSLIST:
                                            FieldValue.arrayRemove(
                                                [widget.currentUserNo]),
                                        widget.currentUserNo!:
                                            FieldValue.delete(),
                                        '${widget.currentUserNo}-joinedOn':
                                            FieldValue.delete()
                                      }
                                    : {
                                        Dbkeys.groupMEMBERSLIST:
                                            FieldValue.arrayRemove(
                                                [widget.currentUserNo]),
                                        widget.currentUserNo!:
                                            FieldValue.delete(),
                                        '${widget.currentUserNo}-joinedOn':
                                            FieldValue.delete()
                                      });

                            await FirebaseFirestore.instance
                                .collection(DbPaths.collectiongroups)
                                .doc(groupDoc[Dbkeys.groupID])
                                .collection(DbPaths.collectiongroupChats)
                                .doc(time.millisecondsSinceEpoch.toString() +
                                    '--' +
                                    groupDoc[Dbkeys.groupID])
                                .set({
                              Dbkeys.groupmsgCONTENT:
                                  '${widget.currentUserNo} ${getTranslated(context, 'leftthegroup')}',
                              Dbkeys.groupmsgLISToptional: [],
                              Dbkeys.groupmsgTIME: time.millisecondsSinceEpoch,
                              Dbkeys.groupmsgSENDBY: widget.currentUserNo,
                              Dbkeys.groupmsgISDELETED: false,
                              Dbkeys.groupmsgTYPE:
                                  Dbkeys.groupmsgTYPEnotificationUserLeft,
                            });

                            try {
                              await FirebaseFirestore.instance
                                  .collection(DbPaths
                                      .collectiontemptokensforunsubscribe)
                                  .doc(widget.currentUserNo)
                                  .delete();
                            } catch (err) {}
                          }).catchError((err) {

                          });
                        });
                      },
                    )
                  ],
                );
              },
              context: context,
            ));
          }));
    }
    showDialog(
        context: contextForDialog,
        builder: (contextForDialog) {
          return SimpleDialog(
              backgroundColor: Thm.isDarktheme(widget.prefs)
                  ? corncallDIALOGColorDarkMode
                  : corncallDIALOGColorLightMode,
              children: tiles);
        });
  }

  Widget buildItem(BuildContext context, Map<String, dynamic> user) {
    if (user[Dbkeys.phone] == currentUserNo) {
      return Container(width: 0, height: 0);
    } else {
      return StreamBuilder(
        stream: getUnread(user).asBroadcastStream(),
        builder: (context, AsyncSnapshot<MessageData> unreadData) {
          int unread = unreadData.hasData &&
                  unreadData.data!.snapshot.docs.isNotEmpty
              ? unreadData.data!.snapshot.docs
                  .where((t) => t[Dbkeys.timestamp] > unreadData.data!.lastSeen)
                  .length
              : 0;
          return Column(
            children: [
              ListTile(
                  contentPadding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                  onLongPress: () {
                    showMenuForOneToOneChat(context, user);
                  },
                  leading: customCircleAvatar(
                      url: user[Dbkeys.photoUrl], radius: 22),
                  title: Text(
                    Corncall.getNickname(user)!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: corncallBlack,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    if (_cachedModel!.currentUser![Dbkeys.locked] != null &&
                        _cachedModel!.currentUser![Dbkeys.locked]
                            .contains(user[Dbkeys.phone])) {
                      if (widget.prefs.getString(Dbkeys.isPINsetDone) !=
                              currentUserNo ||
                          widget.prefs.getString(Dbkeys.isPINsetDone) == null) {
                        ChatController.unlockChat(
                            currentUserNo, user[Dbkeys.phone] as String?);
                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => new ChatScreen(
                                    isSharingIntentForwarded: false,
                                    prefs: widget.prefs,
                                    unread: unread,
                                    model: _cachedModel!,
                                    currentUserNo: currentUserNo,
                                    peerNo: user[Dbkeys.phone] as String?)));
                      } else {
                        NavigatorState state = Navigator.of(context);
                        ChatController.authenticate(_cachedModel!,
                            getTranslated(context, 'auth_neededchat'),
                            state: state,
                            shouldPop: false,
                            type: Corncall.getAuthenticationType(
                                biometricEnabled, _cachedModel),
                            prefs: widget.prefs, onSuccess: () {
                          state.pushReplacement(new MaterialPageRoute(
                              builder: (context) => new ChatScreen(
                                  isSharingIntentForwarded: false,
                                  prefs: widget.prefs,
                                  unread: unread,
                                  model: _cachedModel!,
                                  currentUserNo: currentUserNo,
                                  peerNo: user[Dbkeys.phone] as String?)));
                        });
                      }
                    } else {
                      Navigator.push(
                          context,
                          new MaterialPageRoute(
                              builder: (context) => new ChatScreen(
                                  isSharingIntentForwarded: false,
                                  prefs: widget.prefs,
                                  unread: unread,
                                  model: _cachedModel!,
                                  currentUserNo: currentUserNo,
                                  peerNo: user[Dbkeys.phone] as String?)));
                    }
                  },
                  trailing: unread != 0
                      ? Container(
                          child: Text(unread.toString(),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          padding: const EdgeInsets.all(7.0),
                          decoration: new BoxDecoration(
                            shape: BoxShape.circle,
                            color: user[Dbkeys.lastSeen] == true
                                ? Colors.red[400]
                                : Colors.blue[400],
                          ),
                        )
                      : user[Dbkeys.lastSeen] == true
                          ? Container(
                              child: Container(width: 0, height: 0),
                              padding: const EdgeInsets.all(7.0),
                              decoration: new BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red[400]),
                            )
                          : SizedBox(
                              height: 0,
                              width: 0,
                            )),
              Divider(
                height: 0,
              ),
            ],
          );
        },
      );
    }
  }

  Stream<MessageData> getUnread(Map<String, dynamic> user) {
    String chatId = Corncall.getChatId(currentUserNo!, user[Dbkeys.phone]);
    var controller = StreamController<MessageData>.broadcast();
    unreadSubscriptions.add(FirebaseFirestore.instance
        .collection(DbPaths.collectionmessages)
        .doc(chatId)
        .snapshots()
        .listen((doc) {
      if (doc[currentUserNo!] != null && doc[currentUserNo!] is int) {
        unreadSubscriptions.add(FirebaseFirestore.instance
            .collection(DbPaths.collectionmessages)
            .doc(chatId)
            .collection(chatId)
            .snapshots()
            .listen((snapshot) {
          controller.add(
              MessageData(snapshot: snapshot, lastSeen: doc[currentUserNo!]));
        }));
      }
    }));
    controllers.add(controller);
    return controller.stream;
  }

  _isHidden(phoneNo) {
    Map<String, dynamic> _currentUser = _cachedModel!.currentUser!;
    return _currentUser[Dbkeys.hidden] != null &&
        _currentUser[Dbkeys.hidden].contains(phoneNo);
  }

  StreamController<String> _userQuery =
      new StreamController<String>.broadcast();

  List<Map<String, dynamic>> _streamDocSnap = [];

  _chats(Map<String?, Map<String, dynamic>?> _userData,
      Map<String, dynamic>? currentUser) {
    return Consumer<List<GroupModel>>(
        builder: (context, groupList, _child) => Consumer<List<BroadcastModel>>(
                builder: (context, broadcastList, _child) {
              _streamDocSnap = Map.from(_userData)
                  .values
                  .where((_user) => _user.keys.contains(Dbkeys.chatStatus))
                  .toList()
                  .cast<Map<String, dynamic>>();
              Map<String?, int?> _lastSpokenAt = _cachedModel!.lastSpokenAt;
              List<Map<String, dynamic>> filtered =
                  List.from(<Map<String, dynamic>>[]);
              groupList.forEach((element) {
                _streamDocSnap.add(element.docmap);
              });
              broadcastList.forEach((element) {
                _streamDocSnap.add(element.docmap);
              });
              _streamDocSnap.sort((a, b) {
                int aTimestamp = a.containsKey(Dbkeys.groupISTYPINGUSERID)
                    ? a[Dbkeys.groupLATESTMESSAGETIME]
                    : a.containsKey(Dbkeys.broadcastBLACKLISTED)
                        ? a[Dbkeys.broadcastLATESTMESSAGETIME]
                        : _lastSpokenAt[a[Dbkeys.phone]] ?? 0;
                int bTimestamp = b.containsKey(Dbkeys.groupISTYPINGUSERID)
                    ? b[Dbkeys.groupLATESTMESSAGETIME]
                    : b.containsKey(Dbkeys.broadcastBLACKLISTED)
                        ? b[Dbkeys.broadcastLATESTMESSAGETIME]
                        : _lastSpokenAt[b[Dbkeys.phone]] ?? 0;
                return bTimestamp - aTimestamp;
              });

              if (!showHidden) {
                _streamDocSnap.removeWhere((_user) =>
                    !_user.containsKey(Dbkeys.groupISTYPINGUSERID) &&
                    !_user.containsKey(Dbkeys.broadcastBLACKLISTED) &&
                    _isHidden(_user[Dbkeys.phone]));
              }

              return ListView(
                physics: const BouncingScrollPhysics(
                    parent: BouncingScrollPhysics()),
                shrinkWrap: true,
                children: [
                  Container(
                      child: _streamDocSnap.isNotEmpty
                          ? StreamBuilder(
                              stream: _userQuery.stream.asBroadcastStream(),
                              builder: (context, snapshot) {
                                if (_filter.text.isNotEmpty ||
                                    snapshot.hasData) {
                                  filtered = this._streamDocSnap.where((user) {
                                    return user[Dbkeys.nickname]
                                        .toLowerCase()
                                        .trim()
                                        .contains(new RegExp(r'' +
                                            _filter.text.toLowerCase().trim() +
                                            ''));
                                  }).toList();
                                  if (filtered.isNotEmpty)
                                    return ListView.builder(
                                      physics: BouncingScrollPhysics(),
                                      shrinkWrap: true,
                                      padding: EdgeInsets.all(10.0),
                                      itemBuilder: (context, index) =>
                                          buildItem(context,
                                              filtered.elementAt(index)),
                                      itemCount: filtered.length,
                                    );
                                  else
                                    return ListView(
                                        physics: BouncingScrollPhysics(),
                                        shrinkWrap: true,
                                        children: [
                                          Padding(
                                              padding: EdgeInsets.only(
                                                  top: MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      3.5),
                                              child: Center(
                                                child: Text(
                                                    getTranslated(context,
                                                        'nosearchresult'),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: corncallGrey,
                                                    )),
                                              ))
                                        ]);
                                }
                                return ListView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: EdgeInsets.fromLTRB(0, 10, 0, 120),
                                  itemBuilder: (context, index) {
                                    if (_streamDocSnap[index].containsKey(
                                        Dbkeys.groupISTYPINGUSERID)) {
                                      ///----- Build Group Chat Tile ----
                                      return Column(
                                        children: [
                                          ListTile(
                                            onLongPress: () {
                                              showMenuForGroupChat(context,
                                                  _streamDocSnap[index]);
                                            },
                                            contentPadding: EdgeInsets.fromLTRB(
                                                20, 0, 20, 0),
                                            leading: customCircleAvatarGroup(
                                                url: _streamDocSnap[index]
                                                    [Dbkeys.groupPHOTOURL],
                                                radius: 22),
                                            title: Text(
                                              _streamDocSnap[index]
                                                  [Dbkeys.groupNAME],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: corncallBlack,
                                                fontSize: 16,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${_streamDocSnap[index][Dbkeys.groupMEMBERSLIST].length} ${getTranslated(context, 'participants')}',
                                              style: TextStyle(
                                                color: corncallGrey,
                                                fontSize: 14,
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  new MaterialPageRoute(
                                                      builder: (context) => new GroupChatPage(
                                                          isCurrentUserMuted: _streamDocSnap[index]
                                                                  .containsKey(Dbkeys
                                                                      .groupMUTEDMEMBERS)
                                                              ? _streamDocSnap[index][Dbkeys.groupMUTEDMEMBERS]
                                                                  .contains(
                                                                      currentUserNo)
                                                              : false,
                                                          isSharingIntentForwarded:
                                                              false,
                                                          model: _cachedModel!,
                                                          prefs: widget.prefs,
                                                          joinedTime:
                                                              _streamDocSnap[index][
                                                                  '${widget.currentUserNo}-joinedOn'],
                                                          currentUserno: widget
                                                              .currentUserNo!,
                                                          groupID:
                                                              _streamDocSnap[index]
                                                                  [Dbkeys.groupID])));
                                            },
                                            trailing: StreamBuilder(
                                              stream: FirebaseFirestore.instance
                                                  .collection(
                                                      DbPaths.collectiongroups)
                                                  .doc(_streamDocSnap[index]
                                                      [Dbkeys.groupID])
                                                  .collection(DbPaths
                                                      .collectiongroupChats)
                                                  .where(Dbkeys.groupmsgTIME,
                                                      isGreaterThan:
                                                          _streamDocSnap[index][
                                                              widget
                                                                  .currentUserNo])
                                                  .snapshots(),
                                              builder: (BuildContext context,
                                                  AsyncSnapshot<
                                                          QuerySnapshot<
                                                              dynamic>>
                                                      snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return SizedBox(
                                                    height: 0,
                                                    width: 0,
                                                  );
                                                } else if (snapshot.hasData &&
                                                    snapshot.data!.docs.length >
                                                        0) {
                                                  return Container(
                                                    child: Text(
                                                        '${snapshot.data!.docs.length}',
                                                        style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            7.0),
                                                    decoration:
                                                        new BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.blue[400],
                                                    ),
                                                  );
                                                }
                                                return SizedBox(
                                                  height: 0,
                                                  width: 0,
                                                );
                                              },
                                            ),
                                          ),
                                          Divider(
                                            height: 0,
                                          ),
                                        ],
                                      );
                                    } else if (_streamDocSnap[index]
                                        .containsKey(
                                            Dbkeys.broadcastBLACKLISTED)) {
                                      ///----- Build Broadcast Chat Tile ----
                                      return Column(
                                        children: [
                                          ListTile(
                                            onLongPress: () {
                                              showMenuForBroadcastChat(context,
                                                  _streamDocSnap[index]);
                                            },
                                            contentPadding: EdgeInsets.fromLTRB(
                                                20, 0, 20, 0),
                                            leading:
                                                customCircleAvatarBroadcast(
                                                    url: _streamDocSnap[index][
                                                        Dbkeys
                                                            .broadcastPHOTOURL],
                                                    radius: 22),
                                            title: Text(
                                              _streamDocSnap[index]
                                                  [Dbkeys.broadcastNAME],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: corncallBlack,
                                                fontSize: 16,
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${_streamDocSnap[index][Dbkeys.broadcastMEMBERSLIST].length} ${getTranslated(context, 'recipients')}',
                                              style: TextStyle(
                                                color: corncallGrey,
                                                fontSize: 14,
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  new MaterialPageRoute(
                                                      builder: (context) =>
                                                          new BroadcastChatPage(
                                                              model:
                                                                  _cachedModel!,
                                                              prefs:
                                                                  widget.prefs,
                                                              currentUserno: widget
                                                                  .currentUserNo!,
                                                              broadcastID:
                                                                  _streamDocSnap[
                                                                          index]
                                                                      [Dbkeys
                                                                          .broadcastID])));
                                            },
                                          ),
                                          Divider(height: 0),
                                        ],
                                      );
                                    } else {
                                      return buildItem(context,
                                          _streamDocSnap.elementAt(index));
                                    }
                                  },
                                  itemCount: _streamDocSnap.length,
                                );
                              })
                          : ListView(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              padding: EdgeInsets.all(0),
                              children: [
                                  Padding(
                                      padding: EdgeInsets.only(
                                          top: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              3.5),
                                      child: Center(
                                        child: Padding(
                                            padding: EdgeInsets.all(30.0),
                                            child: Text(
                                                groupList.length != 0
                                                    ? ''
                                                    : getTranslated(
                                                        context, 'startchat'),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  height: 1.59,
                                                  color: corncallGrey,
                                                ))),
                                      ))
                                ])),
                ],
              );
            }));
  }

  Widget buildGroupitem() {
    return Text(
      Dbkeys.groupNAME,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  DataModel? getModel() {
    _cachedModel ??= DataModel(currentUserNo);
    return _cachedModel;
  }

  @override
  void dispose() {
    super.dispose();

    if (IsBannerAdShow == true) {
      myBanner.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final observer = Provider.of<Observer>(this.context, listen: false);
    setStatusBarColor(widget.prefs);
    return Corncall.getNTPWrappedWidget(ScopedModel<DataModel>(
      model: getModel()!,
      child:
          ScopedModelDescendant<DataModel>(builder: (context, child, _model) {
        _cachedModel = _model;
        return Scaffold(
          // bottomSheet: IsBannerAdShow == true &&
          //         observer.isadmobshow == true &&
          //         adWidget != null
          //     ? Container(
          //         height: 60,
          //         margin: EdgeInsets.only(
          //             bottom: Platform.isIOS == true ? 25.0 : 5, top: 0),
          //         child: Center(child: adWidget),
          //       )
          //     : SizedBox(
          //         height: 0,
          //       ),
          backgroundColor: corncallWhite,
          floatingActionButton: Padding(
            padding: EdgeInsets.only(bottom: 0
                // bottom: IsBannerAdShow == true && observer.isadmobshow == true
                //     ? 60
                //     : 0
                ),
            child: FloatingActionButton(
                heroTag: "sdfweewfwq123sdasfw",
                backgroundColor: corncallSECONDARYolor,
                child: Icon(
                  Icons.chat,
                  size: 30.0,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (context) => new SmartContactsPage(
                              onTapCreateBroadcast: () {
                                if (observer.isAllowCreatingBroadcasts ==
                                    false) {
                                  Corncall.showRationale(
                                      getTranslated(this.context, 'disabled'));
                                } else {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              AddContactsToBroadcast(
                                                currentUserNo:
                                                    widget.currentUserNo,
                                                model: _cachedModel,
                                                biometricEnabled: false,
                                                prefs: widget.prefs,
                                                isAddingWhileCreatingBroadcast:
                                                    true,
                                              )));
                                }
                              },
                              onTapCreateGroup: () {
                                if (observer.isAllowCreatingGroups == false) {
                                  Corncall.showRationale(
                                      getTranslated(this.context, 'disabled'));
                                } else {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              AddContactsToGroup(
                                                currentUserNo:
                                                    widget.currentUserNo,
                                                model: _cachedModel,
                                                biometricEnabled: false,
                                                prefs: widget.prefs,
                                                isAddingWhileCreatingGroup:
                                                    true,
                                              )));
                                }
                              },
                              prefs: widget.prefs,
                              biometricEnabled: biometricEnabled,
                              currentUserNo: currentUserNo!,
                              model: _cachedModel!)));
                }),
          ),
          body: RefreshIndicator(
            onRefresh: () {
              isAuthenticating = !isAuthenticating;
              setState(() {
                showHidden = !showHidden;
              });
              return Future.value(true);
            },
            child: _chats(_model.userData, _model.currentUser),
          ),
        );
      }),
    ));
  }
}
