//*************   © Copyrighted by Criterion Tech. *********************

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corncall/Configs/Dbkeys.dart';
import 'package:corncall/Configs/Dbpaths.dart';
import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Screens/Groups/GroupChatPage.dart';
import 'package:corncall/Screens/call_history/callhistory.dart';
import 'package:corncall/Screens/calling_screen/pickup_layout.dart';
import 'package:corncall/Screens/chat_screen/chat.dart';
import 'package:corncall/Services/Providers/SmartContactProviderWithLocalStoreData.dart';
import 'package:corncall/Services/Providers/GroupChatProvider.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Models/DataModel.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectContactToShare extends StatefulWidget {
  const SelectContactToShare({
    required this.currentUserNo,
    required this.model,
    required this.prefs,
    required this.sharedFiles,
    this.sharedText,
  });
  final String? currentUserNo;
  final DataModel model;
  final SharedPreferences prefs;
  final List<SharedMediaFile> sharedFiles;
  final String? sharedText;

  @override
  _SelectContactToShareState createState() => new _SelectContactToShareState();
}

class _SelectContactToShareState extends State<SelectContactToShare>
    with AutomaticKeepAliveClientMixin {
  GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
  Map<String?, String?>? contacts;
  bool isGroupsloading = true;
  var joinedGroupsList = [];
  @override
  bool get wantKeepAlive => true;

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  @override
  void initState() {
    super.initState();
    fetchJoinedGroups();
  }

  fetchJoinedGroups() async {
    await FirebaseFirestore.instance
        .collection(DbPaths.collectiongroups)
        .where(Dbkeys.groupMEMBERSLIST, arrayContains: widget.currentUserNo)
        .orderBy(Dbkeys.groupCREATEDON, descending: true)
        .get()
        .then((groupsList) {
      if (groupsList.docs.length > 0) {
        groupsList.docs.forEach((group) {
          joinedGroupsList.add(group);
          if (groupsList.docs.last[Dbkeys.groupID] == group[Dbkeys.groupID]) {
            isGroupsloading = false;
          }
          setState(() {});
        });
      } else {
        isGroupsloading = false;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  loading() {
    return Stack(children: [
      Container(
        child: Center(
            child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(corncallSECONDARYolor),
        )),
      )
    ]);
  }

  int currentUploadingIndex = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PickupLayout(
        prefs: widget.prefs,
        scaffold: Corncall.getNTPWrappedWidget(ScopedModel<DataModel>(
            model: widget.model,
            child: ScopedModelDescendant<DataModel>(
                builder: (context, child, model) {
              return Consumer<SmartContactProviderWithLocalStoreData>(
                  builder: (context, contactsProvider, _child) => Consumer<
                          List<GroupModel>>(
                      builder: (context, groupList, _child) => Scaffold(
                          key: _scaffold,
                          backgroundColor: Thm.isDarktheme(widget.prefs)
                              ? corncallBACKGROUNDcolorDarkMode
                              : corncallBACKGROUNDcolorLightMode,
                          appBar: AppBar(
                            elevation: 0.4,
                            titleSpacing: -5,
                            leading: IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.arrow_back,
                                size: 24,
                                color: pickTextColorBasedOnBgColorAdvanced(
                                    Thm.isDarktheme(widget.prefs)
                                        ? corncallAPPBARcolorDarkMode
                                        : corncallAPPBARcolorLightMode),
                              ),
                            ),
                            backgroundColor: Thm.isDarktheme(widget.prefs)
                                ? corncallAPPBARcolorDarkMode
                                : corncallAPPBARcolorLightMode,
                            centerTitle: false,
                            // leadingWidth: 40,
                            title: Text(
                              getTranslated(
                                  this.context, 'selectcontacttoshare'),
                              style: TextStyle(
                                fontSize: 18,
                                color: pickTextColorBasedOnBgColorAdvanced(
                                    Thm.isDarktheme(widget.prefs)
                                        ? corncallAPPBARcolorDarkMode
                                        : corncallAPPBARcolorLightMode),
                              ),
                            ),
                          ),
                          body: RefreshIndicator(
                            onRefresh: () {
                              return contactsProvider.fetchContacts(context,
                                  model, widget.currentUserNo!, widget.prefs);
                            },
                            child: contactsProvider
                                            .searchingcontactsindatabase ==
                                        true ||
                                    isGroupsloading == true
                                ? loading()
                                : contactsProvider
                                            .alreadyJoinedSavedUsersPhoneNameAsInServer
                                            .length ==
                                        0
                                    ? ListView(shrinkWrap: true, children: [
                                        Padding(
                                            padding: EdgeInsets.only(
                                                top: MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    2.5),
                                            child: Center(
                                              child: Text(
                                                  getTranslated(context,
                                                      'nosearchresult'),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      color: corncallGrey)),
                                            ))
                                      ])
                                    : ListView(
                                        padding:
                                            EdgeInsets.fromLTRB(10, 10, 10, 10),
                                        physics: BouncingScrollPhysics(),
                                        shrinkWrap: true,
                                        children: [
                                          ListView.builder(
                                            padding: EdgeInsets.all(0),
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            itemCount: joinedGroupsList.length,
                                            itemBuilder: (context, i) {
                                              return Column(
                                                children: [
                                                  ListTile(
                                                    leading: customCircleAvatarGroup(
                                                        url: joinedGroupsList
                                                                .contains(Dbkeys
                                                                    .groupPHOTOURL)
                                                            ? joinedGroupsList[
                                                                    i][
                                                                Dbkeys
                                                                    .groupPHOTOURL]
                                                            : '',
                                                        radius: 22),
                                                    title: Text(
                                                      joinedGroupsList[i]
                                                          [Dbkeys.groupNAME],
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: corncallBlack,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      '${joinedGroupsList[i][Dbkeys.groupMEMBERSLIST].length} ${getTranslated(context, 'participants')}',
                                                      style: TextStyle(
                                                        color: corncallGrey,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      // for group
                                                      Navigator.pushReplacement(
                                                          context,
                                                          new MaterialPageRoute(
                                                              builder: (context) => new GroupChatPage(
                                                                  isCurrentUserMuted: joinedGroupsList[i].containsKey(Dbkeys.groupMUTEDMEMBERS)
                                                                      ? joinedGroupsList[i][Dbkeys.groupMUTEDMEMBERS].contains(widget
                                                                          .currentUserNo)
                                                                      : false,
                                                                  sharedText: widget
                                                                      .sharedText,
                                                                  sharedFiles: widget
                                                                      .sharedFiles,
                                                                  isSharingIntentForwarded:
                                                                      true,
                                                                  model: widget
                                                                      .model,
                                                                  prefs: widget
                                                                      .prefs,
                                                                  joinedTime: joinedGroupsList[i][
                                                                      '${widget.currentUserNo}-joinedOn'],
                                                                  currentUserno:
                                                                      widget.currentUserNo!,
                                                                  groupID: joinedGroupsList[i][Dbkeys.groupID])));
                                                    },
                                                  ),
                                                  Divider(
                                                    height: 2,
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          ListView.builder(
                                            padding: EdgeInsets.all(0),
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            itemCount: contactsProvider
                                                .alreadyJoinedSavedUsersPhoneNameAsInServer
                                                .length,
                                            itemBuilder: (context, idx) {
                                              String phone = contactsProvider
                                                  .alreadyJoinedSavedUsersPhoneNameAsInServer[
                                                      idx]
                                                  .phone;
                                              Widget? alreadyAddedUser;

                                              return alreadyAddedUser ??
                                                  FutureBuilder<LocalUserData?>(
                                                      future: contactsProvider
                                                          .fetchUserDataFromnLocalOrServer(
                                                              widget.prefs,
                                                              phone),
                                                      builder: (BuildContext
                                                              context,
                                                          AsyncSnapshot<
                                                                  LocalUserData?>
                                                              snapshot) {
                                                        if (snapshot.hasData) {
                                                          LocalUserData user =
                                                              snapshot.data!;
                                                          return Column(
                                                            children: [
                                                              ListTile(
                                                                leading:
                                                                    customCircleAvatar(
                                                                  url: user
                                                                      .photoURL,
                                                                  radius: 22.5,
                                                                ),
                                                                title: Text(
                                                                    user.name,
                                                                    style: TextStyle(
                                                                        color:
                                                                            corncallBlack)),
                                                                subtitle: Text(
                                                                    phone,
                                                                    style: TextStyle(
                                                                        color:
                                                                            corncallGrey)),
                                                                contentPadding:
                                                                    EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            10.0,
                                                                        vertical:
                                                                            0.0),
                                                                onTap: () {
                                                                  Navigator.pushReplacement(
                                                                      context,
                                                                      new MaterialPageRoute(
                                                                          builder: (context) => ChatScreen(
                                                                              sharedText: widget.sharedText,
                                                                              sharedFiles: widget.sharedFiles,
                                                                              isSharingIntentForwarded: true,
                                                                              prefs: widget.prefs,
                                                                              unread: 0,
                                                                              model: widget.model,
                                                                              currentUserNo: widget.currentUserNo,
                                                                              peerNo: user.id)));
                                                                },
                                                              ),
                                                              Divider(
                                                                height: 2,
                                                              )
                                                            ],
                                                          );
                                                        }
                                                        return SizedBox();
                                                      });
                                            },
                                          ),
                                        ],
                                      ),
                          ))));
            }))));
  }
}
