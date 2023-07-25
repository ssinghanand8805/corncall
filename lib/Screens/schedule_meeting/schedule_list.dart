//*************   © Copyrighted by Criterion Tech. *********************

import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corncall/Configs/Dbkeys.dart';
import 'package:corncall/Configs/Dbpaths.dart';
import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Configs/optional_constants.dart';
import 'package:corncall/Screens/call_history/callhistory.dart';
import 'package:corncall/Screens/schedule_meeting/utils/instant_meeting.dart';
import 'package:corncall/Screens/status/StatusView.dart';
import 'package:corncall/Screens/status/components/ImagePicker/image_picker.dart';
import 'package:corncall/Screens/status/components/TextStatus/textStatus.dart';
import 'package:corncall/Screens/status/components/VideoPicker/VideoPicker.dart';
import 'package:corncall/Screens/status/components/circleBorder.dart';
import 'package:corncall/Screens/status/components/formatStatusTime.dart';
import 'package:corncall/Screens/status/components/showViewers.dart';
import 'package:corncall/Services/Admob/admob.dart';
import 'package:corncall/Services/Providers/SmartContactProviderWithLocalStoreData.dart';
import 'package:corncall/Services/Providers/StatusProvider.dart';
import 'package:corncall/Services/Providers/Observer.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Models/DataModel.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart' as compress;

import '../../Models/scheduleMeeting.dart';
import '../../Services/Providers/schdule_history_provider.dart';
import '../meeting/meeting2.dart';
import './utils/InfiniteListView.dart';
import 'create_meeting.dart';

class ScheduleList extends StatefulWidget {
  const ScheduleList(
      {required this.userphone, required this.model, required this.prefs});
  final String? userphone;
  final DataModel? model;
  final SharedPreferences prefs;

  @override
  _ScheduleListState createState() => new _ScheduleListState();
}

class _ScheduleListState extends State<ScheduleList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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

  late Stream myStatusUpdates;
  final BannerAd myBanner = BannerAd(
    adUnitId: getBannerAdUnitId()!,
    size: AdSize.banner,
    request: AdRequest(),
    listener: BannerAdListener(),
  );
  AdWidget? adWidget;
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  @override
  initState() {
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
    // myStatusUpdates = FirebaseFirestore.instance
    //     .collection(DbPaths.collectionnstatus)
    //     .doc(widget.currentUserNo)
    //     .snapshots();
    // // forward();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final observer = Provider.of<Observer>(this.context, listen: false);
    //   if (widget.isShowAddStatusOnFirst == true &&
    //       observer.isAllowCreatingStatus == true) {
    //     Navigator.push(
    //         this.context,
    //         MaterialPageRoute(
    //             builder: (context) => StatusImageEditor(
    //               prefs: widget.prefs,
    //               callback: (v, d) async {
    //                 Navigator.of(context).pop();
    //                 await uploadFile(
    //                     filename: DateTime.now()
    //                         .millisecondsSinceEpoch
    //                         .toString(),
    //                     type: Dbkeys.statustypeIMAGE,
    //                     file: d,
    //                     caption: v);
    //               },
    //               title: getTranslated(context, 'createstatus'),
    //             )));
    //   }
    //   if (IsBannerAdShow == true && observer.isadmobshow == true) {
    //     myBanner.load();
    //     adWidget = AdWidget(ad: myBanner);
    //     setState(() {});
    //   }
    //   // Interstital Ads
    //   if (IsInterstitialAdShow == true && observer.isadmobshow == true) {
    //     Future.delayed(const Duration(milliseconds: 3000), () {
    //       _createInterstitialAd();
    //     });
    //   }
    // });
  }

  // forward() {
  //   Future.delayed(const Duration(milliseconds: 500), () {
  //     final observer = Provider.of<Observer>(this.context, listen: false);
  //     if (widget.isShowAddStatusOnFirst == true &&
  //         observer.isAllowCreatingStatus == true) {
  //       Navigator.push(
  //           this.context,
  //           MaterialPageRoute(
  //               builder: (context) => StatusImageEditor(
  //                     callback: (v, d) async {
  //                       Navigator.of(context).pop();
  //                       await uploadFile(
  //                           filename: DateTime.now()
  //                               .millisecondsSinceEpoch
  //                               .toString(),
  //                           type: Dbkeys.statustypeIMAGE,
  //                           file: d,
  //                           caption: v);
  //                     },
  //                     title: getTranslated(context, 'createstatus'),
  //                   )));
  //     }
  //   });
  // }
  final rng = Random();
  random() {
    var randomNumber = rng.nextInt(100000000).toString();
    return randomNumber;
    // print("random number: $randomNumber");
    // _idController = TextEditingController(text: randomNumber.toString());
  }

  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(rng.nextInt(_chars.length))));

  password() {
    final password = getRandomString(6);
    return password;
    // _pwController.text = password;
    // print("password : $password");
  }

  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();
  TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  @override
  void dispose() {
    super.dispose();
    if (IsInterstitialAdShow == true) {
      _interstitialAd!.dispose();
    }
    if (IsBannerAdShow == true) {
      myBanner.dispose();
    }
  }

  GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    final observer = Provider.of<Observer>(this.context, listen: false);
    return Consumer<FirestoreDataProviderScheduleHISTORY>(
      builder: (context, firestoreDataProvider, _) => Scaffold(
        key: _scaffold,
        backgroundColor: Thm.isDarktheme(widget.prefs)
            ? corncallCONTAINERboxColorDarkMode
            : Colors.white,
        bottomSheet: IsBannerAdShow == true &&
                observer.isadmobshow == true &&
                adWidget != null
            ? Container(
                height: 60,
                margin: EdgeInsets.only(
                    bottom: Platform.isIOS == true ? 25.0 : 5, top: 0),
                child: Center(child: adWidget),
              )
            : SizedBox(
                height: 0,
              ),
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
              bottom: IsBannerAdShow == true && observer.isadmobshow == true
                  ? 60
                  : 0),
          child: FloatingActionButton(
              heroTag: "dfsf4e8t4yt834",
              backgroundColor: corncallREDbuttonColor,
              child: Icon(
                Icons.add,
                size: 30.0,
                color: corncallWhite,
              ),
              onPressed: () {
              //_displayTextInputDialog(context);
                String id =  random();
                String pas = password();
                random() ;
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => InstantMeeting(
                        prefs: widget.prefs,
                        id: id, password: pas,))
                );
              }),
        ),
        body: Column(
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => MeetingForm(
                        prefs: widget.prefs,
                        currentuseruid: widget.userphone)));
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                      border: Border.all(color: Thm.isDarktheme(widget.prefs)
                          ? corncallAPPBARcolorDarkMode
                          : corncallAPPBARcolorLightMode,)
                  ),
                  // color: Theme.of(context).brightness == Brightness.light
                  //     ? corncallOurchatcolor.withOpacity(0.8)
                  //     : corncallOurchatcolor.withOpacity(0.8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text( getTranslated(
                            context, 'ScheduleMeeting'),
                            style: TextStyle(
                                color: corncallGrey,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                      ),
                      SvgPicture.asset("assets/images/meetingIcon.svg",),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Consumer<FirestoreDataProviderScheduleHISTORY>(
                builder: (context, contactsProvider, _child) {
              List<ScheduleMeeting> finalScheduleList = [];

              for (var doc in contactsProvider.recievedDocs) {
                ScheduleMeeting scheduleMeeting = ScheduleMeeting.fromMap(doc);
                finalScheduleList.add(scheduleMeeting);
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: finalScheduleList.length,
                  itemBuilder: (context, index) {
                    var schedule = finalScheduleList[index];
                    bool isExpire = false;

                    DateTime startTime = DateTime.parse(schedule.startTime.toString());
                    var currentTime = DateTime.now();
                    var endTime = startTime.add(Duration(minutes: int.parse(schedule.duration.toString())));

                    if (currentTime.isBefore(startTime)) {
                      print("Event is yet to come");
                      isExpire = true;
                    } else if (currentTime.isAfter(endTime)) {
                      print("Event has expired");
                      isExpire = true;
                      print(isExpire);
                    } else {
                      print("Event is ongoing");
                    }

                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0,right: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade800,
                              width: 1,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  // Navigate to edit tasks view
                                  // Navigator.of(context).push(
                                  //   MaterialPageRoute(
                                  //     builder: (context) => EditTasksView(
                                  //       meetingData: snapshot,
                                  //       index: index,
                                  //     ),
                                  //   ),
                                  // );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      schedule.title.toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      schedule.hostName.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Meeting Id: ${schedule.meetingId}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  schedule.startTime.toString().substring(0, 16),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 10),
                            !isExpire
                                ? InkWell(
                              onTap: () {

                                Navigator
                                    .of(context)
                                    .push(MaterialPageRoute(
                                  builder: (context) =>
                                      Meeting(
                                        room: int.parse(schedule.meetingId.toString()), prefs: widget.prefs, pin: schedule.meetingPassword.toString(), isAudio: false, defaultMute: false,),
                                ));
                                // Join the meeting
                                // Future(() => Navigator.of(context).push(MaterialPageRoute(
                                //   builder: (context) => Meeting(
                                //     room: int.parse(schedule.meetingId.toString()),
                                //     pin: schedule.meetingPassword.toString(),
                                //     isAudio: true,
                                //     defaultMute: false,
                                //   ),
                                // )));
                                // Navigator.pop(context);
                                // clearText();
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: SplashBackgroundSolidColor,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  "Join",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                                : Container(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );

                  // return  InfiniteListView(
              //    currentuseruid: widget.userphone,
              //    prefs: widget.prefs,
              //    firestoreDataProviderScheduleHISTORY: contactsProvider,
              //    datatype: 'SCHEDULEHISTORY',
              //    refdata: FirebaseFirestore.instance
              //        .collection(DbPaths.collectionusers)
              //        .doc(widget.userphone)
              //        .collection('scheduleMeeting')
              //    // .orderBy('startTime', descending: true)
              //        .limit(14),
              //    list: ListView.builder(
              //        physics: const NeverScrollableScrollPhysics(),
              //        shrinkWrap: true,
              //        itemCount: firestoreDataProvider.recievedDocs.length,
              //        itemBuilder: (BuildContext context, int i) {
              //          var dc = firestoreDataProvider.recievedDocs[i];
              //          // var schedule = snapshot.data![index];
              //          bool isExpire = false; //ref.watch(isExpireProvider);
              //          DateTime startTime =
              //          DateTime.parse(dc['startTime'].toString());
              //          var currentTime = DateTime.now();
              //          var endTime = startTime.add(
              //              Duration(
              //                  minutes: int.parse(dc['duration'].toString())));
              //          if (currentTime.isBefore(startTime)) {
              //            print("Event is yet to come");
              //            isExpire = true;
              //          } else if (currentTime.isAfter(endTime)) {
              //            print("Event has expired");
              //            isExpire = true;
              //            print(isExpire);
              //          } else {
              //            print("Event is ongoing");
              //          }
              //
              //          return Padding(
              //            padding: const EdgeInsets.only(left: 10.0, right: 10),
              //            child: Column(
              //              children: [
              //                Column(
              //                  children: [
              //                    Row(
              //                      children: [
              //                        Expanded(
              //                          child: InkWell(
              //                            onTap: () {
              //                              // Navigator.of(context).push(
              //                              //     MaterialPageRoute(
              //                              //         builder: (context) =>
              //                              //             EditTasksView(
              //                              //               meetingData: snapshot,
              //                              //               index: index,
              //                              //
              //                              //             )));
              //                            },
              //                            child: Padding(
              //                              padding: const EdgeInsets.only(
              //                                  top: 8.0),
              //                              child: Row(
              //                                children: [
              //                                  Column(
              //                                    crossAxisAlignment:
              //                                    CrossAxisAlignment.start,
              //                                    children: [
              //                                      Text(
              //                                        dc['title'].toString(),
              //                                      ),
              //                                      const SizedBox(
              //                                        height: 5,
              //                                      ),
              //                                      Text(
              //                                        dc['hostName'].toString(),
              //                                      ),
              //                                    ],
              //                                  ),
              //                                  const Spacer(),
              //                                  Column(
              //                                    crossAxisAlignment:
              //                                    CrossAxisAlignment.start,
              //                                    children: [
              //                                      Text(
              //                                        "Meeting Id: ${dc['meetingId']}",
              //                                      ),
              //                                      const SizedBox(
              //                                        height: 5,
              //                                      ),
              //                                      Text(
              //                                        dc['startTime']
              //                                            .toString(),
              //                                      ),
              //                                    ],
              //                                  ),
              //                                ],
              //                              ),
              //                            ),
              //                          ),
              //                        ),
              //                        !isExpire
              //                            ? InkWell(
              //                          onTap: () {
              //                            // Future(() => Navigator
              //                            //     .of(context)
              //                            //     .push(MaterialPageRoute(
              //                            //     builder: (context) =>
              //                            //         Meeting(
              //                            //             room: int
              //                            //                 .parse(schedule
              //                            //                 .meetingId
              //                            //                 .toString()),
              //                            //             pin: schedule
              //                            //                 .meetingPassword
              //                            //                 .toString(),
              //                            //             isAudio: true,
              //                            //             defaultMute:
              //                            //             false))));
              //                            //Navigator.pop(context);
              //
              //                            // clearText();
              //                          },
              //                          child: Padding(
              //                            padding:
              //                            const EdgeInsets.only(left: 8.0),
              //                            child: Column(
              //                              children: const [
              //                                CircleAvatar(
              //                                  // backgroundColor:
              //                                  // greenColor,
              //                                    radius: 18,
              //                                    child: Text(
              //                                      "Join",
              //                                      style: TextStyle(
              //                                          color: Colors.white,
              //                                          fontSize: 14),
              //                                    )),
              //                              ],
              //                            ),
              //                          ),
              //                        )
              //                            : Container(),
              //                      ],
              //                    ),
              //                  ],
              //                ),
              //                Divider(
              //                    color:
              //                    Theme
              //                        .of(context)
              //                        .brightness == Brightness.light
              //                        ? Colors.grey.shade300
              //                        : Colors.grey.shade800,
              //                    indent: 0),
              //                const SizedBox(
              //                  height: 5,
              //                ),
              //              ],
              //            ),
              //          );
              //        }),
              //  );
            }),
          ],
        ),
      ),
    );
  }

  void clearText() {
    isFresh = true;
    _idController.clear();
    _pwController.clear();
  }

  bool isFresh = true;
  Future<void> _displayTextInputDialog(context) async {
    if (isFresh) {
      password();
      random() ;
    }

    return showDialog(
        context: context,
        builder: (context) {
          bool isSwitched = true;
          bool check = true;
          return StatefulBuilder(builder: (context, setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                scrollable: true,
                title: Center(child: const Text('Join Meeting')),
                content: Column(
                  children: [
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white38, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white38, width: 2.0),
                          ),
                          hintText: "Id"),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      controller: _pwController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white38, width: 2.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.white38, width: 2.0),
                          ),
                          hintText: "password"),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        const Text("Join with Video"),
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
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        const Text("Default  mute"),
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
                          children: const [
                            Icon(Icons.share, color: Colors.blue),
                            SizedBox(
                              width: 10,
                            ),
                            Text("share")
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                actions: <Widget>[
                  Center(
                    child: MaterialButton(
                      color: corncallREDbuttonColor,
                      textColor: Colors.white,
                      child: const Text('CANCEL'),
                      onPressed: () {
                        setState(() {
                          Navigator.pop(context);
                          clearText();
                        });
                      },
                    ),
                  ),
                  RoundedLoadingButton(
                    color: SplashBackgroundSolidColor,
                    width: 150,
                    controller: _btnController,
                    onPressed: () async {
                      if (_idController.value.text.isEmpty ||
                          _pwController.value.text.isEmpty) {
                        Fluttertoast.showToast(
                            msg: "Please fill all fields",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 1,
                            textColor: Colors.white,
                            fontSize: 16.0);
                        _btnController.reset();
                      } else {
                        Navigator
                            .of(context)
                            .push(MaterialPageRoute(
                          builder: (context) =>
                              Meeting(
                                room: int.parse( _idController.text.toString()), prefs: widget.prefs, pin: _pwController.text, isAudio: isSwitched, defaultMute: check,),
                        ));
                        // await AuthApi.createRoomApi(
                        //     int.parse(_idController.text.toString()));
                        // Future(
                        //         () => Navigator.of(context).push(MaterialPageRoute(
                        //         builder: (context) => Meeting(
                        //             key: MeetingRoomService.key,
                        //             room: int.parse("1234"
                        //               //  _idController.text.toString()
                        //             ),
                        //             pin: _pwController.text,
                        //             isAudio: isSwitched,
                        //             defaultMute: check))));
                      }
                    },
                    child: const Text('Create/Join',
                        style: TextStyle(color: Colors.white)),
                  )
                  // MaterialButton(
                  //   color: Colors.green,
                  //   textColor: Colors.white,
                  //   child: const Text('Create/Join'),
                  //   onPressed: () async {
                  //     if (_idController.value.text.isEmpty ||
                  //         _pwController.value.text.isEmpty) {
                  //       Fluttertoast.showToast(
                  //           msg: "Please fill all fields",
                  //           toastLength: Toast.LENGTH_SHORT,
                  //           gravity: ToastGravity.CENTER,
                  //           timeInSecForIosWeb: 1,
                  //           textColor: Colors.white,
                  //           fontSize: 16.0);
                  //     } else {
                  //       await AuthApi.createRoomApi(int.parse(
                  //           _idController.text.toString()));
                  //       Future(() => Navigator.of(context).push(
                  //           MaterialPageRoute(
                  //               builder: (context) => MeetingRoom(
                  //                 key: MeetingRoomService.key,
                  //                   userName: userName,
                  //                   room: int.parse( _idController.text.toString()),
                  //                   pin: _pwController.text,
                  //                   isAudio: isSwitched,
                  //                   defaultMute: check))));
                  //     }
                  //   },
                  //   // onPressed: () {
                  //   //     Navigator.pop(context);
                  //   //   clearText();
                  //   // },
                  // ),
                ],
              ),
            );
          });
        });
  }

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
}
