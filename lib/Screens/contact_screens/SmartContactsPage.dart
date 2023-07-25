//*************   © Copyrighted by Criterion Tech. *********************
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corncall/Configs/Dbkeys.dart';
import 'package:corncall/Configs/Dbpaths.dart';
import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Screens/auth_screens/login.dart';
import 'package:corncall/Screens/call_history/callhistory.dart';
import 'package:corncall/Screens/calling_screen/pickup_layout.dart';
import 'package:corncall/Screens/chat_screen/utils/aes_encryption.dart';
import 'package:corncall/Screens/contact_screens/contacts.dart';
import 'package:corncall/Screens/status/components/formatStatusTime.dart';
import 'package:corncall/Services/Providers/Observer.dart';
import 'package:corncall/Services/Providers/SmartContactProviderWithLocalStoreData.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Screens/chat_screen/chat.dart';
import 'package:corncall/Screens/chat_screen/pre_chat.dart';
import 'package:corncall/Screens/contact_screens/AddunsavedContact.dart';
import 'package:corncall/Models/DataModel.dart';
import 'package:corncall/Utils/chat_controller.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corncall/Models/E2EE/e2ee.dart' as e2ee;

class SmartContactsPage extends StatefulWidget {
  final String currentUserNo;
  final DataModel model;
  final bool biometricEnabled;
  final SharedPreferences prefs;
  final Function onTapCreateGroup;
  final Function onTapCreateBroadcast;
  const SmartContactsPage({
    Key? key,
    required this.currentUserNo,
    required this.model,
    required this.biometricEnabled,
    required this.onTapCreateBroadcast,
    required this.prefs,
    required this.onTapCreateGroup,
  }) : super(key: key);

  @override
  _SmartContactsPageState createState() => _SmartContactsPageState();
}

class _SmartContactsPageState extends State<SmartContactsPage> {
  // Map<String?, String?>? contacts;
  // Map<String?, String?>? _filtered = new Map<String, String>();

  // final TextEditingController _filter = new TextEditingController();
  final scrollController = ScrollController();
  int inviteContactsCount = 30;
  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);
  }

  FlutterSecureStorage storage = new FlutterSecureStorage();
  String? sharedSecret;
  String? privateKey;
  readLocal() async {
    try {
      privateKey = await storage.read(key: Dbkeys.privateKey);
      sharedSecret = (await e2ee.X25519().calculateSharedSecret(
              e2ee.Key.fromBase64(privateKey!, false),
              e2ee.Key.fromBase64(
                  widget.model.currentUser![Dbkeys.publicKey], true)))
          .toBase64();
      setState(() {});
    } catch (e) {
      sharedSecret = null;
      setState(() {});
    }
  }

  void scrollListener() {
    if (scrollController.offset >=
            scrollController.position.maxScrollExtent / 2 &&
        !scrollController.position.outOfRange) {
      setStateIfMounted(() {
        inviteContactsCount = inviteContactsCount + 250;
      });
    }
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final observer = Provider.of<Observer>(this.context, listen: false);
    return PickupLayout(
        prefs: widget.prefs,
        scaffold: Corncall.getNTPWrappedWidget(ScopedModel<DataModel>(
            model: widget.model,
            child: ScopedModelDescendant<DataModel>(
                builder: (context, child, model) {
              return Consumer<SmartContactProviderWithLocalStoreData>(
                  builder: (context, availableContacts, _child) {
                // _filtered = availableContacts.filtered;
                return Scaffold(
                    backgroundColor: Thm.isDarktheme(widget.prefs)
                        ? corncallBACKGROUNDcolorDarkMode
                        : corncallBACKGROUNDcolorLightMode,
                    appBar: AppBar(
                      elevation: 0.4,
                      titleSpacing: 5,
                      title: new Text(
                        getTranslated(context, 'selectsinglecontact'),
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          color: pickTextColorBasedOnBgColorAdvanced(
                              Thm.isDarktheme(widget.prefs)
                                  ? corncallAPPBARcolorDarkMode
                                  : corncallAPPBARcolorLightMode),
                        ),
                      ),
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
                      actions: <Widget>[
                        IconButton(
                          icon: Icon(
                            Icons.sync,
                            color: pickTextColorBasedOnBgColorAdvanced(
                                Thm.isDarktheme(widget.prefs)
                                    ? corncallAPPBARcolorDarkMode
                                    : corncallAPPBARcolorLightMode),
                          ),
                          onPressed: () async {
                            final SmartContactProviderWithLocalStoreData
                                contactsProvider = Provider.of<
                                        SmartContactProviderWithLocalStoreData>(
                                    context,
                                    listen: false);
                            Corncall.toast(getTranslated(context, "loading"));
                            contactsProvider.fetchContacts(
                              context,
                              widget.model,
                              widget.currentUserNo,
                              widget.prefs,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.person_add,
                            color: pickTextColorBasedOnBgColorAdvanced(
                                Thm.isDarktheme(widget.prefs)
                                    ? corncallAPPBARcolorDarkMode
                                    : corncallAPPBARcolorLightMode),
                          ),
                          onPressed: () {
                            final SmartContactProviderWithLocalStoreData
                                contactsProvider = Provider.of<
                                        SmartContactProviderWithLocalStoreData>(
                                    context,
                                    listen: false);

                            contactsProvider.fetchContacts(
                              context,
                              widget.model,
                              widget.currentUserNo,
                              widget.prefs,
                            );
                            Navigator.pushReplacement(context,
                                new MaterialPageRoute(builder: (context) {
                              return new AddunsavedNumber(
                                  prefs: widget.prefs,
                                  model: widget.model,
                                  currentUserNo: widget.currentUserNo);
                            }));
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.search,
                            color: pickTextColorBasedOnBgColorAdvanced(
                                Thm.isDarktheme(widget.prefs)
                                    ? corncallAPPBARcolorDarkMode
                                    : corncallAPPBARcolorLightMode),
                          ),
                          onPressed: () {
                            final SmartContactProviderWithLocalStoreData
                                contactsProvider = Provider.of<
                                        SmartContactProviderWithLocalStoreData>(
                                    context,
                                    listen: false);

                            contactsProvider.fetchContacts(
                              context,
                              widget.model,
                              widget.currentUserNo,
                              widget.prefs,
                            );
                            Navigator.pushReplacement(context,
                                new MaterialPageRoute(builder: (context) {
                              return new Contacts(
                                prefs: widget.prefs,
                                model: widget.model,
                                currentUserNo: widget.currentUserNo,
                                biometricEnabled: widget.biometricEnabled,
                              );
                            }));
                          },
                        )
                      ],
                    ),
                    body:
                        //  availableContacts.joinedcontactsInSharePref.length ==
                        //             0 ||
                        availableContacts.searchingcontactsindatabase == true
                            ? loading()
                            : RefreshIndicator(
                                onRefresh: () async {
                                  return availableContacts.fetchContacts(
                                      context,
                                      model,
                                      widget.currentUserNo,
                                      widget.prefs);
                                },
                                child:
                                    availableContacts
                                            .contactsBookContactList!.isEmpty
                                        ? ListView(children: [
                                            Padding(
                                                padding: EdgeInsets.only(
                                                    top: MediaQuery.of(context)
                                                            .size
                                                            .height /
                                                        2.5),
                                                child: Center(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                          getTranslated(context,
                                                              'nosearchresult'),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            color:
                                                                corncallBlack,
                                                          )),
                                                      SizedBox(
                                                        height: 40,
                                                      ),
                                                      IconButton(
                                                          onPressed: () async {
                                                            availableContacts
                                                                .setIsLoading(
                                                                    true);
                                                            await availableContacts
                                                                .fetchContacts(
                                                              context,
                                                              model,
                                                              widget
                                                                  .currentUserNo,
                                                              widget.prefs,
                                                            )
                                                                .then((d) {
                                                              Future.delayed(
                                                                  const Duration(
                                                                      milliseconds:
                                                                          500),
                                                                  () {
                                                                availableContacts
                                                                    .setIsLoading(
                                                                        false);
                                                              });
                                                            });
                                                            setState(() {});
                                                          },
                                                          icon: Icon(
                                                            Icons
                                                                .refresh_rounded,
                                                            size: 40,
                                                            color:
                                                                corncallPRIMARYcolor,
                                                          ))
                                                    ],
                                                  ),
                                                ))
                                          ])
                                        : ListView(
                                            controller: scrollController,
                                            padding: EdgeInsets.only(
                                                bottom: 15, top: 0),
                                            physics: BouncingScrollPhysics(),
                                            children: [
                                              ListTile(
                                                tileColor: Thm.isDarktheme(
                                                        widget.prefs)
                                                    ? corncallCONTAINERboxColorDarkMode
                                                    : corncallCONTAINERboxColorLightMode,
                                                leading: CircleAvatar(
                                                    backgroundColor:
                                                    SplashBackgroundSolidColor,
                                                    radius: 22.5,
                                                    child: Icon(
                                                      Icons.share_rounded,
                                                      color: Colors.white,
                                                    )),
                                                title: Text(
                                                  getTranslated(
                                                      context, 'share'),
                                                  style: TextStyle(
                                                    color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                            .isDarktheme(
                                                                widget.prefs)
                                                        ? corncallCONTAINERboxColorDarkMode
                                                        : corncallCONTAINERboxColorLightMode),
                                                  ),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 22.0,
                                                        vertical: 11.0),
                                                onTap: () {
                                                  Corncall.invite(context);
                                                },
                                              ),
                                              ListTile(
                                                tileColor: Thm.isDarktheme(
                                                        widget.prefs)
                                                    ? corncallCONTAINERboxColorDarkMode
                                                    : corncallCONTAINERboxColorLightMode,
                                                leading: CircleAvatar(
                                                    backgroundColor:
                                                    SplashBackgroundSolidColor,
                                                    radius: 22.5,
                                                    child: Icon(
                                                      Icons.group,
                                                      color: Colors.white,
                                                    )),
                                                title: Text(
                                                  getTranslated(
                                                      context, 'creategroup'),
                                                  style: TextStyle(
                                                    color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                            .isDarktheme(
                                                                widget.prefs)
                                                        ? corncallCONTAINERboxColorDarkMode
                                                        : corncallCONTAINERboxColorLightMode),
                                                  ),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 22.0,
                                                        vertical: 11.0),
                                                onTap: () {
                                                  widget.onTapCreateGroup();
                                                },
                                              ),
                                              ListTile(
                                                tileColor: Thm.isDarktheme(
                                                        widget.prefs)
                                                    ? corncallCONTAINERboxColorDarkMode
                                                    : corncallCONTAINERboxColorLightMode,
                                                leading: CircleAvatar(
                                                    backgroundColor:
                                                    SplashBackgroundSolidColor,
                                                    radius: 22.5,
                                                    child: Icon(
                                                      Icons.campaign,
                                                      color: Colors.white,
                                                    )),
                                                title: Text(
                                                  getTranslated(
                                                      context, 'newbroadcast'),
                                                  style: TextStyle(
                                                    color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                            .isDarktheme(
                                                                widget.prefs)
                                                        ? corncallCONTAINERboxColorDarkMode
                                                        : corncallCONTAINERboxColorLightMode),
                                                  ),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                        horizontal: 22.0,
                                                        vertical: 11.0),
                                                onTap: () {
                                                  widget.onTapCreateBroadcast();
                                                },
                                              ),
                                              if (observer.isWebCompatible ==
                                                  true)
                                                ListTile(
                                                  tileColor: Thm.isDarktheme(
                                                          widget.prefs)
                                                      ? corncallCONTAINERboxColorDarkMode
                                                      : corncallCONTAINERboxColorLightMode,
                                                  leading: CircleAvatar(
                                                      backgroundColor:
                                                      SplashBackgroundSolidColor,
                                                      radius: 22.5,
                                                      child: Icon(
                                                        Icons.devices,
                                                        color: Colors.white,
                                                      )),
                                                  title: Text(
                                                    getTranslated(
                                                        context, 'synctoweb'),
                                                    style: TextStyle(
                                                      color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                              .isDarktheme(
                                                                  widget.prefs)
                                                          ? corncallCONTAINERboxColorDarkMode
                                                          : corncallCONTAINERboxColorLightMode),
                                                    ),
                                                  ),
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          horizontal: 22.0,
                                                          vertical: 11.0),
                                                  onTap: () {
                                                    showModalBottomSheet(
                                                        backgroundColor: Thm
                                                                .isDarktheme(
                                                                    widget
                                                                        .prefs)
                                                            ? corncallDIALOGColorDarkMode
                                                            : corncallDIALOGColorLightMode,
                                                        isScrollControlled:
                                                            true,
                                                        context: this.context,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.vertical(
                                                                  top: Radius
                                                                      .circular(
                                                                          25.0)),
                                                        ),
                                                        builder: (BuildContext
                                                            context) {
                                                          return availableContacts
                                                                      .alreadyJoinedSavedUsersPhoneNameAsInServer
                                                                      .length ==
                                                                  0
                                                              ? Container(
                                                                  height: 270,
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                            .all(
                                                                        28.0),
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Icon(
                                                                            Icons
                                                                                .contact_phone,
                                                                            color:
                                                                                Colors.orange[400],
                                                                            size: 60),
                                                                        SizedBox(
                                                                          height:
                                                                              30,
                                                                        ),
                                                                        Text(
                                                                          getTranslated(
                                                                              context,
                                                                              'nocontactsavailable'),
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          style:
                                                                              TextStyle(
                                                                            color: pickTextColorBasedOnBgColorAdvanced(Thm.isDarktheme(widget.prefs)
                                                                                ? corncallDIALOGColorDarkMode
                                                                                : corncallDIALOGColorLightMode),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ),
                                                                )
                                                              : Container(
                                                                  height: 410,
                                                                  child:
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                            .all(
                                                                        18.0),
                                                                    child:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Icon(
                                                                            Icons
                                                                                .contact_phone,
                                                                            color:
                                                                                Colors.orange[400],
                                                                            size: 60),
                                                                        SizedBox(
                                                                          height:
                                                                              30,
                                                                        ),
                                                                        Text(
                                                                          getTranslated(context, 'synctowebdesc').replaceAll('(####)', availableContacts.alreadyJoinedSavedUsersPhoneNameAsInServer.length.toString()) +
                                                                              "\n\n${getTranslated(context, 'endtoendencryption')}. \n\n${widget.model.currentUser!.containsKey(Dbkeys.webLoginTime) ? widget.model.currentUser![Dbkeys.webLoginTime] == 0 ? getTranslated(context, 'logintoweb') : getStatusTime(widget.model.currentUser![Dbkeys.webLoginTime], context) : getTranslated(context, 'logintoweb')}",
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          style: TextStyle(
                                                                              color: pickTextColorBasedOnBgColorAdvanced(Thm.isDarktheme(widget.prefs) ? corncallDIALOGColorDarkMode : corncallDIALOGColorLightMode),
                                                                              height: 1.3),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              10,
                                                                        ),
                                                                        if (widget
                                                                            .model
                                                                            .currentUser!
                                                                            .containsKey(Dbkeys.lastSyncedTime))
                                                                          Text(
                                                                            "${getTranslated(context, 'lastsynced')}: ${getStatusTime(widget.model.currentUser![Dbkeys.lastSyncedTime], context)} (${widget.model.currentUser![Dbkeys.lastSyncedContacts]} ${getTranslated(context, 'contacts')})",
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style:
                                                                                TextStyle(color: corncallGrey, fontSize: 11),
                                                                          ),
                                                                        SizedBox(
                                                                          height:
                                                                              30,
                                                                        ),
                                                                        MySimpleButton(
                                                                          buttontext: getTranslated(
                                                                              context,
                                                                              'syncnow'),
                                                                          buttoncolor:
                                                                              corncallPRIMARYcolor,
                                                                          onpressed:
                                                                              () async {
                                                                            try {
                                                                              int t = DateTime.now().millisecondsSinceEpoch;
                                                                              await readLocal();
                                                                              if (sharedSecret != null && privateKey != null) {
                                                                                final String encodedalreadyJoinedSavedUsersPhoneNameAsInServer = DeviceContactIdAndName.encode(availableContacts.alreadyJoinedSavedUsersPhoneNameAsInServer);
                                                                                final encrypted = AESEncryptData.encryptAES(encodedalreadyJoinedSavedUsersPhoneNameAsInServer, sharedSecret);
                                                                                Navigator.of(context).pop();
                                                                                FirebaseFirestore.instance.collection(DbPaths.collectionusers).doc(widget.currentUserNo).collection(Dbkeys.lastSyncedContacts).doc(Dbkeys.lastSyncedContacts).set({
                                                                                  Dbkeys.lastSyncedContacts: encrypted,
                                                                                  Dbkeys.lastSyncedTime: t,
                                                                                }).then((value) {
                                                                                  //done sync
                                                                                  FirebaseFirestore.instance.collection(DbPaths.collectionusers).doc(widget.currentUserNo).set({
                                                                                    Dbkeys.lastSyncedContacts: availableContacts.alreadyJoinedSavedUsersPhoneNameAsInServer.length,
                                                                                    Dbkeys.lastSyncedTime: t,
                                                                                    Dbkeys.lastSyncedID: sharedSecret
                                                                                  }, SetOptions(merge: true)).then((value) {
                                                                                    Corncall.toast(getTranslated(this.context, 'syncsuccess'));
                                                                                  }).catchError((e) {
                                                                                    Corncall.toast("${getTranslated(this.context, 'failedtosync')}\n\n $e");
                                                                                  });
                                                                                });
                                                                              } else {
                                                                                Corncall.toast("Failed ! Please try again .");
                                                                              }
                                                                            } catch (e) {
                                                                              Corncall.toast("${getTranslated(this.context, 'failedtosync')} \n\n- $e");
                                                                            }
                                                                          },
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              17,
                                                                        ),
                                                                        if (widget
                                                                            .model
                                                                            .currentUser!
                                                                            .containsKey(Dbkeys.lastSyncedTime))
                                                                          TextButton(
                                                                              onPressed: () {
                                                                                Navigator.of(context).pop();
                                                                                FirebaseFirestore.instance.collection(DbPaths.collectionusers).doc(widget.currentUserNo).collection(Dbkeys.lastSyncedContacts).doc(Dbkeys.lastSyncedContacts).delete().then((value) {
                                                                                  FirebaseFirestore.instance.collection(DbPaths.collectionusers).doc(widget.currentUserNo).set({
                                                                                    Dbkeys.lastSyncedContacts: FieldValue.delete(),
                                                                                    Dbkeys.lastSyncedTime: FieldValue.delete(),
                                                                                    Dbkeys.lastSyncedID: FieldValue.delete(),
                                                                                  }, SetOptions(merge: true)).then((value) {
                                                                                    Corncall.toast(getTranslated(this.context, 'syncdeleted'));
                                                                                  }).catchError((e) {
                                                                                    Corncall.toast("Failed !\n\n $e");
                                                                                  });
                                                                                });
                                                                              },
                                                                              child: Text(
                                                                                getTranslated(context, 'deletesync'),
                                                                                style: TextStyle(color: Colors.red, fontSize: 13),
                                                                              ))
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );
                                                        });
                                                  },
                                                ),
                                              SizedBox(
                                                height: 14,
                                              ),
                                              availableContacts
                                                          .alreadyJoinedSavedUsersPhoneNameAsInServer
                                                          .length ==
                                                      0
                                                  ? SizedBox(
                                                      height: 0,
                                                    )
                                                  : ListView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                          NeverScrollableScrollPhysics(),
                                                      padding:
                                                          EdgeInsets.all(00),
                                                      itemCount: availableContacts
                                                          .alreadyJoinedSavedUsersPhoneNameAsInServer
                                                          .length,
                                                      itemBuilder:
                                                          (context, idx) {
                                                        DeviceContactIdAndName
                                                            user =
                                                            availableContacts
                                                                .alreadyJoinedSavedUsersPhoneNameAsInServer
                                                                .elementAt(idx);
                                                        String phone =
                                                            user.phone;
                                                        String name =
                                                            user.name ??
                                                                user.phone;
                                                        return FutureBuilder<
                                                            LocalUserData?>(
                                                          future: availableContacts
                                                              .fetchUserDataFromnLocalOrServer(
                                                                  widget.prefs,
                                                                  phone),
                                                          builder: (BuildContext
                                                                  context,
                                                              AsyncSnapshot<
                                                                      LocalUserData?>
                                                                  snapshot) {
                                                            if (snapshot
                                                                    .hasData &&
                                                                snapshot.data !=
                                                                    null) {
                                                              return ListTile(
                                                                tileColor: Thm.isDarktheme(
                                                                        widget
                                                                            .prefs)
                                                                    ? corncallCONTAINERboxColorDarkMode
                                                                    : corncallCONTAINERboxColorLightMode,
                                                                leading: customCircleAvatar(
                                                                    url: snapshot
                                                                        .data!
                                                                        .photoURL,
                                                                    radius: 22),
                                                                title: Text(
                                                                    snapshot
                                                                        .data!
                                                                        .name,
                                                                    style:
                                                                        TextStyle(
                                                                      color: pickTextColorBasedOnBgColorAdvanced(Thm.isDarktheme(
                                                                              widget.prefs)
                                                                          ? corncallCONTAINERboxColorDarkMode
                                                                          : corncallCONTAINERboxColorLightMode),
                                                                    )),
                                                                subtitle: Text(
                                                                    phone,
                                                                    style: TextStyle(
                                                                        color:
                                                                            corncallGrey)),
                                                                contentPadding:
                                                                    EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            22.0,
                                                                        vertical:
                                                                            0.0),
                                                                onTap: () {
                                                                  hidekeyboard(
                                                                      context);
                                                                  dynamic
                                                                      wUser =
                                                                      model.userData[
                                                                          phone];
                                                                  if (wUser !=
                                                                          null &&
                                                                      wUser[Dbkeys
                                                                              .chatStatus] !=
                                                                          null) {
                                                                    if (model.currentUser![Dbkeys.locked] !=
                                                                            null &&
                                                                        model
                                                                            .currentUser![Dbkeys.locked]
                                                                            .contains(phone)) {
                                                                      ChatController.authenticate(
                                                                          model,
                                                                          getTranslated(context,
                                                                              'auth_neededchat'),
                                                                          prefs: widget
                                                                              .prefs,
                                                                          shouldPop:
                                                                              false,
                                                                          state: Navigator.of(
                                                                              context),
                                                                          type: Corncall.getAuthenticationType(
                                                                              widget
                                                                                  .biometricEnabled,
                                                                              model),
                                                                          onSuccess:
                                                                              () {
                                                                        Navigator.pushAndRemoveUntil(
                                                                            context,
                                                                            new MaterialPageRoute(builder: (context) => new ChatScreen(isSharingIntentForwarded: false, prefs: widget.prefs, model: model, currentUserNo: widget.currentUserNo, peerNo: phone, unread: 0)),
                                                                            (Route r) => r.isFirst);
                                                                      });
                                                                    } else {
                                                                      Navigator.pushReplacement(
                                                                          context,
                                                                          new MaterialPageRoute(
                                                                              builder: (context) => new ChatScreen(isSharingIntentForwarded: false, prefs: widget.prefs, model: model, currentUserNo: widget.currentUserNo, peerNo: phone, unread: 0)));
                                                                    }
                                                                  } else {
                                                                    Navigator.pushReplacement(
                                                                        context,
                                                                        new MaterialPageRoute(builder:
                                                                            (context) {
                                                                      return new PreChat(
                                                                          prefs: widget
                                                                              .prefs,
                                                                          model: widget
                                                                              .model,
                                                                          name:
                                                                              name,
                                                                          phone:
                                                                              phone,
                                                                          currentUserNo:
                                                                              widget.currentUserNo);
                                                                    }));
                                                                  }
                                                                },
                                                              );
                                                            }
                                                            return ListTile(
                                                              tileColor: Thm
                                                                      .isDarktheme(
                                                                          widget
                                                                              .prefs)
                                                                  ? corncallCONTAINERboxColorDarkMode
                                                                  : corncallCONTAINERboxColorLightMode,
                                                              leading:
                                                                  customCircleAvatar(
                                                                      radius:
                                                                          22),
                                                              title: Text(name,
                                                                  style:
                                                                      TextStyle(
                                                                    color: pickTextColorBasedOnBgColorAdvanced(Thm.isDarktheme(
                                                                            widget.prefs)
                                                                        ? corncallCONTAINERboxColorDarkMode
                                                                        : corncallCONTAINERboxColorLightMode),
                                                                  )),
                                                              subtitle: Text(
                                                                  phone,
                                                                  style: TextStyle(
                                                                      color:
                                                                          corncallGrey)),
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          22.0,
                                                                      vertical:
                                                                          0.0),
                                                              onTap: () {
                                                                hidekeyboard(
                                                                    context);
                                                                dynamic wUser =
                                                                    model.userData[
                                                                        phone];
                                                                if (wUser !=
                                                                        null &&
                                                                    wUser[Dbkeys
                                                                            .chatStatus] !=
                                                                        null) {
                                                                  if (model.currentUser![Dbkeys
                                                                              .locked] !=
                                                                          null &&
                                                                      model
                                                                          .currentUser![Dbkeys
                                                                              .locked]
                                                                          .contains(
                                                                              phone)) {
                                                                    ChatController.authenticate(
                                                                        model,
                                                                        getTranslated(context,
                                                                            'auth_neededchat'),
                                                                        prefs: widget
                                                                            .prefs,
                                                                        shouldPop:
                                                                            false,
                                                                        state: Navigator.of(
                                                                            context),
                                                                        type: Corncall.getAuthenticationType(
                                                                            widget
                                                                                .biometricEnabled,
                                                                            model),
                                                                        onSuccess:
                                                                            () {
                                                                      Navigator.pushAndRemoveUntil(
                                                                          context,
                                                                          new MaterialPageRoute(
                                                                              builder: (context) => new ChatScreen(isSharingIntentForwarded: false, prefs: widget.prefs, model: model, currentUserNo: widget.currentUserNo, peerNo: phone, unread: 0)),
                                                                          (Route r) => r.isFirst);
                                                                    });
                                                                  } else {
                                                                    Navigator.pushReplacement(
                                                                        context,
                                                                        new MaterialPageRoute(
                                                                            builder: (context) => new ChatScreen(
                                                                                isSharingIntentForwarded: false,
                                                                                prefs: widget.prefs,
                                                                                model: model,
                                                                                currentUserNo: widget.currentUserNo,
                                                                                peerNo: phone,
                                                                                unread: 0)));
                                                                  }
                                                                } else {
                                                                  Navigator.pushReplacement(
                                                                      context,
                                                                      new MaterialPageRoute(
                                                                          builder:
                                                                              (context) {
                                                                    return new PreChat(
                                                                        prefs: widget
                                                                            .prefs,
                                                                        model: widget
                                                                            .model,
                                                                        name:
                                                                            name,
                                                                        phone:
                                                                            phone,
                                                                        currentUserNo:
                                                                            widget.currentUserNo);
                                                                  }));
                                                                }
                                                              },
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        18, 24, 18, 18),
                                                child: Text(
                                                  getTranslated(
                                                      context, 'invite'),
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                    color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                            .isDarktheme(
                                                                widget.prefs)
                                                        ? corncallCONTAINERboxColorDarkMode
                                                        : corncallCONTAINERboxColorLightMode),
                                                  ),
                                                ),
                                              ),
                                              ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                padding: EdgeInsets.all(0),
                                                itemCount: inviteContactsCount >=
                                                        availableContacts
                                                            .contactsBookContactList!
                                                            .length
                                                    ? availableContacts
                                                        .contactsBookContactList!
                                                        .length
                                                    : inviteContactsCount,
                                                itemBuilder: (context, idx) {
                                                  MapEntry user = availableContacts
                                                      .contactsBookContactList!
                                                      .entries
                                                      .elementAt(idx);
                                                  String phone = user.key;
                                                  return availableContacts
                                                              .previouslyFetchedKEYPhoneInSharedPrefs
                                                              .indexWhere(
                                                                  (element) =>
                                                                      element
                                                                          .phone ==
                                                                      phone) >=
                                                          0
                                                      ? Container(
                                                          width: 0,
                                                        )
                                                      : Visibility(

                                                    //visible: availableContacts.alreadyJoinedSavedUsersPhoneNameAsInServer[idx].phone.toString() == phone.toString()?false:true,
                                                        child: Stack(
                                                            children: [
                                                              ListTile(
                                                                tileColor: Thm
                                                                        .isDarktheme(
                                                                            widget
                                                                                .prefs)
                                                                    ? corncallCONTAINERboxColorDarkMode
                                                                    : corncallCONTAINERboxColorLightMode,
                                                                leading:
                                                                    CircleAvatar(
                                                                        backgroundColor:
                                                                        corncallbluelightcolor,
                                                                        radius:
                                                                            22.5,
                                                                        child:
                                                                            Text(
                                                                          Corncall.getInitials(
                                                                              user.value),
                                                                          style: TextStyle(
                                                                              color:
                                                                                  corncallWhite),
                                                                        )),
                                                                title: Text(
                                                                    user.value,
                                                                    style:
                                                                        TextStyle(
                                                                      color: pickTextColorBasedOnBgColorAdvanced(Thm.isDarktheme(
                                                                              widget.prefs)
                                                                          ? corncallCONTAINERboxColorDarkMode
                                                                          : corncallCONTAINERboxColorLightMode),
                                                                    )),
                                                                subtitle: Text(
                                                                    phone,
                                                                    style: TextStyle(
                                                                        color:
                                                                            corncallGrey)),
                                                                contentPadding:
                                                                    EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            22.0,
                                                                        vertical:
                                                                            0.0),
                                                                onTap: () {
                                                                  hidekeyboard(
                                                                      context);
                                                                  Corncall.invite(
                                                                      context);
                                                                },
                                                              ),
                                                              Positioned(
                                                                right: 19,
                                                                bottom: 19,
                                                                child: InkWell(
                                                                    onTap: () {
                                                                      hidekeyboard(
                                                                          context);
                                                                      Corncall
                                                                          .invite(
                                                                              context);
                                                                    },
                                                                    child: Icon(
                                                                      Icons
                                                                          .person_add_alt,
                                                                      color:
                                                                      corncallbluelightcolor,
                                                                    )),
                                                              )
                                                            ],
                                                          ),
                                                      );
                                                },
                                              ),
                                            ],
                                          )));
              });
            }))));
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
}
