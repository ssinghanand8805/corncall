import 'dart:convert';
import 'dart:math';

import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pip_view/pip_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:whiteboard/whiteboard.dart';

// import '../main.dart';
// import '../../../../mobile_layout_screen.dart';
// import '../../../../models/call.dart';
// import '../../../../models/user_model.dart';
// import '../../../../models/user_model_with_check.dart';
// import '../../../auth/controller/auth_controller.dart';
// import '../../../select_contacts/controller/select_contact_controller.dart';
// import '../../controller/call_controller.dart';
import '../../Configs/Dbkeys.dart';
import '../../Configs/Dbpaths.dart';
import '../../Services/Providers/user_provider.dart';
import 'room_model.dart';
import 'participants_page.dart';
import 'package:janus_client/janus_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import '../calling_screen/util.dart';
import 'Meeting_User_Model.dart';
// const MethodChannel _channel = MethodChannel('network_speed_channel');
//
// class NetworkSpeedChannel {
//   static Stream<double> listenNetworkSpeed() {
//     print('EEEEEEEEEEE');
//     return _channel.invokeMethod('listenNetworkSpeed').asStream().cast<double>();
//   }
// }
// final userListProvider =
// StateNotifierProvider<userListNotifier, List<UserModelCheck>>((ref) {
//   return userListNotifier();
// });
//
// class userListNotifier extends StateNotifier<List<UserModelCheck>> {
//   userListNotifier() : super([]);
//
//   void add(UserModelCheck user) {
//     state = [...state, user];
//   }
//
//   void update(UserModelCheck user, bool status)
//   {
//     final updatedList = <UserModelCheck>[];
//
//     for(var i=0;i < state.length;i++)
//     {
//
//       if(state[i].uid == user.uid)
//       {
//         UserModelCheck usr = UserModelCheck(
//             name: user.name,
//             uid: user.uid,
//             profilePic:  user.profilePic,
//             isOnline:  user.isOnline,
//             phoneNumber:  user.phoneNumber,
//             deviceToken:  user.deviceToken,
//             profileQuote:  user.profileQuote,
//             groupId:  user.groupId,
//             isChecked:  status, isDialed: user.isDialed, dialedTime: user.dialedTime, callStatus: user.callStatus, isOnlyAudioDialed: user.isOnlyAudioDialed);
//         updatedList.add(usr);
//       }
//       else
//       {
//         updatedList.add(state[i]);
//       }
//     }
//     state = updatedList;
//   }
//
//   void updateCallStatus(UserModelCheck user, bool isDialed,DateTime dialedTime,String callStatus,bool isOnlyAudioDialed,)
//   {
//     final updatedList = <UserModelCheck>[];
//
//     for(var i=0;i < state.length;i++)
//     {
//
//       if(state[i].uid == user.uid)
//       {
//         UserModelCheck usr = UserModelCheck(
//             name: user.name,
//             uid: user.uid,
//             profilePic:  user.profilePic,
//             isOnline:  user.isOnline,
//             phoneNumber:  user.phoneNumber,
//             deviceToken:  user.deviceToken,
//             profileQuote:  user.profileQuote,
//             groupId:  user.groupId,
//             isChecked:  user.isChecked, isDialed: isDialed, dialedTime: dialedTime, callStatus: callStatus, isOnlyAudioDialed: isOnlyAudioDialed);
//         updatedList.add(usr);
//       }
//       else
//       {
//         updatedList.add(state[i]);
//       }
//     }
//     state = updatedList;
//   }
//
// }
//
//
// /////////////////////
// final participantsListProvider =
// StateNotifierProvider<participantsListNotifier, List<MeetingUserList>>((ref) {
//   return participantsListNotifier();
// });
//
// class participantsListNotifier extends StateNotifier<List<MeetingUserList>> {
//   participantsListNotifier() : super([]);
//
//   void add(MeetingUserList user) {
//     if (!state.contains(user)) {
//       state = [...state, user];
//     }
//   }
//
//   void update(MeetingUserList user, bool status)
//   {
//     final updatedList = <MeetingUserList>[];
//
//     for(var i=0;i < state.length;i++)
//     {
//
//       if(state[i].id == user.id)
//       {
//
//         MeetingUserList usr = MeetingUserList(
//             id: user.id,
//             display: user.display,
//             ispublisher: user.ispublisher,
//             isTalking: user.isTalking,
//             isHost: user.isHost,
//             isJoined: user.isJoined,
//             isVideoOn: user.isVideoOn,
//             isAudioOn: user.isAudioOn,
//             isModerator: user.isModerator,
//             profile: user.profile
//         );
//         updatedList.add(usr);
//       }
//       else
//       {
//         updatedList.add(state[i]);
//       }
//     }
//     state = updatedList;
//   }
//
// }
//
//
// class BandwidthData {
//   final String outgoingBandwidth;
//   final String incomingBandwidth;
//
//   BandwidthData(
//       {required this.outgoingBandwidth, required this.incomingBandwidth});
// }
//
class Meeting extends  StatefulWidget {
  // static const String routeName = '/video-call';
  final SharedPreferences prefs;
  final int room;
  final String pin;
  final bool isAudio;
  final bool defaultMute;
  const Meeting({
    Key? key,
    required this.prefs,
    required this.room,
    required this.pin,
    required this.isAudio,
    required this.defaultMute,
  }) : super(key: key);
  @override
  _MeetingState createState() => _MeetingState();
}




class _MeetingState extends State<Meeting> {
  int pageIndex = 2;
  JanusClient? j;
  RestJanusTransport? rest;
  WebSocketJanusTransport? ws;
  JanusSession? session;
  JanusSession? session2;
  final DrawingController _drawingController = DrawingController();

  bool front = true;
  dynamic fullScreenDialog;
  bool screenSharing = false;
  bool joined = false;
  String? myUsername;
  String? myPin;
  List<String> joinedUserList = [];
  List<String> alreadyJoinUserList = [];
  final List<int> selectedIndex = [];
  TextEditingController username = TextEditingController(text: 'shivansh');
  TextEditingController room = TextEditingController(text: '1234');
  TextEditingController pin = TextEditingController();
  dynamic joiningDialog;
  GlobalKey<FormState> joinForm = GlobalKey();
  bool videoEnabled = true;
  bool isAnyOneShareScreen = false;
  bool isAnyOneShareWhiteboard = false;
  bool isMeRaisedHand = false;
  bool isWhiteboardDrawByMe = false;
  bool isWhiteboardDrawByHuman = false;
  String currentPresenter = '';
  bool audioEnabled = true;
  late Timer timer;
  int elapsedSeconds = 0;
  late UserModel userInfo;
  int? myId;
  int? myPvtId;
  List<String> raiseHandUserList = [];
  get screenShareId => myId! + myId! + int.parse("1");
  int? myRoom = 1234;
  bool speakerOn = false;
  JanusVideoRoomPlugin? videoPlugin;
  JanusVideoRoomPlugin? screenPlugin;
  JanusVideoRoomPlugin? remotePlugin;
  late JanusTextRoomPlugin textRoom;
  late StreamRenderer localScreenSharingRenderer;
  late StreamRenderer localVideoRenderer;
  int incomingBandwidth = 0;
  int outgoingBandwidth = 0;
  List<MediaDeviceInfo>? _mediaDevicesList;
  Future<void> _refreshMediaDevices() async {
    var devices = await navigator.mediaDevices.enumerateDevices();
    setState(() {
      _mediaDevicesList = devices;
    });
  }

  String encryptString(String input) {
    String encrypted = '';
    for (int i = 0; i < input.length; i++) {
      int codePoint = input.codeUnitAt(i);
      encrypted += codePoint.toString();
    }
    return encrypted;
  }

  String decryptString(String input) {
    String decrypted = '';
    for (int i = 0; i < input.length; i += 5) {
      String codePointStr = input.substring(i, i + 5);
      int codePoint = int.parse(codePointStr);
      decrypted += String.fromCharCode(codePoint);
    }
    return decrypted;
  }

  // StreamController<BandwidthData> bandwidthStreamController =
  //     StreamController<BandwidthData>.broadcast();
  // Stream<BandwidthData> get bandwidthStream => bandwidthStreamController.stream;
  String currentVideoQuality = 'Auto';
  var canvasDataHistory = null;
  String whiteBoardImageUrl =
      "https://incompetech.com/graphpaper/plain/Axis%20Graphing%205mm.png";
  VideoRoomPluginStateManager videoState = VideoRoomPluginStateManager();
  // void updateBandwidthData() {
  //   // whiteBoardController.convertToImage();
  //   // Simulate updating the bandwidth values
  //   String readableIncomingBandwidth = '';
  //
  //   if (incomingBandwidth < 1024) {
  //     var d = incomingBandwidth.toStringAsFixed(2);
  //     readableIncomingBandwidth = '$d bytes';
  //   } else if (incomingBandwidth < 1024 * 1024) {
  //     double kb = incomingBandwidth / 1024;
  //     var d = kb.toStringAsFixed(2);
  //     readableIncomingBandwidth = '$d KB';
  //   } else if (incomingBandwidth < 1024 * 1024 * 1024) {
  //     double mb = incomingBandwidth / (1024 * 1024);
  //     var d = mb.toStringAsFixed(2);
  //     readableIncomingBandwidth = '$d MB';
  //   } else {
  //     double gb = incomingBandwidth / (1024 * 1024 * 1024);
  //     var d = gb.toStringAsFixed(2);
  //     readableIncomingBandwidth = '$d GB';
  //   }
  //
  //   String readableOutgoingBandwidth = '';
  //
  //   if (outgoingBandwidth < 1024) {
  //     var d = outgoingBandwidth.toStringAsFixed(2);
  //     readableOutgoingBandwidth = '$d bytes';
  //   } else if (outgoingBandwidth < 1024 * 1024) {
  //     double kb = outgoingBandwidth / 1024;
  //     var d = kb.toStringAsFixed(2);
  //     readableOutgoingBandwidth = '$d KB';
  //   } else if (outgoingBandwidth < 1024 * 1024 * 1024) {
  //     double mb = outgoingBandwidth / (1024 * 1024);
  //     var d = mb.toStringAsFixed(2);
  //     readableOutgoingBandwidth = '$d MB';
  //   } else {
  //     double gb = outgoingBandwidth / (1024 * 1024 * 1024);
  //     var d = gb.toStringAsFixed(2);
  //     readableOutgoingBandwidth = '$d GB';
  //   }
  //   BandwidthData bandwidthData = BandwidthData(
  //     outgoingBandwidth: readableOutgoingBandwidth,
  //     incomingBandwidth: readableIncomingBandwidth,
  //   );
  //
  //   bandwidthStreamController.sink.add(bandwidthData);
  // }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (mounted) {
      await initialize();

      autoJoinRoom();
      startTimer();

    }
  }

  initLocalMediaRenderer() {
    localScreenSharingRenderer = StreamRenderer('localScreenShare');
    localVideoRenderer = StreamRenderer('local');
    _drawingController.realPainter!.addListener(() {
      var d = _drawingController.getJsonList();
      print(d);
      if (isWhiteboardDrawByHuman) {
        sendWhiteBoardData(d);
      }
    });
  }

  sendWhiteBoardData(data) async {
    var msg = {
      "type": "whiteboardEvent",
      "data": {
        "type": "drawing",
        "data": data,
        "feedId": myId.toString(),
        "backGroundType": "image",
        "backGroundUrl":
            "https://gist.githubusercontent.com/tatsuyasusukida/1261585e3422da5645a1cbb9cf8813d6/raw/0996cf54461f77f335a395145e8c1764533f7989/img-check-01.png",
      }
    };
    await textRoom.sendMessage(myRoom, json.encode(msg));
    setIsWhiteboardDrawByHuman(false);
  }

  autoJoinRoom() async {
    myRoom = int.parse(widget.room.toString());
    // myPin = widget.pin.toString();
    myUsername = userInfo!.name.toString();
    print("dddddddddddddddddddd${myRoom.toString()}");
    setState(() {
      this.joined = true;
    });

    await joinRoom();
  }

  printLongString(String text) {
    final RegExp pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern
        .allMatches(text)
        .forEach((RegExpMatch match) => print(match.group(0)));
  }

  attachPlugin({bool pop = false}) async {
    JanusVideoRoomPlugin? videoPlugin =
        await session?.attach<JanusVideoRoomPlugin>();
    await videoPlugin!.initDataChannel();
    videoPlugin?.data!.listen((event) {
      print("********##########${event}");
    });
    videoPlugin?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      print("~~~~~~~~~~~~~~~~~~~~~~${data}");
      if (data is VideoRoomJoinedEvent) {
        myPvtId = data.privateId;
        var ses = await videoPlugin.createOffer(
            audioRecv: false,  videoRecv: false);
        // printLongString('RRRRRRRRR${ses.sdp}');
        // await videoPlugin.configure(bitrate: 3000000, sessionDescription: ses);

        await videoPlugin.publishMedia(bitrate: 3000000, offer: ses);
        //  videoPlugin!.publishMedia(offer: ses);
      }
      if (data is VideoRoomLeavingEvent) {
        unSubscribeTo(data.leaving!);
      }
      if (data is VideoRoomUnPublishedEvent) {
        unSubscribeTo(data.unpublished);
      }
      videoPlugin.handleRemoteJsep(event.jsep);
    });
    return videoPlugin;
  }

  // String getReadableIncomingBandwidth() {
  //   if (incomingBandwidth < 1024) {
  //     var d = incomingBandwidth.toStringAsFixed(2);
  //     return '$d bytes';
  //   } else if (incomingBandwidth < 1024 * 1024) {
  //     double kb = incomingBandwidth / 1024;
  //     var d = kb.toStringAsFixed(2);
  //     return '$d KB';
  //   } else if (incomingBandwidth < 1024 * 1024 * 1024) {
  //     double mb = incomingBandwidth / (1024 * 1024);
  //     var d = mb.toStringAsFixed(2);
  //     return '$d MB';
  //   } else {
  //     double gb = incomingBandwidth / (1024 * 1024 * 1024);
  //     var d = gb.toStringAsFixed(2);
  //     return '$d GB';
  //   }
  // }
  // String getReadableOutGoingBandwidth2() {
  //   if (outgoingBandwidth < 1024) {
  //     var d = outgoingBandwidth.toStringAsFixed(2);
  //
  //     return '$d bytes';
  //   } else if (outgoingBandwidth < 1024 * 1024) {
  //     double kb = outgoingBandwidth / 1024;
  //     var d = kb.toStringAsFixed(2);
  //     return '$d KB';
  //   } else if (outgoingBandwidth < 1024 * 1024 * 1024) {
  //     double mb = outgoingBandwidth / (1024 * 1024);
  //     var d = mb.toStringAsFixed(2);
  //     return '$d MB';
  //   } else {
  //     double gb = outgoingBandwidth / (1024 * 1024 * 1024);
  //     var d = gb.toStringAsFixed(2);
  //     return '$d GB';
  //   }
  // }
  // String getReadableOutGoingBandwidth() {
  //   // Existing code...
  //
  //   String readableOutgoingBandwidth = '';
  //
  //   if (outgoingBandwidth < 1024) {
  //     var d = outgoingBandwidth.toStringAsFixed(2);
  //     readableOutgoingBandwidth = '$d bytes';
  //   } else if (outgoingBandwidth < 1024 * 1024) {
  //     double kb = outgoingBandwidth / 1024;
  //     var d = kb.toStringAsFixed(2);
  //     readableOutgoingBandwidth = '$d KB';
  //   } else if (outgoingBandwidth < 1024 * 1024 * 1024) {
  //     double mb = outgoingBandwidth / (1024 * 1024);
  //     var d = mb.toStringAsFixed(2);
  //     readableOutgoingBandwidth = '$d MB';
  //   } else {
  //     double gb = outgoingBandwidth / (1024 * 1024 * 1024);
  //     var d = gb.toStringAsFixed(2);
  //     readableOutgoingBandwidth = '$d GB';
  //   }
  //
  //   outgoingBandwidthStreamController.sink.add(readableOutgoingBandwidth);
  //
  //   return readableOutgoingBandwidth;
  // }
  Future<UserModel?> getUserDetailsByIntId(int id) async
  {
    UserModel? user;
    var userData = await FirebaseFirestore.instance.collection(DbPaths.collectionusers).where(Dbkeys.intUserId,isEqualTo: id).limit(1).get();
    if (userData.size > 0) {
      List<DocumentSnapshot> documents = userData.docs;
      if (documents.isNotEmpty) {
        DocumentSnapshot document = documents.first;
        Map<String, dynamic> data = (document.data() as Map<String, dynamic>);
        user = UserModel.fromMap(data);
      }

    }
    return user;
  }
  initialize() async {

    var id = await widget.prefs.getInt(Dbkeys.intUserId);
    userInfo = (await getUserDetailsByIntId(id!))!;
    setState(() {
    });

    ws = WebSocketJanusTransport(url: 'ws://aws.edumation.in:8188/janus');

    j = JanusClient(
        transport: ws!,
        isUnifiedPlan: true,
        iceServers: [
          RTCIceServer(
              urls: "stun:stun1.l.google.com:19302",
              username: "",
              credential: "")
        ],
        loggerLevel: Level.FINE);
    session = await j?.createSession();
    textRoom = await session!.attach<JanusTextRoomPlugin>();
    initLocalMediaRenderer();
    // ws!.onDataSent.listen((data) {
    //   // Handle the event when data is sent
    //   outgoingBandwidth +=data.toString().length;
    //
    //   setState(() {
    //
    //   });
    //   updateBandwidthData();
    //   // NetworkSpeedChannel.listenNetworkSpeed().listen((event) {
    //   //   print('ddddddddddddd');
    //   //
    //   // });
    //   print('OOOOOOOOOOOOOOOO: $outgoingBandwidth');
    //   // Other actions or logic...
    // });
    // ws!.stream!.listen((event) {
    //   incomingBandwidth += event.toString().length;
    //   setState(() {});
    //   print("WWWWWWWWWWWWWWWWWW${getReadableIncomingBandwidth()}");
    //   updateBandwidthData();
    // });
  }

  Future<void> unSubscribeTo(int id) async {
    var feed = videoState.feedIdToDisplayStreamsMap[id];
    if (feed == null) return;
    setState(() {
      videoState.streamsToBeRendered.remove(id.toString());
    });
    videoState.feedIdToDisplayStreamsMap.remove(id.toString());
    // getParticipantList();
    await videoState.streamsToBeRendered[id]?.dispose();
    var unsubscribeStreams = (feed['streams'] as List<dynamic>).map((stream) {
      return SubscriberUpdateStream(
          feed: id, mid: stream['mid'], crossrefid: null);
    }).toList();
    if (remotePlugin != null)
      await remotePlugin?.update(unsubscribe: unsubscribeStreams);
    videoState.feedIdToMidSubscriptionMap.remove(id);
    // getParticipantList();
  }

  subscribeTo(List<List<Map>> sources) async {
    if (sources.isEmpty) {
      return;
    }
    if (remotePlugin == null) {
      remotePlugin = await session?.attach<JanusVideoRoomPlugin>();
      remotePlugin?.messages?.listen((payload) async {
        print("SSSSSSSSSSSSSS${payload}");
        JanusEvent event = JanusEvent.fromJson(payload.event);
        List<dynamic>? streams = event.plugindata?.data['streams'];
        streams?.forEach((element) {
          videoState.subStreamsToFeedIdMap[element['mid']] = element;
          // to avoid duplicate subscriptions
          if (videoState.feedIdToMidSubscriptionMap[element['feed_id']] == null)
            videoState.feedIdToMidSubscriptionMap[element['feed_id']] = {};
          videoState.feedIdToMidSubscriptionMap[element['feed_id']]
              [element['mid']] = true;
        });
        if (payload.jsep != null) {
          await remotePlugin?.handleRemoteJsep(payload.jsep);
          await remotePlugin?.start(myRoom);
        }
      });

      remotePlugin?.remoteTrack?.listen((event) async {
        print("KKKKKKKKKKKKKKKKKKKK");
        print({
          'mid': event.mid,
          'flowing': event.flowing,
          'id': event.track?.id,
          'kind': event.track?.kind
        });
        int? feedId = videoState.subStreamsToFeedIdMap[event.mid]?['feed_id'];
        String? displayName =
            videoState.feedIdToDisplayStreamsMap[feedId]?['display'];
        if (feedId != null) {
          if (videoState.streamsToBeRendered.containsKey(feedId.toString()) &&
              event.track?.kind == "audio") {
            var existingRenderer =
                videoState.streamsToBeRendered[feedId.toString()];
            existingRenderer?.mediaStream?.addTrack(event.track!);
            existingRenderer?.videoRenderer.srcObject =
                existingRenderer.mediaStream;
            existingRenderer?.videoRenderer.muted = false;
            setState(() {});
          }
          if (!videoState.streamsToBeRendered.containsKey(feedId.toString()) &&
              event.track?.kind == "video") {
            var localStream = StreamRenderer(feedId.toString());
            await localStream.init();
            localStream.mediaStream =
                await createLocalMediaStream(feedId.toString());
            localStream.mediaStream?.addTrack(event.track!);
            localStream.videoRenderer.srcObject = localStream.mediaStream;
            localStream.publisherName = displayName;
            localStream.publisherId = feedId.toString();
            var userDetails = await getUserDetailsByIntId(feedId!.toInt())!;

            if(userDetails != null)  {
              localStream.uid = userDetails!.uid;
              localStream.profile = userDetails!.profilePhoto;
            }
            setState(() {
              videoState.streamsToBeRendered
                  .putIfAbsent(feedId.toString(), () => localStream);
            });
          }
        }
      });
      List<PublisherStream> streams = sources
          .map((e) => e.map((e) => PublisherStream(
              feed: e['id'], mid: e['mid'], simulcast: e['simulcast'])))
          .expand((element) => element)
          .toList();
      await remotePlugin?.joinSubscriber(myRoom, streams: streams, pin: myPin);
      print('cccccccccccc${streams}');
      // getParticipantList();
      return;
    }
    List<Map>? added = null, removed = null;
    for (var streams in sources) {
      for (var stream in streams) {
        // If the publisher is VP8/VP9 and this is an older Safari, let's avoid video
        if (stream['disabled'] != null) {
          print("Disabled stream:");
          // Unsubscribe
          if (removed == null) removed = [];
          removed.add({
            'feed': stream['id'], // This is mandatory
            'mid': stream['mid'] // This is optional (all streams, if missing)
          });
          videoState.feedIdToMidSubscriptionMap[stream['id']]
              ?.remove(stream['mid']);
          videoState.feedIdToMidSubscriptionMap.remove(stream['id']);
          continue;
        }
        if (videoState.feedIdToMidSubscriptionMap[stream['id']] != null &&
            videoState.feedIdToMidSubscriptionMap[stream['id']]
                    [stream['mid']] ==
                true) {
          print("Already subscribed to stream, skipping:");
          continue;
        }

        // Subscribe
        if (added == null) added = [];
        added.add({
          'feed': stream['id'], // This is mandatory
          'mid': stream['mid'] // This is optional (all streams, if missing)
        });
        if (videoState.feedIdToMidSubscriptionMap[stream['id']] == null)
          videoState.feedIdToMidSubscriptionMap[stream['id']] = {};
        videoState.feedIdToMidSubscriptionMap[stream['id']][stream['mid']] =
            true;
      }
    }
    if ((added == null || added.length == 0) &&
        (removed == null || removed.length == 0)) {
      // Nothing to do
      return;
    }
    await remotePlugin?.update(
        subscribe: added
            ?.map((e) => SubscriberUpdateStream(
                feed: e['feed'], mid: e['mid'], crossrefid: null))
            .toList(),
        unsubscribe: removed
            ?.map((e) => SubscriberUpdateStream(
                feed: e['feed'], mid: e['mid'], crossrefid: null))
            .toList());
    // getParticipantList();
  }

  manageMuteUIEvents(String feedId, String kind, bool muted) async {
    print("!!!!!!!!sam");
    // int? feedId = videoState.subStreamsToFeedIdMap[mid]?['feed_id'];
    // if (feedId == null) {
    //   return;
    // }
    print(videoState.streamsToBeRendered);

    StreamRenderer renderer =
        videoState.streamsToBeRendered[feedId.toString()]!;
    setState(() {
      if (kind == 'audio') {
        print("#######${muted}");
        renderer.isAudioMuted = muted;
      } else {
        renderer.isVideoMuted = muted;
      }
    });
    print(
        "ddddd${videoState.streamsToBeRendered[feedId.toString()]!.isVideoMuted}");
    // getParticipantList();
  }

  bool isAudioAvailable(stream) {
    final audioTracks =
        stream.getTracks().where((track) => track.kind == 'audio');
    print("CCCCCCCCCCCCCCCC${stream.getAudioTracks()}");
    return audioTracks.isNotEmpty;
  }

  bool isVideoAvailable(MediaStream stream) {
    return stream.getVideoTracks().isNotEmpty;
  }

  attachSubscriberOnPublisherChange(List<dynamic>? publishers) async {
    print("###########################LA LA LA###########${publishers}");
    if (publishers != null) {
      List<List<Map>> sources = [];
      for (Map publisher in publishers) {
        if ([myId, screenShareId].contains(publisher['id'])) {
          continue;
        }
        print("ZZZZZZZZZZZZZZZZZZZZZZ");

        videoState.feedIdToDisplayStreamsMap[publisher['id']] = {
          'id': publisher['id'],
          'display': publisher['display'],
          'streams': publisher['streams'],


        };
        List<Map> mappedStreams = [];
        for (Map stream in publisher['streams'] ?? []) {
          // int? feedId = videoState.subStreamsToFeedIdMap[stream['mid']]?['feed_id'];
          // if(videoState.streamsToBeRendered.containsKey(feedId.toString()))
          //   {
          //     StreamRenderer renderer = videoState.streamsToBeRendered[feedId.toString()]!;
          //     bool isAudio = isAudioAvailable(renderer.mediaStream);
          //     // print("###########################LA LA LA###########${isAudio}");
          //   }
          //
          // if (stream['disabled'] == true) {
          //   manageMuteUIEvents(stream['mid'], stream['type'], true);
          // } else {
          //   manageMuteUIEvents(stream['mid'], stream['type'], false);
          // }
          if (videoState.feedIdToMidSubscriptionMap[publisher['id']] != null &&
              videoState.feedIdToMidSubscriptionMap[publisher['id']]
                      ?[stream['mid']] ==
                  true) {
            continue;
          }
          stream['id'] = publisher['id'];
          stream['display'] = publisher['display'];
          mappedStreams.add(stream);
        }
        sources.add(mappedStreams);
      }
      await subscribeTo(sources);
    }
  }

  eventMessagesHandler() async {
    videoPlugin?.messages?.listen((payload) async {
      print('!!!!!!!!!!!!${payload}');
      JanusEvent event = JanusEvent.fromJson(payload.event);
      List<dynamic>? publishers = event.plugindata?.data['publishers'];
      await attachSubscriberOnPublisherChange(publishers);
    });

    screenPlugin?.messages?.listen((payload) async {
      JanusEvent event = JanusEvent.fromJson(payload.event);
      List<dynamic>? publishers = event.plugindata?.data['publishers'];
      await attachSubscriberOnPublisherChange(publishers);
    });

    videoPlugin?.renegotiationNeeded?.listen((event) async {
      print('++++++++++++++++Retrying to connect publisher++++++++++++');
      if (videoPlugin?.webRTCHandle?.peerConnection?.signalingState !=
          RTCSignalingState.RTCSignalingStateStable) return;

      var offer = await videoPlugin?.createOffer(
          audioRecv: false,videoRecv: false);
      await videoPlugin?.configure(sessionDescription: offer);
    });
    screenPlugin?.renegotiationNeeded?.listen((event) async {
      if (screenPlugin?.webRTCHandle?.peerConnection?.signalingState !=
          RTCSignalingState.RTCSignalingStateStable) return;
      print('retrying to connect publisher');
      var offer = await screenPlugin?.createOffer(
          audioRecv: false,  videoRecv: false);
      await screenPlugin?.configure(sessionDescription: offer);
    });
  }

  joinRoom() async {
    myId = await widget.prefs.getInt(Dbkeys.intUserId);
    print("************${myId.toString()}");
    initLocalMediaRenderer();
    await textRoomsetup(myId.toString());
    videoPlugin = await attachPlugin(pop: false);
    // videoPlugin!.createRoom(3238);
    eventMessagesHandler();
    await localVideoRenderer.init();
    localVideoRenderer.mediaStream = await videoPlugin?.initializeMediaDevices(
        mediaConstraints: {'video': true, 'audio': true});
    localVideoRenderer.videoRenderer.srcObject = localVideoRenderer.mediaStream;
    localVideoRenderer.publisherName = "You";
    setState(() {
      videoState.streamsToBeRendered
          .putIfAbsent(myId.toString(), () => localVideoRenderer);
    });
    await videoPlugin?.joinPublisher(myRoom,
        displayName: userInfo!.name.toString(), id: myId, pin: myPin);
    print("***********************");
    initVideoMute();
    // await videoPlugin?.configureOther( {
    //     'request': 'configure',
    //     'video': true,
    //     'simulcast': true,
    //   },
    // );
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription: 'Screen Share is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
          backgroundColor: Colors.orange,
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'testButton', text: 'Test'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _startForegroundTask();
  }

  Future<bool> _startForegroundTask() async {
    // You can save data using the saveData function.
    //await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    var receivePort;
    if (await FlutterForegroundTask.isRunningService) {
      receivePort = await FlutterForegroundTask.restartService();
    } else {
      receivePort = await FlutterForegroundTask.startService(
        notificationTitle: 'Screen Share',
        notificationText: 'Screen Share ',
        callback: () {
          //FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
        },
      );
    }

/*     if (receivePort != null) {
      _receivePort = receivePort;
      _receivePort?.listen((message) {
        if (message is DateTime) {
          print('receive timestamp: $message');
        }
      });

      return true;
    } */

    return false;
  }

  screenShare() async {
    var idx = await findStreamKeyByDisplayNameContains();
    if (idx != -1) {
      return;
    }
    _initForegroundTask();
    setState(() {
      screenSharing = true;
    });
    initLocalMediaRenderer();
    screenPlugin = await session?.attach<JanusVideoRoomPlugin>();
    screenPlugin?.typedMessages?.listen((event) async {
      Object data = event.event.plugindata?.data;
      if (data is VideoRoomJoinedEvent) {
        myPvtId = data.privateId;
        (await screenPlugin?.configure(
            bitrate: 3000000,
            sessionDescription: await screenPlugin?.createOffer(
                audioRecv: false,
                videoRecv: false)));
      }
      if (data is VideoRoomLeavingEvent) {
        unSubscribeTo(data.leaving!);
      }
      if (data is VideoRoomUnPublishedEvent) {
        unSubscribeTo(data.unpublished);
      }
      screenPlugin?.handleRemoteJsep(event.jsep);
    });
    await localScreenSharingRenderer.init();
    localScreenSharingRenderer.mediaStream = await screenPlugin
        ?.initializeMediaDevices(
            mediaConstraints: {'video': true, 'audio': true},
            useDisplayMediaDevices: true);
    localScreenSharingRenderer.videoRenderer.srcObject =
        localScreenSharingRenderer.mediaStream;
    localScreenSharingRenderer.publisherName = "Your Screenshare";
    setState(() {
      videoState.streamsToBeRendered.putIfAbsent(
          localScreenSharingRenderer.id, () => localScreenSharingRenderer);
    });
    await screenPlugin?.joinPublisher(myRoom,
        displayName: userInfo!.name.toString() + "_screenshare",
        id: screenShareId,
        pin: myPin);
    setState(() {
      isAnyOneShareScreen = true;
    });
    var msg = {
      "type": "screenEvent",
      "data": {"type": 'start', "feedId": myId.toString()}
    };
    await textRoom.sendMessage(myRoom, json.encode(msg));
  }

  disposeScreenSharing() async {
    setState(() {
      screenSharing = false;
      isAnyOneShareScreen = false;
    });
    await screenPlugin?.unpublish();
    StreamRenderer? rendererRemoved;
    setState(() {
      rendererRemoved =
          videoState.streamsToBeRendered.remove(localScreenSharingRenderer.id);
    });
    var msg = {
      "type": "screenEvent",
      "data": {"type": 'stop', "feedId": myId.toString()}
    };
    await textRoom.sendMessage(myRoom, json.encode(msg));
    await rendererRemoved?.dispose();
    await screenPlugin?.hangup();
    screenPlugin = null;
  }

  switchCamera() async {
    print('ffff');
    setState(() {
      front = !front;
    });
    // ideoPlugin?.webRTCHandle!.localStream!.
    await videoPlugin?.switchCamera(deviceId: await getCameraDeviceId(front));
    localVideoRenderer = StreamRenderer('local');
    await localVideoRenderer.init();
    localVideoRenderer.videoRenderer.srcObject =
        videoPlugin?.webRTCHandle!.localStream;
    localVideoRenderer.publisherName = "My Camera";
    localVideoRenderer.uid = userInfo!.uid;
    localVideoRenderer.profile = userInfo!.profilePhoto;

    setState(() {
      videoState.streamsToBeRendered[myId.toString()] = localVideoRenderer;
    });
  }

  mute(RTCPeerConnection? peerConnection, String kind, bool enabled) async {
    var rm =localVideoRenderer;
    print( rm.mediaStream?.getVideoTracks());

    // for(var i=0;i<rm.length;i++)
    //   {
    //     var name = rm[i].
    //   }

    if (kind == 'audio' && rm!.mediaStream?.getAudioTracks()!.isNotEmpty == true) {
      rm.mediaStream?.getAudioTracks()[0].enabled = enabled;
      var msg = {
        "type": "event",
        "data": {"for": kind, "callBack": enabled}
      };
      await textRoom.sendMessage(myRoom, json.encode(msg));
    } else if (kind == 'video' && rm!.mediaStream?.getVideoTracks()!.isNotEmpty == true) {
      rm.mediaStream?.getVideoTracks()[0].enabled = enabled;
      var msg = {
        "type": "event",
        "data": {"for": kind, "callBack": enabled}
      };
      await textRoom.sendMessage(myRoom, json.encode(msg));
    }



    // var transreciever = (await peerConnection?.getTransceivers())?.where((element) => element.sender.track?.kind == kind).toList();
    // if (transreciever?.isEmpty == true) {
    //   return;
    // }
    // // videoPlugin?.sendData("hello");
    // print("*************${enabled}");
    // await transreciever?.first.setDirection(enabled ? TransceiverDirection.SendRecv : TransceiverDirection.Inactive);
    //
  }

  void topSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 500),
      barrierLabel: MaterialLocalizations.of(context).dialogLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (context, _, __) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.all(Radius.circular(15))),
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  color: Colors.black,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const SizedBox(
                        height: 15,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await callEnd();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            fixedSize:
                                const Size(90, 50), // specify width, height
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                              15,
                            ))),
                        child: const Text("End Meeting for all",
                            style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await callEnd();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade900,
                            fixedSize:
                                const Size(90, 50), // specify width, height
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                              15,
                            ))),
                        child: const Text("Leave Meeting ",
                            style: TextStyle(fontSize: 18)),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ).drive(Tween<Offset>(
            begin: Offset(0, -1.0),
            end: Offset.zero,
          )),
          child: child,
        );
      },
    );
  }

  callEnd() async {
    Navigator.pop(context);
    timer?.cancel();
    for (var feed in videoState.feedIdToDisplayStreamsMap.entries) {
      await unSubscribeTo(feed.key);
    }
    videoState.streamsToBeRendered.forEach((key, value) async {
      await value.dispose();
    });
    setState(() {
      videoState.streamsToBeRendered.clear();
      videoState.feedIdToDisplayStreamsMap.clear();
      videoState.subStreamsToFeedIdMap.clear();
      videoState.feedIdToMidSubscriptionMap.clear();
      this.joined = false;
      this.screenSharing = false;
    });
    await videoPlugin?.hangup();
    if (screenSharing) {
      await screenPlugin?.hangup();
    }

    await videoPlugin?.dispose();
    await screenPlugin?.dispose();
    await remotePlugin?.dispose();
    remotePlugin = null;
  }

  handleMessage(msg) {
    var data = json.decode(msg['text']);
    print('22');
    if (data['type'] == 'event') {
      print('ddddddddddddd');
      var ev = data['data'];
      var forUser = msg['from'];
      print(videoState!.streamsToBeRendered);
      print(forUser);
      manageMuteUIEvents(forUser, ev['for'], !ev['callBack']);
    }
    if (data['type'] == 'screenEvent' &&
        msg['from'].toString() != myId.toString()) {
      var ev = data['data'];
      // var forUser = msg['from'];
      bool val = ev['type'] == 'start' ? true : false;
      setState(() {
        isAnyOneShareScreen = val;
      });
    }
    if (data['type'] == 'whiteboardEvent' &&
        msg['from'].toString() != myId.toString()) {
      var ev = data['data'];
      if (ev['type'] == 'start') {
        setState(() {
          isAnyOneShareWhiteboard = true;
        });
      } else if (ev['type'] == 'end') {
        setState(() {
          isAnyOneShareWhiteboard = false;
        });
      } else if (ev['type'] == 'drawing') {
        // if (whiteBoardImageUrl != ev['backGroundUrl']) {
        //   setState(() {
        //     whiteBoardImageUrl = ev['backGroundUrl'];
        //   });
        // }

        print("remote SD${ev['data']}");
        // canvasDataHistory = ev['data'];
        ev['data'].forEach((element) {
          print(element);
          if (element != null) {
            _drawingController.addContent(SimpleLine.fromJson(element));
          }
        });

        // }
      }
    }

    if (data['type'] == 'raiseHandEvent' &&
        msg['from'].toString() != myId.toString()) {
      if (raiseHandUserList.contains(msg['from'].toString())) {
        raiseHandUserList.remove(msg['from'].toString());
      } else {
        raiseHandUserList.add(msg['from'].toString());
      }
      setState(() {});
    }
  }

  textRoomsetup(uName) async {
    await textRoom.setup();
    textRoom.onData?.listen((event) async {
      if (RTCDataChannelState.RTCDataChannelOpen == event) {
        textRoom.joinRoom(widget.room, uName, display: userInfo!.name);
      }
    });

    textRoom.data?.listen((event) {
      print('recieved message from data channel');
      dynamic data = parse(event.text);
      print(data);
      if (data != null) {
        if (data['textroom'] == 'message') {
          handleMessage(data);
          // setState(() {
          //   textMessages.add(data);
          // });
          // scrollToBottom();
        }

        if (data['textroom'] == 'leave') {
          // setState(() {
          //   textMessages.add({'from': data['username'], 'text': 'Left The Chat!'});
          //   Future.delayed(Duration(seconds: 1)).then((value) {
          //     userNameDisplayMap.remove(data['username']);
          //   });
          // });
          // scrollToBottom();
        }
        if (data['textroom'] == 'join') {
          // setState(() {
          //   userNameDisplayMap.putIfAbsent(data['username'], () => data['display']);
          //   textMessages.add({'from': data['username'], 'text': 'Joined The Chat!'});
          // });
          // scrollToBottom();
        }
        if (data['participants'] != null) {
          // (data['participants'] as List<dynamic>).forEach((element) {
          //   setState(() {
          //     userNameDisplayMap.putIfAbsent(element['username'], () => element['display']);
          //   });
          // });
        }
      }
    });
  }

  @override
  void dispose() async {
    super.dispose();
    await textRoom.leaveRoom(widget.room);
    session?.dispose();
    // ref.invalidate(userListProvider);
    // ref.invalidate(participantsListProvider);
    // ref.invalidate(participantsListProvider);
    textRoom.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer _timer) {
      setState(() {
        elapsedSeconds += 1;
      });
    });
  }

  String getFormattedTime() {
    int minutes = elapsedSeconds ~/ 60;
    int seconds = elapsedSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    print("yyyyyyyyyyyyyyyyyy${videoState.streamsToBeRendered.entries.length}");
    return PIPView(
      builder: (context, isFloating) {
        return WillPopScope(
          onWillPop: () {
            if (this.joined == false) {
              return new Future(() => true);
            } else {
             // PIPView.of(context)!.presentBelow(MobileLayoutScreen());
              return new Future(() => false);
            }
          },
          child: Scaffold(
            resizeToAvoidBottomInset: !isFloating,
            backgroundColor: Colors.black,
            appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.black,
                title: Container(
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              width: 0.5,
                              color: Colors.grey.withOpacity(0.3)))),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Text(outgoingBandwidth.toString()),
                        IconButton(
                          icon: Icon(
                            speakerOn ? Icons.volume_up : Icons.volume_off_sharp,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            setState(() {
                              speakerOn = !speakerOn!;
                            });
                            await Helper.setSpeakerphoneOn(speakerOn);
                            // await textRoom.sendMessage(myRoom, msg.toString());
                            // videoPlugin!.sendData('Hello');
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.switch_camera,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            switchCamera();

                            //  await videoPlugin?.configure(bitrate: 3);
                          },
                        ),
                        Text(
                          getFormattedTime(),
                          style: TextStyle(fontSize: 18),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.security_outlined,
                              color: Colors.green,
                              size: 15,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {});
                                bottomSheet2();
                              },
                              child: Text(
                                "CornCall",
                                style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),

                        GestureDetector(
                          onTap: () async {
                            if (joined) {
                              topSheet(context);
                              //    await callEnd();
                              return;
                            }
                            // Navigator.pushAndRemoveUntil(
                            //     context,
                            //     MaterialPageRoute(builder: (_) => HomePage()),
                            //         (route) => false);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 12, right: 12, top: 5, bottom: 5),
                              child: Text("Leave",
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )),
            body: getMainLayOutOfVideo(size),
            bottomNavigationBar: Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                      top: BorderSide(
                          width: 0.5, color: Colors.grey.withOpacity(0.3)))),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, bottom: 20, top: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: textItems.length,
                  itemBuilder: (BuildContext context, int index) {
                    IconData icon;
                    if (index == 0 && !audioEnabled) {
                      icon = bottomItemsSwitch[index];
                    } else if (index == 1 && !videoEnabled) {
                      icon = bottomItemsSwitch[index];
                    } else {
                      icon = bottomItems[index];
                    }
                    return InkWell(
                        onTap: () {
                          selectedTab(index);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 18.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(icon,
                                  size: sizedItems[index],
                                  color: colorItems[index]),
                              SizedBox(
                                height: 5,
                              ),
                              Text(
                                textItems[index],
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colorItems[index]),
                              )
                            ],
                          ),
                        ));
                  },

                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int? findStreamKeyByDisplayNameContains() {
    final entries = videoState.streamsToBeRendered.entries.toList();
    final index = entries.indexWhere((entry) {
      final value = entry.value;
      print("^^^^^^^^^^^^^${value.publisherName}");
      return value.publisherName!.toLowerCase()?.contains('screen') == true;
    });

    return index;
  }

  getScreenShareWidgt(size) {
    var idx = findStreamKeyByDisplayNameContains();
    print('###########${idx}');
    if (idx == -1) {
      return Center();
    }
    return Center(
      child: Container(
        width: size.width,
        height: size.height,
        child: Visibility(
          visible: videoState.streamsToBeRendered.entries
                  .map((e) => e.value)
                  .toList()[idx!.toInt()]
                  .isVideoMuted ==
              false,
          replacement: Container(
            child: Center(
              child: Text(
                  "Video Paused By " +
                      videoState.streamsToBeRendered.entries
                          .map((e) => e.value)
                          .toList()[idx!.toInt()]
                          .publisherName!,
                  style: TextStyle(color: Colors.black)),
            ),
          ),
          child: RTCVideoView(
            videoState.streamsToBeRendered.entries
                .map((e) => e.value)
                .toList()[idx!.toInt()]
                .videoRenderer,
            filterQuality: FilterQuality.none,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          ),
        ),
        // decoration: BoxDecoration(
        //     image: DecorationImage(
        //         image: AssetImage(
        //           "assets/images/person2.jpg",),
        //         fit: BoxFit.cover)),
      ),
    );
  }

  setIsWhiteboardDrawByHuman(val) {
    setState(() {
      isWhiteboardDrawByHuman = val;
    });
  }

  getWhiteboardWidgt(size) {
// var idx =  findStreamKeyByDisplayNameContains();
// print('###########${idx}');
// if(idx == -1)
//   {
//     return  Center();
//   }
    print("Check1");
    return Center(
      child: Container(
        width: size.width,
        height: size.height,
        child: Container(
          child: GestureDetector(
            onLongPress: () {
              // print("check2");
            },
            onHorizontalDragUpdate: (val) {
              print("check2");
              setIsWhiteboardDrawByHuman(true);
            },
            onVerticalDragUpdate: (val) {
              print("check2");
              setIsWhiteboardDrawByHuman(true);
            },
            child: DrawingBoard(
              controller: _drawingController,
              background: Image(
                  image: NetworkImage(whiteBoardImageUrl),
                  width: 400,
                  height:
                      600), //Container(width: 400, height: 400, color: Colors.white),
              showDefaultActions: true,
              showDefaultTools: true,
              onInteractionStart: (det) {
                print(
                    'detttttttttttt${_drawingController.painterKey.currentState}');
              },
              onInteractionEnd: (det) {
                print('detttttttttttt${det}');
              },
              onInteractionUpdate: (val) {
                print('detttttttttttt${val}');
              },
            ),
          ),
        ),
        // decoration: BoxDecoration(
        //     image: DecorationImage(
        //         image: AssetImage(
        //           "assets/images/person2.jpg",),
        //         fit: BoxFit.cover)),
      ),
    );
  }

  initVideoMute() async {
    if (widget.isAudio && videoEnabled == true) {
      setState(() {
        speakerOn = !speakerOn!;
      });
      await Helper.setSpeakerphoneOn(speakerOn);
      setState(() {
        videoEnabled = !videoEnabled;
      });
      await mute(
          videoPlugin?.webRTCHandle?.peerConnection, 'video', videoEnabled);
    }
  }


List<String> partiList = [];
  getParticipantList() async
  {
    var d = await videoPlugin?.getRoomParticipants(widget.room);
    d!.participants?.forEach((element) async {
      if(partiList.contains(element.id.toString()))
      {

      }
      else{
        partiList.add(element.id.toString());
        print(
            "3333333333${element.id}");
       // var userDetails = await getUserDetailsByIntId(element.id!.toInt()))!;
        var newUser = MeetingUserList(
            id: element.id,
            display: element.display,
            ispublisher: element.publisher,
            isTalking: element.talking,
            isHost: true,
            isJoined: true,
            isVideoOn: videoState
                .streamsToBeRendered[element.id.toString()]?.isVideoMuted,
            isAudioOn: videoState
                .streamsToBeRendered[element.id.toString()]?.isAudioMuted,
            isModerator: true,
            profile: 'https://cdn-icons-png.flaticon.com/512/149/149071.png'
        );
      //  ref.read(participantsListProvider.notifier).add(newUser);
      }

    });
  }
  selectedTab(index) async {
    setState(() {
      pageIndex = index;
    });
    if (index == 0) {
      setState(() {
        audioEnabled = !audioEnabled;
      });
      await mute(
          videoPlugin?.webRTCHandle?.peerConnection, 'audio', audioEnabled);
      setState(() {
        localVideoRenderer.isAudioMuted = !audioEnabled;
      });
    }
    if (index == 1) {
      setState(() {
        videoEnabled = !videoEnabled;
      });
      await mute(
          videoPlugin?.webRTCHandle?.peerConnection, 'video', videoEnabled);
    }
    if (index == 2) {
      shareBottom(context);
    }
    if (index == 3) {




     getParticipantList();

      Navigator.push(
          context,
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => ParticipantsPage()));
    }
    if (index == 4) {
      getOtherUserList();
    }
    if (index == 5) {
      //  bottomSheet();

      var msg = {
        "type": "raiseHandEvent",
        "data": {
          "type": !isMeRaisedHand ? "start" : "end",
          "feedId": myId.toString()
        }
      };
      setState(() {
        isMeRaisedHand = !isMeRaisedHand;
      });
      await textRoom.sendMessage(myRoom, json.encode(msg));
    }
  }

  bottomSheet() {
    showAdaptiveActionSheet(
      context: context,

      bottomSheetColor: Colors.grey[100],
      actions: <BottomSheetAction>[
        BottomSheetAction(
            leading: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Security'),
            ),
            trailing: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(Icons.security),
            ),
            title: Text(""),
            onPressed: (context) {
              print('1');
            }),
        BottomSheetAction(
            leading: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Chat'),
            ),
            trailing: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(Icons.chat),
            ),
            title: Text(""),
            onPressed: (context) {}),
        BottomSheetAction(
            leading: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Meeting Settings'),
            ),
            trailing: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(Icons.settings_outlined),
            ),
            title: Text(""),
            onPressed: (context) {}),
        BottomSheetAction(
            leading: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Youtube'),
            ),
            trailing: Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(Icons.youtube_searched_for),
            ),
            title: Text(""),
            onPressed: (context) {}),
        BottomSheetAction(
            leading: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Disconnect Audio',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            ),
            title: Text(""),
            onPressed: (context) {}),
        BottomSheetAction(
            title: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '✋ Raise Hand ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
            ),
            onPressed: (context) {}),
        BottomSheetAction(
            title: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                ' 👏   👍   💔   🤣   😮   🎉 ',
              ),
            ),
            onPressed: (context) {}),
      ],
      cancelAction: CancelAction(
          title: const Text(
        'Cancel',
        style: TextStyle(color: Colors.black),
      )), // onPressed parameter is optional by default will dismiss the ActionSheet
    );
  }

  bottomSheet23() {
    showAdaptiveActionSheet(
      context: context,

      bottomSheetColor: Colors.grey[100],
      actions: <BottomSheetAction>[
        BottomSheetAction(
            leading: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Bandwith Consumption',
                style: TextStyle(color: Colors.red, fontSize: 15),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // StreamBuilder<BandwidthData>(
                //   stream: bandwidthStream,
                //   builder: (context, snapshot) {
                //     if (snapshot.hasData) {
                //       BandwidthData bandwidthData = snapshot.data!;
                //       String outgoingBandwidth =
                //           bandwidthData.outgoingBandwidth;
                //       String incomingBandwidth =
                //           bandwidthData.incomingBandwidth;
                //       return Row(
                //         children: [
                //           Icon(Icons.arrow_downward),
                //           Text(
                //             incomingBandwidth,
                //             style: TextStyle(fontSize: 13),
                //           ),
                //           Icon(Icons.arrow_upward),
                //           Text(
                //             outgoingBandwidth,
                //             style: TextStyle(fontSize: 13),
                //           ),
                //         ],
                //       );
                //     } else if (snapshot.hasError) {
                //       return Text('Error: ${snapshot.error}');
                //     } else {
                //       return Row(
                //         children: [
                //           Icon(Icons.arrow_downward),
                //           Text('0 kb'),
                //           Icon(Icons.arrow_upward),
                //           Text('0 kb'),
                //         ],
                //       );
                //     }
                //   },
                // )
              ],
            ),
            onPressed: (context) {}),
        BottomSheetAction(
            leading: const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Choose Quality',
                style: TextStyle(color: Colors.red, fontSize: 15),
              ),
            ),
            title: DropdownButton<String>(
              value: currentVideoQuality,
              items:
                  <String>['Auto', 'High', 'Medium', 'Low'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  currentVideoQuality = val.toString();
                });
                print("selected value$currentVideoQuality");
              },
            ),
            onPressed: (context) {}),
        BottomSheetAction(
            title: const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '✋ Raise Hand ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
            ),
            onPressed: (context) {}),
        BottomSheetAction(
            title: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                ' 👏   👍   💔   🤣   😮   🎉 ',
              ),
            ),
            onPressed: (context) {}),
      ],
      cancelAction: CancelAction(
          title: const Text(
        'Cancel',
        style: TextStyle(color: Colors.black),
      )), // onPressed parameter is optional by default will dismiss the ActionSheet
    );
  }

  bottomSheet2() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context,
              StateSetter setState /*You can rename this!*/) {
            return Container(
                height: 250,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Bandwidth Consumption'),
                        // StreamBuilder<BandwidthData>(
                        //   stream: bandwidthStream,
                        //   builder: (context, snapshot) {
                        //     if (snapshot.hasData) {
                        //       BandwidthData bandwidthData = snapshot.data!;
                        //       String outgoingBandwidth =
                        //           bandwidthData.outgoingBandwidth;
                        //       String incomingBandwidth =
                        //           bandwidthData.incomingBandwidth;
                        //       return Row(
                        //         children: [
                        //           Icon(Icons.arrow_downward),
                        //           Text(
                        //             incomingBandwidth,
                        //             style: TextStyle(fontSize: 13),
                        //           ),
                        //           Icon(Icons.arrow_upward),
                        //           Text(
                        //             outgoingBandwidth,
                        //             style: TextStyle(fontSize: 13),
                        //           ),
                        //         ],
                        //       );
                        //     } else if (snapshot.hasError) {
                        //       return Text('Error: ${snapshot.error}');
                        //     } else {
                        //       return Row(
                        //         children: [
                        //           Icon(Icons.arrow_downward),
                        //           Text('0 kb'),
                        //           Icon(Icons.arrow_upward),
                        //           Text('0 kb'),
                        //         ],
                        //       );
                        //     }
                        //   },
                        // )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Choose Quality'),
                        DropdownButton<String>(
                          value: currentVideoQuality,
                          items: <String>['Auto', 'High', 'Medium', 'Low']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) async {
                            if (val == 'Auto') {
                              await videoPlugin?.configure(bitrate: 128000);
                            } else if (val == 'High') {
                              await videoPlugin?.configure(bitrate: 3000000);
                            } else if (val == 'Medium') {
                              await videoPlugin?.configure(bitrate: 50000);
                              videoPlugin?.webRTCHandle!.peerConnection!
                                  .getStats();
                            } else if (val == 'Low') {
                              await videoPlugin?.configure(bitrate: 700);
                            }

                            // val == 'Auto' ? val == 'High' :   await videoPlugin?.configure(bitrate: 300) : val == 'High' :   await videoPlugin?.configure(bitrate: 300)
                            setState(() {
                              currentVideoQuality = val.toString();
                            });
                            print("selected value$currentVideoQuality");
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Meeting Id'),
              Text(myRoom.toString()),
                      ],
                    )
                  ],
                ));
          });
        });
  }

  shareBottomold() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (BuildContext context,
              StateSetter setState /*You can rename this!*/) {
            return Container(
                height: 250,
                child: Column(
                  children: [
                    InkWell(
                      child: screenSharing
                          ? Text('Close Screen Share')
                          : Text('Screen Share'),
                      onTap: () async {
                        if (screenSharing) {
                          await disposeScreenSharing();
                          return;
                        }
                        await screenShare();
                      },
                    ),
                    InkWell(
                      child: Text('WhiteBoard'),
                      onTap: () async {
                        setState(() {
                          isWhiteboardDrawByMe = true;
                        });
                        if (isWhiteboardDrawByMe) {
                          setState(() {
                            isAnyOneShareWhiteboard = !isAnyOneShareWhiteboard;
                          });
                          var msg = {
                            "type": "whiteboardEvent",
                            "data": {
                              "type": isAnyOneShareWhiteboard ? "start" : "end",
                              "feedId": myId.toString()
                            }
                          };

                          await textRoom.sendMessage(myRoom, json.encode(msg));
                        }
                        Navigator.pop(context);
                      },
                    ),
                    Text('Picture'),
                    Text('Url'),
                  ],
                ));
          });
        });
  }

  void shareBottom(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: Colors.grey.shade300,
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        builder: (builder) {
          return SizedBox(
            height: 400.0,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    // padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8)),
                    child: ListView.separated(
                      itemCount: shareItemsText.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(height: 3),
                      itemBuilder: (BuildContext context, int index) {
                        IconData icon;
                        if (index == 0 && screenSharing) {
                          icon = shareItemsSwitch[index];
                        } else if (index == 1 && isWhiteboardDrawByMe) {
                          icon = shareItemsSwitch[index];
                        } else {
                          icon = shareItems[index];
                        }

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: () {
                              shareItemClicked(index);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(shareItemsText[index],
                                    style: TextStyle(fontSize: 18)),
                                Icon(
                                  icon,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      color: Colors.grey.shade300,
                      width: MediaQuery.of(context).size.width,
                      height: 60,
                      child: Center(
                          child: Text(
                        "Cancel",
                        style: TextStyle(fontSize: 20),
                      )),
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }

  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  Path drawHeart(Size sizeold) {
    Size size = Size(30, 30);
    final path = Path();
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;
    final radius = min(halfWidth, halfHeight);

    path.moveTo(halfWidth, halfHeight + radius / 2);
    path.cubicTo(
      halfWidth + radius / 2,
      halfHeight + radius / 2,
      halfWidth + radius / 2,
      halfHeight - radius / 3,
      halfWidth,
      halfHeight - radius / 1.5,
    );
    path.cubicTo(
      halfWidth - radius / 2,
      halfHeight - radius / 3,
      halfWidth - radius / 2,
      halfHeight + radius / 2,
      halfWidth,
      halfHeight + radius / 2,
    );

    return path;
  }

  Path drawBrokenHeart(Size sizew) {
    Size size = Size(30, 30);
    final path = Path();
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;
    final radius = min(halfWidth, halfHeight);

    path.moveTo(halfWidth - radius / 2, halfHeight + radius / 2);
    path.cubicTo(
      halfWidth - radius / 2,
      halfHeight + radius / 2,
      halfWidth - radius / 2,
      halfHeight - radius / 6,
      halfWidth,
      halfHeight - radius / 1.5,
    );
    path.cubicTo(
      halfWidth + radius / 2,
      halfHeight - radius / 6,
      halfWidth + radius / 2,
      halfHeight + radius / 2,
      halfWidth + radius / 2,
      halfHeight + radius / 2,
    );
    path.moveTo(halfWidth - radius / 2, halfHeight + radius / 2);
    path.cubicTo(
      halfWidth - radius / 2,
      halfHeight + radius / 2,
      halfWidth - radius / 2,
      halfHeight - radius / 6,
      halfWidth,
      halfHeight - radius / 1.5,
    );
    path.moveTo(halfWidth, halfHeight + radius / 2);
    path.cubicTo(
      halfWidth,
      halfHeight + radius / 2,
      halfWidth,
      halfHeight - radius / 6,
      halfWidth + radius / 2,
      halfHeight + radius / 2,
    );

    return path;
  }
getOtherUserList()
{
//   ref.watch(getAllUserProvider).when(data: (list) {
//     var contactList = [];
//     list.forEach((user) {
//       if (joinedUserList.contains(user.uid)) {
//       } else {
//         if (alreadyJoinUserList.contains(user.uid)) {
//         } else {
//           alreadyJoinUserList.add(user.uid);
//           UserModelCheck usr = UserModelCheck(
//               name: user.name,
//               uid: user.uid,
//               profilePic:  user.profilePic,
//               isOnline:  user.isOnline,
//               phoneNumber:  user.phoneNumber,
//               deviceToken:  user.deviceToken,
//               profileQuote:  user.profileQuote,
//               groupId:  user.groupId,
//               isChecked:  false,
//               isDialed: false,
//               dialedTime: DateTime.now(), callStatus: '', isOnlyAudioDialed: false
//           );
//           ref.read(userListProvider.notifier).add(usr);
//         }
//         // contactList.add(user);
//       }
//     });
//     showBottomDialog(context);
// }
//   , error: (Object error, StackTrace stackTrace) { print(error); }, loading: () {
//     print('loading');
// });
}
  void showBottomDialog(BuildContext context) {



    showGeneralDialog(
      barrierLabel: "showGeneralDialog",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      context: context,
      pageBuilder: (context, _, __) {

        return Consumer(
          builder: (BuildContext context, userListProvider, Widget? child) {
            final userList = [];
            // final userList = ref.watch(userListProvider);
            return Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.white,
                height: MediaQuery.of(context).size.height * 0.60,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 0.0, vertical: 10),
                        child: ListView.builder(
                            itemCount: userList.length,
                            itemBuilder: (context, index) {
                              final contact = userList[index];
                              // final contact =
                              return Column(
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                          color: contact.isChecked
                                              ? Colors.blue.shade100
                                              : Colors.grey.shade200,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(7))),
                                      height: 60,
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 10),
                                      child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [

                                        Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 12.0, left: 10),
                                              child: GestureDetector(
                                                onTap: () {
                                                  // ref
                                                  //     .read(userListProvider.notifier)
                                                  //     .update(contact,!contact.isChecked);


                                                },
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      contact.name.toUpperCase(),
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          color:
                                                          selectedIndex == index
                                                              ? Color(0xffDEB988)
                                                              : Colors.black,
                                                          fontWeight:
                                                          selectedIndex == index
                                                              ? FontWeight.bold
                                                              : FontWeight.normal,
                                                          fontFamily: "Poppins",
                                                          fontSize: 16,
                                                          decoration:
                                                          TextDecoration.none),
                                                    ),
                                                    const SizedBox(
                                                      height: 5,
                                                    ),
                                                    Text(
                                                      contact.phoneNumber
                                                          .toUpperCase(),
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                          color:
                                                          selectedIndex == index
                                                              ? Color(0xffDEB988)
                                                              : Colors.black,
                                                          fontWeight:
                                                          selectedIndex == index
                                                              ? FontWeight.bold
                                                              : FontWeight.normal,
                                                          fontFamily: "Poppins",
                                                          fontSize: 16,
                                                          decoration:
                                                          TextDecoration.none),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )),
                                        Expanded(
                                          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                            stream:  null,//ref.watch(callControllerProvider).callInPageStream(contact.uid),
                                            builder: (context, snapshot) {


                                              if (snapshot.hasError) {
                                                print(snapshot.error);
                                              }

                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return Container();
                                              }

                                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                                return Container();
                                              }
                                              List<DocumentSnapshot<Map<String, dynamic>>> documents = snapshot.data!.docs;
                                              return Container();
                                              // Call call = Call.fromMap(documents[0].data()!);
                                              // return Container(
                                              //   height: 100,
                                              //   child: Row(
                                              //     children: [
                                              //       Visibility(
                                              //           visible: snapshot.hasData || snapshot.data!.docs.isNotEmpty && (call.callStatus == 'active' ||
                                              //               call.callStatus == 'Calling' ||
                                              //               call.callStatus == 'Ringing' ||
                                              //               call.callStatus == 'Busy'),
                                              //           child: Icon(Icons.ring_volume,color: Colors.green,size: 27,)),
                                              //       Visibility(
                                              //           visible: snapshot.hasData || snapshot.data!.docs.isNotEmpty && (call.callStatus == 'active' ||
                                              //               call.callStatus == 'Calling' ||
                                              //               call.callStatus == 'Ringing' ||
                                              //               call.callStatus == 'Busy'),
                                              //           child: call.callStatus == 'active' ? Text('Calling',style:TextStyle(fontSize: 11) ,) : Text(call.callStatus)),
                                              //       Visibility(
                                              //           visible: snapshot.hasData || snapshot.data!.docs.isNotEmpty,
                                              //           child: GestureDetector(
                                              // onTap: () {
                                              // // ref.read(callControllerProvider).callEndFromVideoCallPage(
                                              // // call.callerId,
                                              // // call.receiverId,
                                              // // call, context);
                                              // },
                                              //               child: Icon(Icons.call_end,color: Colors.red,size: 27,))),
                                              //     ],
                                              //   ),
                                              // );
                                            }
                                          ),
                                        )
                                      ])),
                                ],
                              );
                            }),
                      ),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          print("EEEEEEEEEEEEEEEEEEEE");
                          // print(selectedUsers);

                          userList.forEach((user) {
                            if(user.isChecked)
                            {
                              // ref
                              //     .read(userListProvider.notifier)
                              //     .updateCallStatus(user,true,DateTime.now(),'ringing',false);
                              //
                              // // ... Do something here with items here
                              // ref.read(callControllerProvider).makeCallForExitingRoom(
                              //     context,
                              //     user.name,
                              //     user.uid,
                              //     user.profilePic,
                              //     false,
                              //     true,
                              //     user.isOnline,
                              //     user.deviceToken,
                              //     myRoom!);
                              // joinedUserList.add(user.uid);
                            }

                          });
                        },
                        child: const Text("Join"))
                  ],
                ),
              ),
            );
          },

        );
      },
      transitionBuilder: (_, animation1, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          ).animate(animation1),
          child: child,
        );
      },
    );
  }
shareItemClicked(int index) async {
    if (index == 0) {
      if (screenSharing) {
        await disposeScreenSharing();
        return;
      }

      await screenShare();
      Navigator.pop(context);
    } else if (index == 1) {
      setState(() {
        isWhiteboardDrawByMe = true;
      });
      if (isWhiteboardDrawByMe) {
        setState(() {
          isAnyOneShareWhiteboard = !isAnyOneShareWhiteboard;
        });
        var msg = {
          "type": "whiteboardEvent",
          "data": {
            "type": isAnyOneShareWhiteboard ? "start" : "end",
            "feedId": myId.toString()
          }
        };

        await textRoom.sendMessage(myRoom, json.encode(msg));
      }
      Navigator.pop(context);
    }
  }

  getMainLayOutOfVideo(size) {

    if(!isAnyOneShareWhiteboard)
      {
        if(!isAnyOneShareScreen)
        {
          if(videoState.streamsToBeRendered.entries.length == 2)
          {

            
            
            return Container(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                        width: size.width,
                        height: size.height,
                        child: Stack(
                          children: [
                            Visibility(
                              visible: videoState
                                  .streamsToBeRendered.entries
                                  .map((e) => e.value)
                                  .toList()[1]
                                  .isVideoMuted ==
                                  false,
                              child: RTCVideoView(
                                videoState
                                    .streamsToBeRendered.entries
                                    .map((e) => e.value)
                                    .toList()[1]
                                    .videoRenderer,
                                filterQuality: FilterQuality.none,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitContain,
                              ),
                            ),
                            Positioned(
                              left: 150,
                              bottom: 5,
                              child: Visibility(
                                  visible: true,
                                  child: Container(
                                      color: Colors.black,
                                      child: Text(
                                          videoState
                                              .streamsToBeRendered
                                              .entries
                                              .map((e) => e.value)
                                              .toList()[1]
                                              .publisherName
                                              .toString(),
                                          style: TextStyle(
                                              fontSize: 22,
                                              color: Colors
                                                  .white)))),
                            ),
                            Positioned(
                              left: 280,
                              bottom: 5,
                              child: Visibility(
                                visible:
                                true,
                                child: Container(
                                  color: Colors.black,
                                  child: Center(
                                    child: videoState
                                        .streamsToBeRendered
                                        .entries
                                        .map((e) => e.value)
                                        .toList()[1]
                                        .isAudioMuted! == true ? Text(
                                        "Audio Off",
                                        style: TextStyle(
                                            color: Colors.red)) : Text(
                                        "Audio On",
                                        style: TextStyle(
                                            color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 120,
                              bottom: 5,
                              child: Visibility(
                                  visible: raiseHandUserList
                                      .contains(videoState
                                      .streamsToBeRendered
                                      .entries
                                      .map((e) => e.value)
                                      .toList()[1]
                                      .id
                                      .toString()) ==
                                      true,
                                  child: Container(
                                      color: Colors.black,
                                      child: Text('👏',
                                          style: TextStyle(
                                              fontSize: 22)))),
                            ),
                            Positioned(

                              child: Visibility(
                                visible: videoState
                                    .streamsToBeRendered
                                    .entries
                                    .map((e) => e.value)
                                    .toList()[1]
                                    .isVideoMuted ==
                                    true,
                                child: Container(
                                  child: Center(
                                    child: videoState
        .streamsToBeRendered
        .entries
        .map((e) => e.value)
        .toList()[1]
        .profile != '' ? Image.network(videoState
                                        .streamsToBeRendered
                                        .entries
                                        .map((e) => e.value)
                                        .toList()[1]
                                        .profile.toString()) : Text('Video Paused'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                        width: 100,
                        height: 100,
                        child: Visibility(
                          visible: videoState
                              .streamsToBeRendered.entries
                              .map((e) => e.value)
                              .toList()[0]
                              .isVideoMuted ==
                              false,
                          replacement: Container(
                            child: Center(
                              child: Image.network(userInfo!.profilePhoto!),
                            ),
                          ),
                          child: RTCVideoView(
                            videoState.streamsToBeRendered.entries
                                .map((e) => e.value)
                                .toList()[0]
                                .videoRenderer,
                            filterQuality: FilterQuality.none,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitContain,
                          ),
                        )
                      // decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(12),
                      //     image: DecorationImage(
                      //         image: AssetImage(
                      //             "assets/images/person1.jpg"),
                      //         fit: BoxFit.cover)),
                    ),
                  ),
                ],
              ),
            );
          }
          else if(videoState.streamsToBeRendered.entries.length == 1)
            {
              return Center(
                child: Container(
                  width: size.width,
                  height: size.height,
                  child: Stack(
                    children: [
                      Visibility(
                        visible: videoState
                            .streamsToBeRendered.entries
                            .map((e) => e.value)
                            .toList()[0]
                            .isVideoMuted ==
                            false,
                        child: RTCVideoView(
                          videoState.streamsToBeRendered.entries
                              .map((e) => e.value)
                              .toList()[0]
                              .videoRenderer,
                          filterQuality: FilterQuality.none,
                          objectFit: RTCVideoViewObjectFit
                              .RTCVideoViewObjectFitContain,
                        ),
                      ),
                      Visibility(
                        visible: videoState
                            .streamsToBeRendered
                            .entries
                            .map((e) => e.value)
                            .toList()[0]
                            .isVideoMuted == true,
                        child: Container(
                          child: Center(child: Image.network(userInfo!.profilePhoto!)),
                          // child: getUserDetById(videoState.streamsToBeRendered.entries
                          //     .map((e) => e.value)
                          //     .toList()[0]
                          //         .id) == null ? Text("Audio Only") :Image.network(etUserDetById(videoState.streamsToBeRendered.entries
                          //     .map((e) => e.value)
                          //     .toList()[0]
                          //     .id),width: size.width, height: size.height,),

                        ),
                      ),
                      Positioned(
                        left: 150,
                        bottom: 5,
                        child: Visibility(
                            visible: true,
                            child: Container(
                                color: Colors.black,
                                child: Text(
                                    videoState
                                        .streamsToBeRendered
                                        .entries
                                        .map((e) => e.value)
                                        .toList()[0]
                                        .publisherName
                                        .toString(),
                                    style: TextStyle(
                                        color: Colors.white)))),
                      ),
                      Positioned(
                        left: 120,
                        bottom: 5,
                        child: Visibility(
                            visible: raiseHandUserList.contains(
                                videoState
                                    .streamsToBeRendered
                                    .entries
                                    .map((e) => e.value)
                                    .toList()[0]
                                    .id
                                    .toString()) ==
                                true,
                            child: Container(
                                color: Colors.black,
                                child: Text('👏',
                                    style: TextStyle(
                                        fontSize: 22)))),
                      ),
                      Positioned(
                        left: 280,
                        bottom: 5,
                        child: Visibility(
                          visible:
                              true,
                          child: Container(
                            color: Colors.black,
                            child: Center(
                              child: videoState
                                  .streamsToBeRendered
                                  .entries
                                  .map((e) => e.value)
                                  .toList()[0]
                                  .isAudioMuted! == true ? Text(
                                  "Audio Off",
                                  style: TextStyle(
                                      color: Colors.red)) : Text(
                                  "Audio On",
                                  style: TextStyle(
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ),


                    ],
                  ),
                  // decoration: BoxDecoration(
                  //     image: DecorationImage(
                  //         image: AssetImage(
                  //           "assets/images/person2.jpg",),
                  //         fit: BoxFit.cover)),
                ),
              );
            }
          else
            {
              return GridView.builder(
                  shrinkWrap: true,
                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2),
                  itemCount: videoState
                      .streamsToBeRendered.entries.length,
                  itemBuilder: (context, index) {
                    List<StreamRenderer> items = videoState
                        .streamsToBeRendered.entries
                        .map((e) => e.value)
                        .toList();
                    StreamRenderer remoteStream = items[index];
                    return Stack(
                      children: [
                        Visibility(
                          visible:
                          remoteStream.isVideoMuted == false,
                          replacement: Container(
                            child: Center(
                              child: Text(
                                  "Video Paused By " +
                                      remoteStream.publisherName!,
                                  style: TextStyle(
                                      color: Colors.black)),
                            ),
                          ),
                          child: RTCVideoView(
                            remoteStream.videoRenderer,
                            filterQuality: FilterQuality.none,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          ),
                        ),
                        Align(
                          alignment:
                          AlignmentDirectional.bottomStart,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment:
                            MainAxisAlignment.end,
                            children: [
                              Visibility(
                                  visible:
                                  raiseHandUserList.contains(
                                      remoteStream.id
                                          .toString()) ==
                                      true,
                                  child: Container(
                                      color: Colors.black,
                                      child: Text('👏',
                                          style: TextStyle(
                                              fontSize: 22)))),
                              Text(remoteStream.publisherName!),
                              Icon(remoteStream.isAudioMuted ==
                                  true
                                  ? Icons.mic_off
                                  : Icons.mic),
                              IconButton(
                                  onPressed: () async {
                                    fullScreenDialog =
                                    await showDialog(
                                        context: context,
                                        builder: ((context) {
                                          return AlertDialog(
                                            contentPadding:
                                            EdgeInsets
                                                .all(10),
                                            insetPadding:
                                            EdgeInsets
                                                .zero,
                                            content:
                                            Container(
                                              width: double
                                                  .maxFinite,
                                              padding:
                                              EdgeInsets
                                                  .zero,
                                              child: Stack(
                                                children: [
                                                  Positioned
                                                      .fill(
                                                      child:
                                                      Padding(
                                                        padding:
                                                        const EdgeInsets.all(
                                                            0),
                                                        child:
                                                        RTCVideoView(
                                                          remoteStream
                                                              .videoRenderer,
                                                        ),
                                                      )),
                                                  Align(
                                                    alignment:
                                                    Alignment
                                                        .topRight,
                                                    child: IconButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop(fullScreenDialog);
                                                        },
                                                        icon: Icon(
                                                          Icons.close,
                                                          color:
                                                          Colors.white,
                                                        )),
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        }));
                                  },
                                  icon: Icon(Icons.fullscreen)),
                            ],
                          ),
                        )
                      ],
                    );
                  });
            }
        }
        else
          {
            return getScreenShareWidgt(size);
          }
      }
    else
      {
        getWhiteboardWidgt(size);
      }





  }

}
