//*************   © Copyrighted by Criterion Tech. *********************

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corncall/Configs/Dbkeys.dart';
import 'package:corncall/Configs/Dbpaths.dart';
import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Screens/auth_screens/login.dart';
import 'package:corncall/Screens/call_history/callhistory.dart';
import 'package:corncall/Screens/calling_screen/pickup_layout.dart';
import 'package:corncall/Services/Providers/BroadcastProvider.dart';
import 'package:corncall/Services/Providers/SmartContactProviderWithLocalStoreData.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Models/DataModel.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:corncall/widgets/MyElevatedButton/MyElevatedButton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddContactsToBroadcast extends StatefulWidget {
  const AddContactsToBroadcast({
    this.blacklistedUsers,
    required this.currentUserNo,
    required this.model,
    required this.biometricEnabled,
    required this.prefs,
    required this.isAddingWhileCreatingBroadcast,
    this.broadcastID,
  });

  final List? blacklistedUsers;
  final String? broadcastID;
  final String? currentUserNo;
  final DataModel? model;
  final SharedPreferences prefs;
  final bool biometricEnabled;
  final bool isAddingWhileCreatingBroadcast;

  @override
  _AddContactsToBroadcastState createState() =>
      new _AddContactsToBroadcastState();
}

class _AddContactsToBroadcastState extends State<AddContactsToBroadcast>
    with AutomaticKeepAliveClientMixin {
  GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
  Map<String?, String?>? contacts;
  List<LocalUserData> _selectedList = [];

  @override
  bool get wantKeepAlive => true;

  final TextEditingController _filter = new TextEditingController();
  final TextEditingController broadcastname = new TextEditingController();
  final TextEditingController broadcastdesc = new TextEditingController();
  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  @override
  void dispose() {
    super.dispose();
    _filter.dispose();
  }

  loading() {
    return Stack(children: [
      Container(
        color: pickTextColorBasedOnBgColorAdvanced(
                !Thm.isDarktheme(widget.prefs)
                    ? corncallAPPBARcolorDarkMode
                    : corncallAPPBARcolorLightMode)
            .withOpacity(0.8),
        child: Center(
            child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(corncallSECONDARYolor),
        )),
      )
    ]);
  }

  bool iscreatingbroadcast = false;
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PickupLayout(
        prefs: widget.prefs,
        scaffold: Corncall.getNTPWrappedWidget(ScopedModel<DataModel>(
            model: widget.model!,
            child: ScopedModelDescendant<DataModel>(
                builder: (context, child, model) {
              return Consumer<SmartContactProviderWithLocalStoreData>(
                  builder:
                      (context, contactsProvider, _child) =>
                          Consumer<List<BroadcastModel>>(
                              builder: (context, broadcastList, _child) =>
                                  Scaffold(
                                      key: _scaffold,
                                      backgroundColor:
                                          Thm.isDarktheme(widget.prefs)
                                              ? corncallBACKGROUNDcolorDarkMode
                                              : corncallBACKGROUNDcolorLightMode,
                                      appBar: AppBar(
                                        elevation: 0.4,
                                        leading: IconButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          icon: Icon(
                                            Icons.arrow_back,
                                            size: 24,
                                            color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                    .isDarktheme(widget.prefs)
                                                ? corncallAPPBARcolorDarkMode
                                                : corncallAPPBARcolorLightMode),
                                          ),
                                        ),
                                        backgroundColor:
                                            Thm.isDarktheme(widget.prefs)
                                                ? corncallAPPBARcolorDarkMode
                                                : corncallAPPBARcolorLightMode,
                                        centerTitle: false,
                                        title: _selectedList.length == 0
                                            ? Text(
                                                getTranslated(this.context,
                                                    'selectcontacts'),
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                          .isDarktheme(
                                                              widget.prefs)
                                                      ? corncallAPPBARcolorDarkMode
                                                      : corncallAPPBARcolorLightMode),
                                                ),
                                                textAlign: TextAlign.left,
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    getTranslated(this.context,
                                                        'selectcontacts'),
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                              .isDarktheme(
                                                                  widget.prefs)
                                                          ? corncallAPPBARcolorDarkMode
                                                          : corncallAPPBARcolorLightMode),
                                                    ),
                                                    textAlign: TextAlign.left,
                                                  ),
                                                  SizedBox(
                                                    height: 4,
                                                  ),
                                                  Text(
                                                    widget.isAddingWhileCreatingBroadcast ==
                                                            true
                                                        ? '${_selectedList.length} / ${contactsProvider.alreadyJoinedSavedUsersPhoneNameAsInServer.length}'
                                                        : '${_selectedList.length} ${getTranslated(this.context, 'selected')}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                              .isDarktheme(
                                                                  widget.prefs)
                                                          ? corncallAPPBARcolorDarkMode
                                                          : corncallAPPBARcolorLightMode),
                                                    ),
                                                    textAlign: TextAlign.left,
                                                  ),
                                                ],
                                              ),
                                        actions: <Widget>[
                                          _selectedList.length == 0
                                              ? SizedBox()
                                              : IconButton(
                                                  icon: Icon(
                                                    Icons.check,
                                                    color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                            .isDarktheme(
                                                                widget.prefs)
                                                        ? corncallAPPBARcolorDarkMode
                                                        : corncallAPPBARcolorLightMode),
                                                  ),
                                                  onPressed:
                                                      widget.isAddingWhileCreatingBroadcast ==
                                                              true
                                                          ? () async {
                                                              broadcastdesc
                                                                  .clear();
                                                              broadcastname
                                                                  .clear();
                                                              showModalBottomSheet(
                                                                  backgroundColor: Thm.isDarktheme(
                                                                          widget
                                                                              .prefs)
                                                                      ? corncallDIALOGColorDarkMode
                                                                      : corncallDIALOGColorLightMode,
                                                                  isScrollControlled:
                                                                      true,
                                                                  context:
                                                                      context,
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.vertical(
                                                                            top:
                                                                                Radius.circular(25.0)),
                                                                  ),
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    // return your layout
                                                                    var w = MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width;
                                                                    return Padding(
                                                                      padding: EdgeInsets.only(
                                                                          bottom: MediaQuery.of(context)
                                                                              .viewInsets
                                                                              .bottom),
                                                                      child: Container(
                                                                          padding: EdgeInsets.all(16),
                                                                          height: MediaQuery.of(context).size.height / 2.2,
                                                                          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                                                            SizedBox(
                                                                              height: 12,
                                                                            ),
                                                                            SizedBox(
                                                                              height: 3,
                                                                            ),
                                                                            Padding(
                                                                              padding: const EdgeInsets.only(left: 7),
                                                                              child: Text(
                                                                                getTranslated(this.context, 'setbroadcastdetails'),
                                                                                textAlign: TextAlign.left,
                                                                                style: TextStyle(color: pickTextColorBasedOnBgColorAdvanced(Thm.isDarktheme(widget.prefs) ? corncallDIALOGColorDarkMode : corncallDIALOGColorLightMode), fontWeight: FontWeight.bold, fontSize: 16.5),
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              height: 10,
                                                                            ),
                                                                            Container(
                                                                              margin: EdgeInsets.only(top: 10),
                                                                              padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                                                              // height: 63,
                                                                              height: 83,
                                                                              width: w / 1.24,
                                                                              child: InpuTextBox(
                                                                                isDark: Thm.isDarktheme(widget.prefs),
                                                                                controller: broadcastname,
                                                                                leftrightmargin: 0,
                                                                                showIconboundary: false,
                                                                                boxcornerradius: 5.5,
                                                                                boxheight: 50,
                                                                                hinttext: getTranslated(this.context, 'broadcastname'),
                                                                                prefixIconbutton: Icon(
                                                                                  Icons.edit,
                                                                                  color: Colors.grey.withOpacity(0.5),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            Container(
                                                                              margin: EdgeInsets.only(top: 10),
                                                                              padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                                                              // height: 63,
                                                                              height: 83,
                                                                              width: w / 1.24,
                                                                              child: InpuTextBox(
                                                                                isDark: Thm.isDarktheme(widget.prefs),
                                                                                maxLines: 1,
                                                                                controller: broadcastdesc,
                                                                                leftrightmargin: 0,
                                                                                showIconboundary: false,
                                                                                boxcornerradius: 5.5,
                                                                                boxheight: 50,
                                                                                hinttext: getTranslated(this.context, 'broadcastdesc'),
                                                                                prefixIconbutton: Icon(
                                                                                  Icons.message,
                                                                                  color: Colors.grey.withOpacity(0.5),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              height: 6,
                                                                            ),
                                                                            myElevatedButton(
                                                                                color: corncallSECONDARYolor,
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
                                                                                  child: Text(
                                                                                    getTranslated(context, 'createbroadcast'),
                                                                                    style: TextStyle(color: Colors.white, fontSize: 18),
                                                                                  ),
                                                                                ),
                                                                                onPressed: () async {
                                                                                  Navigator.of(_scaffold.currentContext!).pop();
                                                                                  List<String> listusers = [];
                                                                                  List<String> listmembers = [];
                                                                                  _selectedList.forEach((element) {
                                                                                    listusers.add(element.id);
                                                                                    listmembers.add(element.id);
                                                                                  });

                                                                                  DateTime time = DateTime.now();
                                                                                  DateTime time2 = DateTime.now().add(Duration(seconds: 1));
                                                                                  Map<String, dynamic> broadcastdata = {
                                                                                    Dbkeys.broadcastDESCRIPTION: broadcastdesc.text.isEmpty ? '' : broadcastdesc.text.trim(),
                                                                                    Dbkeys.broadcastCREATEDON: time,
                                                                                    Dbkeys.broadcastCREATEDBY: widget.currentUserNo,
                                                                                    Dbkeys.broadcastNAME: broadcastname.text.isEmpty ? 'Unnamed BroadCast' : broadcastname.text.trim(),
                                                                                    Dbkeys.broadcastADMINLIST: [
                                                                                      widget.currentUserNo
                                                                                    ],
                                                                                    Dbkeys.broadcastID: widget.currentUserNo!.toString() + '--' + time.millisecondsSinceEpoch.toString(),
                                                                                    Dbkeys.broadcastMEMBERSLIST: listmembers,
                                                                                    Dbkeys.broadcastLATESTMESSAGETIME: time.millisecondsSinceEpoch,
                                                                                    Dbkeys.broadcastBLACKLISTED: [],
                                                                                  };

                                                                                  listmembers.forEach((element) {
                                                                                    broadcastdata.putIfAbsent(element.toString(), () => time.millisecondsSinceEpoch);

                                                                                    broadcastdata.putIfAbsent('$element-joinedOn', () => time.millisecondsSinceEpoch);
                                                                                  });
                                                                                  setStateIfMounted(() {
                                                                                    iscreatingbroadcast = true;
                                                                                  });
                                                                                  await FirebaseFirestore.instance.collection(DbPaths.collectionbroadcasts).doc(widget.currentUserNo!.toString() + '--' + time.millisecondsSinceEpoch.toString()).set(broadcastdata).then((value) async {
                                                                                    await FirebaseFirestore.instance.collection(DbPaths.collectionbroadcasts).doc(widget.currentUserNo!.toString() + '--' + time.millisecondsSinceEpoch.toString()).collection(DbPaths.collectionbroadcastsChats).doc(time2.millisecondsSinceEpoch.toString() + '--' + widget.currentUserNo!.toString()).set({
                                                                                      Dbkeys.broadcastmsgCONTENT: '',
                                                                                      Dbkeys.broadcastmsgLISToptional: listmembers,
                                                                                      Dbkeys.broadcastmsgTIME: time2.millisecondsSinceEpoch,
                                                                                      Dbkeys.broadcastmsgSENDBY: widget.currentUserNo,
                                                                                      Dbkeys.broadcastmsgISDELETED: false,
                                                                                      Dbkeys.broadcastmsgTYPE: Dbkeys.broadcastmsgTYPEnotificationAddedUser,
                                                                                    }).then((value) async {
                                                                                      Navigator.of(_scaffold.currentContext!).pop();
                                                                                    }).catchError((err) {
                                                                                      setStateIfMounted(() {
                                                                                        iscreatingbroadcast = false;
                                                                                      });

                                                                                      Corncall.toast('Error Creating Broadcast. $err');
                                                                                      print('Error Creating Broadcast. $err');
                                                                                    });
                                                                                  });
                                                                                }),
                                                                          ])),
                                                                    );
                                                                  });
                                                            }
                                                          : () async {
                                                              // List<String> listusers = [];
                                                              List<String>
                                                                  listmembers =
                                                                  [];
                                                              _selectedList
                                                                  .forEach(
                                                                      (element) {
                                                                // listusers.add(element[Dbkeys.phone]);
                                                                listmembers.add(
                                                                    element.id);
                                                                // listmembers
                                                                //     .add(widget.currentUserNo!);
                                                              });
                                                              DateTime time =
                                                                  DateTime
                                                                      .now();

                                                              setStateIfMounted(
                                                                  () {
                                                                iscreatingbroadcast =
                                                                    true;
                                                              });

                                                              Map<String,
                                                                      dynamic>
                                                                  docmap = {
                                                                Dbkeys.broadcastMEMBERSLIST:
                                                                    FieldValue
                                                                        .arrayUnion(
                                                                            listmembers)
                                                              };

                                                              _selectedList.forEach(
                                                                  (element) async {
                                                                docmap.putIfAbsent(
                                                                    '${element.id}-joinedOn',
                                                                    () => time
                                                                        .millisecondsSinceEpoch);
                                                              });
                                                              setStateIfMounted(
                                                                  () {});
                                                              await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                      DbPaths
                                                                          .collectionbroadcasts)
                                                                  .doc(widget
                                                                      .broadcastID)
                                                                  .update(
                                                                      docmap)
                                                                  .then(
                                                                      (value) async {
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        DbPaths
                                                                            .collectionbroadcasts)
                                                                    .doc(widget
                                                                            .currentUserNo!
                                                                            .toString() +
                                                                        '--' +
                                                                        time.millisecondsSinceEpoch
                                                                            .toString())
                                                                    .collection(
                                                                        DbPaths
                                                                            .collectionbroadcastsChats)
                                                                    .doc(time
                                                                            .millisecondsSinceEpoch
                                                                            .toString() +
                                                                        '--' +
                                                                        widget
                                                                            .currentUserNo!
                                                                            .toString())
                                                                    .set({
                                                                  Dbkeys.broadcastmsgCONTENT:
                                                                      '',
                                                                  Dbkeys.broadcastmsgLISToptional:
                                                                      listmembers,
                                                                  Dbkeys.broadcastmsgTIME:
                                                                      time.millisecondsSinceEpoch,
                                                                  Dbkeys.broadcastmsgSENDBY:
                                                                      widget
                                                                          .currentUserNo,
                                                                  Dbkeys.broadcastmsgISDELETED:
                                                                      false,
                                                                  Dbkeys.broadcastmsgTYPE:
                                                                      Dbkeys
                                                                          .broadcastmsgTYPEnotificationAddedUser,
                                                                }).then(
                                                                        (value) async {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                }).catchError(
                                                                        (err) {
                                                                  setStateIfMounted(
                                                                      () {
                                                                    iscreatingbroadcast =
                                                                        false;
                                                                  });

                                                                  Corncall
                                                                      .toast(
                                                                    getTranslated(
                                                                        context,
                                                                        'erroraddingbroadcast'),
                                                                  );
                                                                });
                                                              });
                                                            },
                                                )
                                        ],
                                      ),
                                      bottomSheet: contactsProvider
                                                      .searchingcontactsindatabase ==
                                                  true ||
                                              iscreatingbroadcast == true ||
                                              _selectedList.length == 0
                                          ? SizedBox(
                                              height: 0,
                                              width: 0,
                                            )
                                          : Container(
                                              color: Thm.isDarktheme(
                                                      widget.prefs)
                                                  ? corncallDIALOGColorDarkMode
                                                  : corncallDIALOGColorLightMode,
                                              padding: EdgeInsets.only(top: 6),
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              height: 97,
                                              child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  itemCount: _selectedList
                                                      .reversed
                                                      .toList()
                                                      .length,
                                                  itemBuilder:
                                                      (context, int i) {
                                                    return Stack(
                                                      children: [
                                                        Container(
                                                          width: 80,
                                                          padding:
                                                              const EdgeInsets
                                                                      .fromLTRB(
                                                                  11,
                                                                  10,
                                                                  12,
                                                                  10),
                                                          child: Column(
                                                            children: [
                                                              customCircleAvatar(
                                                                  url: _selectedList
                                                                      .reversed
                                                                      .toList()[
                                                                          i]
                                                                      .photoURL,
                                                                  radius: 20),
                                                              SizedBox(
                                                                height: 7,
                                                              ),
                                                              Text(
                                                                _selectedList
                                                                    .reversed
                                                                    .toList()[i]
                                                                    .name,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    TextStyle(
                                                                  color: pickTextColorBasedOnBgColorAdvanced(Thm.isDarktheme(
                                                                          widget
                                                                              .prefs)
                                                                      ? corncallCONTAINERboxColorDarkMode
                                                                      : corncallCONTAINERboxColorLightMode),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Positioned(
                                                          right: 17,
                                                          top: 5,
                                                          child: new InkWell(
                                                            onTap: () {
                                                              setStateIfMounted(
                                                                  () {
                                                                _selectedList.remove(
                                                                    _selectedList
                                                                        .reversed
                                                                        .toList()[i]);
                                                              });
                                                            },
                                                            child:
                                                                new Container(
                                                              width: 20.0,
                                                              height: 20.0,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(2.0),
                                                              decoration:
                                                                  new BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                              child: Icon(
                                                                Icons.close,
                                                                size: 14,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ), //............
                                                          ),
                                                        )
                                                      ],
                                                    );
                                                  }),
                                            ),
                                      body: RefreshIndicator(
                                          onRefresh: () {
                                            return contactsProvider
                                                .fetchContacts(
                                                    context,
                                                    model,
                                                    widget.currentUserNo!,
                                                    widget.prefs);
                                          },
                                          child: contactsProvider
                                                          .searchingcontactsindatabase ==
                                                      true ||
                                                  iscreatingbroadcast == true
                                              ? loading()
                                              : contactsProvider
                                                          .alreadyJoinedSavedUsersPhoneNameAsInServer
                                                          .length ==
                                                      0
                                                  ? ListView(
                                                      shrinkWrap: true,
                                                      children: [
                                                          Padding(
                                                              padding: EdgeInsets.only(
                                                                  top: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .height /
                                                                      2.5),
                                                              child: Center(
                                                                child: Text(
                                                                    getTranslated(
                                                                        context,
                                                                        'nosearchresult'),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .center,
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            18,
                                                                        color:
                                                                            corncallGrey)),
                                                              ))
                                                        ])
                                                  : Padding(
                                                      padding: EdgeInsets.only(
                                                          bottom: _selectedList
                                                                      .length ==
                                                                  0
                                                              ? 0
                                                              : 80),
                                                      child: Stack(
                                                        children: [
                                                          FutureBuilder(
                                                              future: Future
                                                                  .delayed(Duration(
                                                                      seconds:
                                                                          2)),
                                                              builder: (c, s) => s
                                                                          .connectionState ==
                                                                      ConnectionState
                                                                          .done
                                                                  ? Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .topCenter,
                                                                      child:
                                                                          Padding(
                                                                        padding:
                                                                            EdgeInsets.all(30),
                                                                        child:
                                                                            Card(
                                                                          elevation:
                                                                              0.5,
                                                                          color:
                                                                              Colors.grey[100],
                                                                          child: Container(
                                                                              padding: EdgeInsets.fromLTRB(8, 10, 8, 10),
                                                                              child: RichText(
                                                                                textAlign: TextAlign.center,
                                                                                text: TextSpan(
                                                                                  children: [
                                                                                    WidgetSpan(
                                                                                      child: Padding(
                                                                                        padding: const EdgeInsets.only(bottom: 2.5, right: 4),
                                                                                        child: Icon(
                                                                                          Icons.contact_page,
                                                                                          color: corncallPRIMARYcolor.withOpacity(0.7),
                                                                                          size: 14,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    TextSpan(
                                                                                        text: getTranslated(this.context, 'nosavedcontacts'),
                                                                                        // text:
                                                                                        //     'No Saved Contacts available for this task',
                                                                                        style: TextStyle(color: corncallSECONDARYolor.withOpacity(0.7), height: 1.3, fontSize: 13, fontWeight: FontWeight.w400)),
                                                                                  ],
                                                                                ),
                                                                              )),
                                                                        ),
                                                                      ),
                                                                    )
                                                                  : Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .topCenter,
                                                                      child: Padding(
                                                                          padding: EdgeInsets.all(30),
                                                                          child: CircularProgressIndicator(
                                                                            valueColor:
                                                                                AlwaysStoppedAnimation<Color>(corncallSECONDARYolor),
                                                                          )),
                                                                    )),
                                                          Container(
                                                            color: Thm.isDarktheme(
                                                                    widget
                                                                        .prefs)
                                                                ? corncallCONTAINERboxColorDarkMode
                                                                : corncallCONTAINERboxColorLightMode,
                                                            child: ListView
                                                                .builder(
                                                              physics:
                                                                  AlwaysScrollableScrollPhysics(),
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(10),
                                                              itemCount:
                                                                  contactsProvider
                                                                      .alreadyJoinedSavedUsersPhoneNameAsInServer
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      idx) {
                                                                String phone =
                                                                    contactsProvider
                                                                        .alreadyJoinedSavedUsersPhoneNameAsInServer[
                                                                            idx]
                                                                        .phone;
                                                                Widget? alreadyAddedUser = widget
                                                                            .isAddingWhileCreatingBroadcast ==
                                                                        true
                                                                    ? null
                                                                    : broadcastList
                                                                            .lastWhere((element) =>
                                                                                element.docmap[Dbkeys.broadcastID] ==
                                                                                widget.broadcastID)
                                                                            .docmap[Dbkeys.broadcastMEMBERSLIST]
                                                                            .contains(phone)
                                                                        ? SizedBox()
                                                                        : null;
                                                                return alreadyAddedUser ??
                                                                    FutureBuilder<
                                                                            LocalUserData?>(
                                                                        future: contactsProvider.fetchUserDataFromnLocalOrServer(
                                                                            widget
                                                                                .prefs,
                                                                            phone),
                                                                        builder: (BuildContext
                                                                                context,
                                                                            AsyncSnapshot<LocalUserData?>
                                                                                snapshot) {
                                                                          if (snapshot
                                                                              .hasData) {
                                                                            LocalUserData
                                                                                user =
                                                                                snapshot.data!;
                                                                            return Container(
                                                                              color: Thm.isDarktheme(widget.prefs) ? corncallCONTAINERboxColorDarkMode : corncallCONTAINERboxColorLightMode,
                                                                              child: Column(
                                                                                children: [
                                                                                  ListTile(
                                                                                    leading: customCircleAvatar(
                                                                                      url: user.photoURL,
                                                                                      radius: 22.5,
                                                                                    ),
                                                                                    trailing: Container(
                                                                                      decoration: BoxDecoration(
                                                                                        border: Border.all(color: corncallGrey, width: 1),
                                                                                        borderRadius: BorderRadius.circular(5),
                                                                                      ),
                                                                                      child: _selectedList.lastIndexWhere((element) => element.id == phone) >= 0
                                                                                          ? Icon(
                                                                                              Icons.check,
                                                                                              size: 19.0,
                                                                                              color: corncallPRIMARYcolor,
                                                                                            )
                                                                                          : Icon(
                                                                                              Icons.check,
                                                                                              color: Colors.transparent,
                                                                                              size: 19.0,
                                                                                            ),
                                                                                    ),
                                                                                    title: Text(user.name,
                                                                                        style: TextStyle(
                                                                                          color: pickTextColorBasedOnBgColorAdvanced(Thm.isDarktheme(widget.prefs) ? corncallCONTAINERboxColorDarkMode : corncallCONTAINERboxColorLightMode),
                                                                                        )),
                                                                                    subtitle: Text(phone, style: TextStyle(color: corncallGrey)),
                                                                                    contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                                                                                    onTap: () {
                                                                                      if (_selectedList.indexWhere((element) => element.id == phone) >= 0) {
                                                                                        _selectedList.removeAt(_selectedList.indexWhere((element) => element.id == phone));
                                                                                        setStateIfMounted(() {});
                                                                                      } else {
                                                                                        _selectedList.add(snapshot.data!);
                                                                                        setStateIfMounted(() {});
                                                                                      }
                                                                                    },
                                                                                  ),
                                                                                  Divider()
                                                                                ],
                                                                              ),
                                                                            );
                                                                          }
                                                                          return SizedBox();
                                                                        });
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )))));
            }))));
  }
}
