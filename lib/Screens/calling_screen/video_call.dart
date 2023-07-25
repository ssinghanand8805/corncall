//*************   © Copyrighted by Criterion Tech. *********************

import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:corncall/Configs/Dbkeys.dart';
import 'package:corncall/Configs/Dbpaths.dart';
import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Configs/optional_constants.dart';
import 'package:corncall/Screens/calling_screen/util.dart';
import 'package:corncall/Screens/homepage/homepage.dart';
import 'package:corncall/Services/Providers/Observer.dart';
import 'package:corncall/Services/Providers/call_history_provider.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Models/call.dart';
import 'package:corncall/Utils/call_utilities.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/setStatusBarColor.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:janus_client/janus_client.dart';
import 'package:pip_view/pip_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';

import '../../Models/DataModel.dart';
import 'package:logging/logging.dart';

import '../../Services/Providers/SmartContactProviderWithLocalStoreData.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../Services/Providers/user_provider.dart';
import '../../widgets/MyElevatedButton/MyElevatedButton.dart';

class VideoCall extends StatefulWidget {
  final String channelName;
  final String currentuseruid;
  final SharedPreferences prefs;
  final Call call;
  const VideoCall({
    Key? key,
    required this.call,
    required this.prefs,
    required this.currentuseruid,
    required this.channelName,
  }) : super(key: key);

  @override
  _VideoCallState createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  // late RtcEngine _engine;
  bool isspeaker = true;
  bool isalreadyendedcall = false;

  JanusClient? j;
  RestJanusTransport? rest;
  WebSocketJanusTransport? ws;
  JanusSession? session;
  JanusSession? session2;
  bool isVideoOffFirstTime = false;
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
  int? myId;
  int? myPvtId;
  List<String> raiseHandUserList = [];
  VideoRoomPluginStateManager videoState = VideoRoomPluginStateManager();
  get screenShareId => myId! + myId! + int.parse("1");
  int? myRoom = 1234;
  bool speakerOn = false;
  JanusVideoRoomPlugin? videoPlugin;
  JanusVideoRoomPlugin? screenPlugin;
  JanusVideoRoomPlugin? remotePlugin;
  // late JanusTextRoomPlugin textRoom;
  late StreamRenderer localScreenSharingRenderer;
  late StreamRenderer localVideoRenderer;
  int incomingBandwidth = 0;
  int outgoingBandwidth = 0;
  List<LocalUserData> _selectedList = [];
  List<String> inCallUserList = [];
  List<String> callUserList = [];
  DataModel? _cachedModel;
  late String myProfile;
  late String myUid;
  bool privousState = true;
  initialize() async {


    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {

      // var st = await InternetConnectionChecker().hasConnection;
      bool st = true;
      print("result${result}");
      if(result == ConnectivityResult.none)
      {
        print("RRRRRRRRRRRRRRRRRRRRRR${result}");
        st = false;
      }
      else
      {
        st = true;
      }
      if(privousState != st)
      {
        print(
            'ConnectionStatus Changed');
        if(st == false)
        {
          print(
              'Internet Gone');
          privousState = st;
        }
        else
        {
          //reconnection
          print(
              'Online Back');
          if(joined)
          {
            //  initialize()
            reConnectWs();
          }
          privousState = st;
        }
      }


    });



    _cachedModel ??= DataModel(widget.currentuseruid);
    ws = WebSocketJanusTransport(url: 'ws://aws.edumation.in:8188/janus');
    myRoom = int.parse(widget.channelName!);
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
    // textRoom = await session!.attach<JanusTextRoomPlugin>();
    initLocalMediaRenderer();
    autoJoinRoom();
  }
  callEnd() async {
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
  reConnectWs() async {
    await callEnd();
    joined = false;

    ws = WebSocketJanusTransport(url: 'ws://aws.edumation.in:8188/janus');
    j = JanusClient(transport: ws!, isUnifiedPlan: true, iceServers: [RTCIceServer(urls: "stun:stun1.l.google.com:19302", username: "", credential: "")], loggerLevel: Level.FINE);
    session = await j?.createSession();
    //
    await joinRoom();
    //  initLocalMediaRenderer();

  }

  initLocalMediaRenderer() {
    localScreenSharingRenderer = StreamRenderer('localScreenShare');
    localVideoRenderer = StreamRenderer('local');
  }

  autoJoinRoom() async {
    myId = await widget.prefs.getInt(Dbkeys.intUserId);
    myProfile = (await widget.prefs.getString(Dbkeys.photoUrl))!;
    myUid = (await widget.prefs.getString(Dbkeys.phone))!;

    myRoom = int.parse(widget.call.channelId.toString());
    // myPin = widget.pin.toString();
    // myUsername = userInfo!.name.toString();
    print("dddddddddddddddddddd${myRoom.toString()} and myid is ${myId}");
    setState(() {
      this.joined = true;
    });
    videoPlugin = await attachPlugin(pop: false);
    // await textRoomsetup(myId.toString());
    // videoPlugin!.createRoom(3238);
    eventMessagesHandler();
    videoPlugin!.createRoom(myRoom);
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
            audioRecv: false, videoRecv: false);
        // printLongString('RRRRRRRRR${ses.sdp}');
        // await videoPlugin.configure(bitrate: 3000000, sessionDescription: ses);

        await videoPlugin.publishMedia(bitrate: 3000000, offer: ses);
        //  videoPlugin!.publishMedia(offer: ses);
      }
      if (data is VideoRoomLeavingEvent) {
        unSubscribeTo(data.leaving!);
        if (videoState.streamsToBeRendered.entries.length == 1) {
          _stopCallingSound();

          setState(() {
            _infoStrings.add('onLeaveChannel');
            _users.clear();
          });
          if (isalreadyendedcall == false) {
            FirebaseFirestore.instance
                .collection(DbPaths.collectionusers)
                .doc(widget.call.callerId)
                .collection(DbPaths.collectioncallhistory)
                .doc(widget.call.timeepoch.toString())
                .set({
              'STATUS': 'ended',
              'ENDED': DateTime.now(),
            }, SetOptions(merge: true));
            FirebaseFirestore.instance
                .collection(DbPaths.collectionusers)
                .doc(widget.call.receiverId)
                .collection(DbPaths.collectioncallhistory)
                .doc(widget.call.timeepoch.toString())
                .set({
              'STATUS': 'ended',
              'ENDED': DateTime.now(),
            }, SetOptions(merge: true));
          }
          Wakelock.disable();
          //await callEnd();
        }
      }
      if (data is VideoRoomUnPublishedEvent) {
        unSubscribeTo(data.unpublished);
      }
      videoPlugin.handleRemoteJsep(event.jsep);
    });
    return videoPlugin;
  }

  joinRoom() async {
    initLocalMediaRenderer();
    if (widget.call.callerId == widget.currentuseruid) {
      setState(() {
        final info =
            'onJoinChannel: ${widget.channelName}, uid: ${widget.currentuseruid}';
        _infoStrings.add(info);
      });
      FirebaseFirestore.instance
          .collection(DbPaths.collectionusers)
          .doc(widget.call.callerId)
          .collection(DbPaths.collectioncallhistory)
          .doc(widget.call.timeepoch.toString())
          .set({
        'TYPE': 'OUTGOING',
        'ISVIDEOCALL': widget.call.isvideocall,
        'PEER': widget.call.receiverId,
        'TIME': widget.call.timeepoch,
        'DP': widget.call.receiverPic,
        'ISMUTED': false,
        'TARGET': widget.call.receiverId,
        'ISJOINEDEVER': false,
        'STATUS': 'calling',
        'STARTED': null,
        'ENDED': null,
        'CALLERNAME': widget.call.callerName,
        'CHANNEL': widget.channelName,
        'UID': widget.currentuseruid,
      }, SetOptions(merge: true));
      FirebaseFirestore.instance
          .collection(DbPaths.collectionusers)
          .doc(widget.call.receiverId)
          .collection(DbPaths.collectioncallhistory)
          .doc(widget.call.timeepoch.toString())
          .set({
        'TYPE': 'INCOMING',
        'ISVIDEOCALL': widget.call.isvideocall,
        'PEER': widget.call.callerId,
        'TIME': widget.call.timeepoch,
        'DP': widget.call.callerPic,
        'ISMUTED': false,
        'TARGET': widget.call.receiverId,
        'ISJOINEDEVER': true,
        'STATUS': 'missedcall',
        'STARTED': null,
        'ENDED': null,
        'CALLERNAME': widget.call.callerName,
        'CHANNEL': widget.channelName,
        'UID': widget.currentuseruid,
      }, SetOptions(merge: true));
      _playCallingTone();
    }
    Wakelock.enable();
    flutterLocalNotificationsPlugin.cancelAll();
    // videoPlugin = await attachPlugin(pop: false);

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
        displayName: widget.currentuseruid == widget.call.callerId
            ? widget.call.callerName
            : widget.call.receiverName,
        id: myId,
        pin: myPin);
    _onToggleSpeaker();
    print("***********************");
    // initVideoMute();
    // await videoPlugin?.configureOther( {
    //     'request': 'configure',
    //     'video': true,
    //     'simulcast': true,
    //   },
    // );
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
        startTimerNow();
        _stopCallingSound();
        setState(() {
          final info = 'userJoined: ${publisher['id']}';
          _infoStrings.add(info);
          // _users.add(publisher['id']);
          // callUserList.add(publisher['id']);
        });
        isPickedup = true;
        isOtherUserpicked = true;
        setState(() {});
        if (widget.currentuseruid == widget.call.callerId) {
          _stopCallingSound();
          FirebaseFirestore.instance
              .collection(DbPaths.collectionusers)
              .doc(widget.call.callerId)
              .collection(DbPaths.collectioncallhistory)
              .doc(widget.call.timeepoch.toString())
              .set({
            'STARTED': DateTime.now(),
            'STATUS': 'pickedup',
            'ISJOINEDEVER': true,
          }, SetOptions(merge: true));
          FirebaseFirestore.instance
              .collection(DbPaths.collectionusers)
              .doc(widget.call.receiverId)
              .collection(DbPaths.collectioncallhistory)
              .doc(widget.call.timeepoch.toString())
              .set({
            'STARTED': DateTime.now(),
            'STATUS': 'pickedup',
          }, SetOptions(merge: true));
          FirebaseFirestore.instance
              .collection(DbPaths.collectionusers)
              .doc(widget.call.callerId)
              .set({
            Dbkeys.videoCallMade: FieldValue.increment(1),
          }, SetOptions(merge: true));
          FirebaseFirestore.instance
              .collection(DbPaths.collectionusers)
              .doc(widget.call.receiverId)
              .set({
            Dbkeys.videoCallRecieved: FieldValue.increment(1),
          }, SetOptions(merge: true));
          FirebaseFirestore.instance
              .collection(DbPaths.collectiondashboard)
              .doc(DbPaths.docchatdata)
              .set({
            Dbkeys.videocallsmade: FieldValue.increment(1),
          }, SetOptions(merge: true));
        }
        Wakelock.enable();
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

      if (event.plugindata?.data['videoroom'] != null) {
        print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@${event}');
        if (event.plugindata?.data['error_code'] == 427) {
          print('room already exists..now join');
          await joinRoom();
        } else if (event.plugindata?.data['videoroom'] == 'created') {
          print('room created..now join');
          await joinRoom();
        }
// return;
      }
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
          audioRecv: false,  videoRecv: false);
      await videoPlugin?.configure(sessionDescription: offer);
    });
    screenPlugin?.renegotiationNeeded?.listen((event) async {
      if (screenPlugin?.webRTCHandle?.peerConnection?.signalingState !=
          RTCSignalingState.RTCSignalingStateStable) return;
      print('retrying to connect publisher');
      var offer = await screenPlugin?.createOffer(
          audioRecv: false, videoRecv: false);
      await screenPlugin?.configure(sessionDescription: offer);
    });
  }

  // textRoomsetup(uName) async {
  //   await textRoom.setup();
  //   textRoom.onData?.listen((event) async {
  //     if (RTCDataChannelState.RTCDataChannelOpen == event) {
  //       textRoom.joinRoom(myRoom!, uName, display: widget.currentuseruid == widget.call.callerId
  //           ? widget.call.callerName
  //           : widget.call.receiverName);
  //     }
  //   });
  //
  //   textRoom.data?.listen((event) {
  //     print('recieved message from data channel');
  //     dynamic data = parse(event.text);
  //     print(data);
  //     if (data != null) {
  //       if (data['textroom'] == 'message') {
  //         handleMessage(data);
  //         // setState(() {
  //         //   textMessages.add(data);
  //         // });
  //         // scrollToBottom();
  //       }
  //
  //       if (data['textroom'] == 'leave') {
  //         // setState(() {
  //         //   textMessages.add({'from': data['username'], 'text': 'Left The Chat!'});
  //         //   Future.delayed(Duration(seconds: 1)).then((value) {
  //         //     userNameDisplayMap.remove(data['username']);
  //         //   });
  //         // });
  //         // scrollToBottom();
  //       }
  //       if (data['textroom'] == 'join') {
  //         // setState(() {
  //         //   userNameDisplayMap.putIfAbsent(data['username'], () => data['display']);
  //         //   textMessages.add({'from': data['username'], 'text': 'Joined The Chat!'});
  //         // });
  //         // scrollToBottom();
  //       }
  //       if (data['participants'] != null) {
  //         // (data['participants'] as List<dynamic>).forEach((element) {
  //         //   setState(() {
  //         //     userNameDisplayMap.putIfAbsent(element['username'], () => element['display']);
  //         //   });
  //         // });
  //       }
  //     }
  //   });
  // }
  //
  handleMessage(msg) {
    var data = json.decode(msg['text']);
    print('22');
    if (data['type'] == 'event') {
      print('ddddddddddddd');
      var ev = data['data'];
      var forUser = msg['from'];
      print(videoState!.streamsToBeRendered);
      print(forUser);
      // manageMuteUIEvents(forUser, ev['for'], !ev['callBack']);
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

  Future<UserModel?> getUserDetailsByIntId(int id) async {
    UserModel? user;
    var userData = await FirebaseFirestore.instance
        .collection(DbPaths.collectionusers)
        .where(Dbkeys.intUserId, isEqualTo: id)
        .limit(1)
        .get();
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

            var userDetails = await getUserDetailsByIntId(feedId!.toInt());
            _users.add(feedId!.toInt());
            if (inCallUserList.contains(userDetails!.phone!)) {
              inCallUserList.add(userDetails!.phone!);
            }

            if (userDetails != null) {
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

  @override
  void dispose() {
    // clear users
    player.setReleaseMode(ReleaseMode.stop);
    player.stop();
    player.dispose();
    _users.clear();
    callUserList.clear();
    inCallUserList.clear();
    _users.clear();
    // destroy sdk
    // _engine.leaveChannel();
    // _engine.destroy();
    streamController!.done;
    streamController!.close();
    timerSubscription!.cancel();

    super.dispose();
  }

  bool isPickedup = false;
  double screenHeight = 0.0;
  double screenWidth = 0.0;
  Stream<DocumentSnapshot>? stream;
  @override
  void initState() {
    super.initState();
    // initialize agora sdk

    initialize();
    stream = FirebaseFirestore.instance
        .collection(DbPaths.collectionusers)
        .doc(widget.currentuseruid == widget.call.callerId
            ? widget.call.receiverId
            : widget.call.callerId)
        .collection(DbPaths.collectioncallhistory)
        .doc(widget.call.timeepoch.toString())
        .snapshots();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final observer = Provider.of<Observer>(this.context, listen: false);
      observer.setisOngoingCall(true);
    });
    startTimerNow();
  }

  String? mp3Uri;
  final player = AudioPlayer();
  AudioCache audioCache = AudioCache();
  Future<Null> _playCallingTone() async {
    await audioCache.loadAsFile('sounds/callingtone.mp3');
    player.play(AssetSource("sounds/callingtone.mp3"));
    // Lottie.asset("sounds/112098-call.json");
    print('AAAAAAAAAAAAAAAA${AssetSource("sounds/callingtone.mp3")}');
    player.setReleaseMode(ReleaseMode.loop);
    setState(() {});
  }

  void _stopCallingSound() async {
    try {
      player.setReleaseMode(ReleaseMode.stop);
      player.stop();
      player.dispose();
      await audioCache.clearAll();
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  bool selfVideoTap = false;

  getMainLayOutOfVideo(size) {
    if (videoState.streamsToBeRendered.entries.length == 2) {
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
                        visible: videoState.streamsToBeRendered.entries
                                .map((e) => e.value)
                                .toList()[1]
                                .isVideoMuted ==
                            false,
                        child: RTCVideoView(
                          mirror: true,
                          videoState.streamsToBeRendered.entries
                              .map((e) => e.value)
                              .toList()[selfVideoTap == true ? 0 : 1]
                              .videoRenderer,
                          filterQuality: FilterQuality.none,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                      Positioned(
                        left: 125,
                        top: 100,
                        child: Visibility(
                            visible: videoState.streamsToBeRendered.entries
                                    .map((e) => e.value)
                                    .toList()[1]
                                    .isVideoMuted ==
                                true,
                            child: Text(
                                videoState.streamsToBeRendered.entries
                                    .map((e) => e.value)
                                    .toList()[1]
                                    .publisherName
                                    .toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white))),
                      ),
                      Positioned(
                        left: 180,
                        bottom: 105,
                        child: Visibility(
                          visible: videoState.streamsToBeRendered.entries
                                  .map((e) => e.value)
                                  .toList()[1]
                                  .isVideoMuted ==
                              true,
                          child: Container(
                            color: Colors.black,
                            child: Center(
                              child: videoState.streamsToBeRendered.entries
                                          .map((e) => e.value)
                                          .toList()[1]
                                          .isAudioMuted! ==
                                      true
                                  ? const Text("Audio Off",
                                      style: TextStyle(color: Colors.red))
                                  : const Text("Audio On",
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 120,
                        bottom: 5,
                        child: Visibility(
                            visible: raiseHandUserList.contains(videoState
                                    .streamsToBeRendered.entries
                                    .map((e) => e.value)
                                    .toList()[1]
                                    .id
                                    .toString()) ==
                                true,
                            child: Container(
                                color: Colors.black,
                                child: const Text('👏',
                                    style: TextStyle(fontSize: 22)))),
                      ),
                      Positioned(
                        child: Visibility(
                          visible: videoState.streamsToBeRendered.entries
                                  .map((e) => e.value)
                                  .toList()[1]
                                  .isVideoMuted ==
                              true,
                          child: Container(
                            child: Center(
                              child: videoState.streamsToBeRendered.entries
                                          .map((e) => e.value)
                                          .toList()[1]
                                          .profile !=
                                      ''
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(videoState
                                          .streamsToBeRendered.entries
                                          .map((e) => e.value)
                                          .toList()[1]
                                          .profile
                                          .toString()),
                                      radius: 100,
                                    )
                                  : const Text('Video Paused'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
            ),
            Positioned(
              bottom: 80,
              right: 13,
              child: InkWell(
                onTap: () {
                  setState(() {
                    selfVideoTap = !selfVideoTap;
                  });
                },
                child: Container(
                    width: 120,
                    height: 140,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(12))
                    ),
                    child: Visibility(
                      visible: videoState.streamsToBeRendered.entries
                              .map((e) => e.value)
                              .toList()[0]
                              .isVideoMuted ==
                          false,
                      replacement: Container(
                        child: Center(
                          child: Image.network(myProfile),
                        ),
                      ),
                      child: RTCVideoView(
                        mirror: true,
                        videoState.streamsToBeRendered.entries
                            .map((e) => e.value)
                            .toList()[selfVideoTap == true ? 1 : 0]
                            .videoRenderer,
                        filterQuality: FilterQuality.none,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    )),
              ),
            ),
          ],
        ),
      );
    } else if (videoState.streamsToBeRendered.entries.length == 1) {
      return Center(
        child: Container(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              Visibility(
                visible: videoState.streamsToBeRendered.entries
                        .map((e) => e.value)
                        .toList()[0]
                        .isVideoMuted ==
                    false,
                child: RTCVideoView(
                  mirror: true,
                  videoState.streamsToBeRendered.entries
                      .map((e) => e.value)
                      .toList()[0]
                      .videoRenderer,
                  filterQuality: FilterQuality.none,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
              Visibility(
                visible: videoState.streamsToBeRendered.entries
                        .map((e) => e.value)
                        .toList()[0]
                        .isVideoMuted ==
                    true,
                child: Container(
                  child: Center(
                      child: CircleAvatar(
                          //  backgroundColor: Colors.black12,

                          radius: 100,
                          child: Image.network(myProfile))),
                ),
              ),
              Positioned(
                left: 180,
                top: 100,
                child: Visibility(
                    visible: videoState.streamsToBeRendered.entries
                            .map((e) => e.value)
                            .toList()[0]
                            .isVideoMuted ==
                        true,
                    child: Text(
                        videoState.streamsToBeRendered.entries
                            .map((e) => e.value)
                            .toList()[0]
                            .publisherName
                            .toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white))),
              ),
              Positioned(
                left: 180,
                bottom: 105,
                child: Visibility(
                  visible: videoState.streamsToBeRendered.entries
                          .map((e) => e.value)
                          .toList()[0]
                          .isVideoMuted ==
                      true,
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: videoState.streamsToBeRendered.entries
                                  .map((e) => e.value)
                                  .toList()[0]
                                  .isAudioMuted! ==
                              true
                          ? const Text("Audio Off",
                              style: TextStyle(color: Colors.red))
                          : const Text("Audio On",
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2),
          itemCount: videoState.streamsToBeRendered.entries.length,
          itemBuilder: (context, index) {
            List<StreamRenderer> items = videoState.streamsToBeRendered.entries
                .map((e) => e.value)
                .toList();
            StreamRenderer remoteStream = items[index];
            return Stack(
              children: [
                Visibility(
                  visible: remoteStream.isVideoMuted == false,
                  replacement: Container(
                    child: Center(
                      child: Text(
                          "Video Paused By " + remoteStream.publisherName!,
                          style: const TextStyle(color: Colors.black)),
                    ),
                  ),
                  child: RTCVideoView(
                    mirror: true,
                    remoteStream.videoRenderer,
                    filterQuality: FilterQuality.none,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Visibility(
                          visible: raiseHandUserList
                                  .contains(remoteStream.id.toString()) ==
                              true,
                          child: Container(
                              color: Colors.black,
                              child: const Text('👏',
                                  style: TextStyle(fontSize: 22)))),
                      Text(remoteStream.publisherName!),
                      Icon(remoteStream.isAudioMuted == true
                          ? Icons.mic_off
                          : Icons.mic),
                      IconButton(
                          onPressed: () async {
                            fullScreenDialog = await showDialog(
                                context: context,
                                builder: ((context) {
                                  return AlertDialog(
                                    contentPadding: const EdgeInsets.all(10),
                                    insetPadding: EdgeInsets.zero,
                                    content: Container(
                                      width: double.maxFinite,
                                      padding: EdgeInsets.zero,
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                              child: Padding(
                                            padding: const EdgeInsets.all(0),
                                            child: RTCVideoView(
                                              mirror: true,
                                              remoteStream.videoRenderer,
                                            ),
                                          )),
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: IconButton(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(fullScreenDialog);
                                                },
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                )),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }));
                          },
                          icon: const Icon(Icons.fullscreen)),
                    ],
                  ),
                )
              ],
            );
          });
    }
  }

  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  void _onToggleSpeaker() async {
    await Helper.setSpeakerphoneOn(isspeaker);
    setState(() {
      isspeaker = !isspeaker;
    });
  }

  Widget _toolbar(
    BuildContext context,
    bool isshowspeaker,
    String? status,
  ) {
    final observer = Provider.of<Observer>(this.context, listen: true);
    // if (widget.role == ClientRole.Audience) return Container();

    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          isshowspeaker == true
              ? SizedBox(
                  width: 65.67,
                  child: RawMaterialButton(
                    onPressed: _onToggleSpeaker,
                    child: Icon(
                      isspeaker
                          ? Icons.volume_mute_rounded
                          : Icons.volume_off_sharp,
                      color: isspeaker ? Colors.white : colorCallbuttons,
                      size: 22.0,
                    ),
                    shape: CircleBorder(),
                    elevation: 2.0,
                    fillColor: isspeaker ? colorCallbuttons : Colors.white,
                    padding: const EdgeInsets.all(12.0),
                  ))
              : SizedBox(height: 0, width: 65.67),
          status != 'ended' && status != 'rejected'
              ? SizedBox(
                  width: 65.67,
                  child: RawMaterialButton(
                    onPressed: _onToggleMute,
                    child: Icon(
                      muted ? Icons.mic_off : Icons.mic,
                      color: muted ? Colors.white : colorCallbuttons,
                      size: 22.0,
                    ),
                    shape: CircleBorder(),
                    elevation: 2.0,
                    fillColor: muted ? colorCallbuttons : Colors.white,
                    padding: const EdgeInsets.all(12.0),
                  ))
              : SizedBox(height: 42, width: 65.67),
          SizedBox(
            width: 65.67,
            child: RawMaterialButton(
              onPressed: () async {
                setState(() {
                  isalreadyendedcall =
                      status == 'ended' || status == 'rejected' ? true : false;
                });

                _onCallEnd(context);
              },
              child: Icon(
                status == 'ended' || status == 'rejected'
                    ? Icons.close
                    : Icons.call,
                color: Colors.white,
                size: 35.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: status == 'ended' || status == 'rejected'
                  ? Colors.black
                  : Colors.redAccent,
              padding: const EdgeInsets.all(15.0),
            ),
          ),
          status == 'ended' || status == 'rejected'
              ? SizedBox(
                  width: 65.67,
                )
              : SizedBox(
                  width: 65.67,
                  child: RawMaterialButton(
                    onPressed: _onSwitchCamera,
                    child: Icon(
                      Icons.switch_camera,
                      color: colorCallbuttons,
                      size: 20.0,
                    ),
                    shape: CircleBorder(),
                    elevation: 2.0,
                    fillColor: Colors.white,
                    padding: const EdgeInsets.all(12.0),
                  ),
                ),
          status == 'pickedup'
              ? SizedBox(
                  width: 65.67,
                  child: RawMaterialButton(
                    onPressed: () {
                      PIPView.of(context)!.presentBelow(Homepage(
                          doc: observer.userAppSettingsDoc!,
                          isShowOnlyCircularSpin: true,
                          currentUserNo: widget.currentuseruid,
                          prefs: widget.prefs));
                    },
                    child: Icon(
                      Icons.open_in_full_outlined,
                      color: Colors.black87,
                      size: 15.0,
                    ),
                    shape: CircleBorder(),
                    elevation: 2.0,
                    fillColor: Colors.white,
                    padding: const EdgeInsets.all(12.0),
                  ),
                )
              : SizedBox(
                  width: 65.67,
                )
        ],
      ),
    );
  }

  bool isuserenlarged = false;
  onetooneview(double h, double w, bool iscallended, bool userenlarged) {
    var size = MediaQuery.of(context).size;
    final views = getMainLayOutOfVideo(size);
    if (iscallended == true) {
      return Container(
        color: corncallPRIMARYcolor,
        height: h,
        width: w,
        child: Center(
            child: Icon(
          Icons.videocam_off,
          size: 120,
          color: pickTextColorBasedOnBgColorAdvanced(
                  Thm.isDarktheme(widget.prefs)
                      ? corncallAPPBARcolorDarkMode
                      : corncallAPPBARcolorLightMode)
              .withOpacity(0.38),
        )),
      );
    }
    return views;
  }

  Widget _panel(
      {required BuildContext context, bool? ispeermuted, String? status}) {
    if (status == 'rejected') {
      _stopCallingSound();
    }
    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 28),
      alignment: Alignment.bottomCenter,
      child: Container(
        // height: 73,
        margin: status == 'ended' ||
                status == 'calling' ||
                status == 'ringing' ||
                status == 'connecting' ||
                status == 'rejected' ||
                status == 'missedcall'
            ? EdgeInsets.symmetric(vertical: 100)
            : EdgeInsets.fromLTRB(0, 0, 70, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            status == 'pickedup' && ispeermuted == true
                ? Flexible(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getTranslated(context, 'muted'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87),
                        )),
                  )
                : SizedBox(
                    height: 0,
                    width: 0,
                  ),
            status == 'calling' || status == 'ringing' || status == 'missedcall'
                ? Flexible(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getTranslated(
                              context,
                              widget.call.receiverId == widget.currentuseruid
                                  ? 'connecting'
                                  : 'calling'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87),
                        )),
                  )
                : SizedBox(
                    height: 0,
                    width: 0,
                  ),
            status == 'nonetwork'
                ? Flexible(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getTranslated(context, 'connecting'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87),
                        )),
                  )
                : SizedBox(
                    height: 0,
                    width: 0,
                  ),
            status == 'ended'
                ? Flexible(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(getTranslated(context, 'callended'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: corncallREDbuttonColor,
                            ))),
                  )
                : SizedBox(
                    height: 0,
                    width: 0,
                  ),
            status == 'rejected'
                ? Flexible(
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal: 15,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getTranslated(context, 'callrejected'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: corncallREDbuttonColor),
                        )),
                  )
                : SizedBox(
                    height: 0,
                    width: 0,
                  ),
          ],
        ),
      ),
    );
  }
  TextEditingController controller = TextEditingController();
  var ratingValue = 0.0;
  bool isOtherUserpicked = false;
  Future<void> logOutDialog(context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          title: Text(
           getTranslated(context, "CallFeedback"),
          ),
          content: SizedBox(
            height: 200,
            child: Column(
              children: [
                RatingBar.builder(
                  updateOnDrag: true,
                  initialRating: 0,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 28,
                  itemPadding: const EdgeInsets.symmetric(
                      horizontal: 4.0),
                  itemBuilder: (context, _) =>
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    ratingValue = rating;
                  },
                ),
                SizedBox(height: 20,) ,
                TextFormField(
                  maxLines: 3,
                  controller: controller,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0,horizontal: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey)
                    ),
                    errorBorder:  OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey)
                    ),
                    focusedBorder:  OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey)
                    ),
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  corncallPRIMARYcolor,
                ),
              ),
              child: Text(
                  getTranslated(context, "cancel")
              ),
              onPressed: ()  {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  corncallPRIMARYcolor,
                ),
              ),
              child: Text(
                getTranslated(context, "submit")
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection(DbPaths.collectionusers)
                    .doc(widget.call.callerId)
                    .collection(DbPaths.collectioncallhistory)
                    .doc(widget.call.timeepoch.toString())
                    .set({'feedbackRating': ratingValue.toString(), 'feedbackText': controller.text.toString()}, SetOptions(merge: true));
                // widget.onTapLogout();
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
  void _onCallEnd(BuildContext context) async {
    final FirestoreDataProviderCALLHISTORY firestoreDataProviderCALLHISTORY =
        Provider.of<FirestoreDataProviderCALLHISTORY>(context, listen: false);
    final observer = Provider.of<Observer>(context, listen: false);

    _stopCallingSound();
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
    // await textRoom.leaveRoom(int.parse(widget.channelName!));
    await screenPlugin?.dispose();
    await remotePlugin?.dispose();
    // textRoom.dispose();
    remotePlugin = null;
    await CallUtils.callMethods.endCall(call: widget.call);
    DateTime now = DateTime.now();
    observer.setisOngoingCall(false);
    if (isalreadyendedcall == false) {
      await FirebaseFirestore.instance
          .collection(DbPaths.collectionusers)
          .doc(widget.call.callerId)
          .collection(DbPaths.collectioncallhistory)
          .doc(widget.call.timeepoch.toString())
          .set({'STATUS': 'ended', 'ENDED': now}, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection(DbPaths.collectionusers)
          .doc(widget.call.receiverId)
          .collection(DbPaths.collectioncallhistory)
          .doc(widget.call.timeepoch.toString())
          .set({'STATUS': 'ended', 'ENDED': now}, SetOptions(merge: true));
      //----------
      //----------
      //----------

      if (widget.currentuseruid == widget.call.callerId) {
        try {
          await FirebaseFirestore.instance
              .collection(DbPaths.collectionusers)
              .doc(widget.call.callerId)
              .collection('recent')
              .doc('callended')
              .delete();
          if (isPickedup == false) {
            await FirebaseFirestore.instance
                .collection(DbPaths.collectionusers)
                .doc(widget.call.receiverId)
                .collection('recent')
                .doc('callended')
                .set({
              'id': widget.call.receiverId,
              'ENDED': DateTime.now().millisecondsSinceEpoch,
              'CALLERNAME': widget.call.callerName,
            }, SetOptions(merge: true));
          }
        } catch (e) {}
      } else {
        try {
          await FirebaseFirestore.instance
              .collection(DbPaths.collectionusers)
              .doc(widget.call.receiverId)
              .collection('recent')
              .doc('callended')
              .delete();
          if (isPickedup == false) {
            await FirebaseFirestore.instance
                .collection(DbPaths.collectionusers)
                .doc(widget.call.callerId)
                .collection('recent')
                .doc('callended')
                .delete();
            Future.delayed(const Duration(milliseconds: 300), () async {
              await FirebaseFirestore.instance
                  .collection(DbPaths.collectionusers)
                  .doc(widget.call.callerId)
                  .collection('recent')
                  .doc('callended')
                  .set({
                'id': widget.call.callerId,
                'ENDED': DateTime.now().millisecondsSinceEpoch,
                'CALLERNAME': widget.call.callerName,
              });
            });
          }
        } catch (e) {}
      }
    }
    Wakelock.disable();

    firestoreDataProviderCALLHISTORY.fetchNextData(
        'CALLHISTORY',
        FirebaseFirestore.instance
            .collection(DbPaths.collectionusers)
            .doc(widget.currentuseruid)
            .collection(DbPaths.collectioncallhistory)
            .orderBy('TIME', descending: true)
            .limit(14),
        true);
    Navigator.pop(context);
    setStatusBarColor(widget.prefs);
    if(isOtherUserpicked)
      {
        logOutDialog(context);
      }

  }

  void _onToggleMute() {
    var rm = localVideoRenderer;
    if (rm!.mediaStream?.getAudioTracks()!.isNotEmpty == true) {
      rm.mediaStream?.getAudioTracks()[0].enabled = muted;
    }
    setState(() {
      muted = !muted;
    });
    _stopCallingSound();
    FirebaseFirestore.instance
        .collection(DbPaths.collectionusers)
        .doc(widget.currentuseruid)
        .collection(DbPaths.collectioncallhistory)
        .doc(widget.call.timeepoch.toString())
        .set({'ISMUTED': muted}, SetOptions(merge: true));
  }

  void _onSwitchCamera() async {
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
    localVideoRenderer.uid = widget.currentuseruid;
    // localVideoRenderer.profile = userInfo!.profilePic;

    setState(() {
      videoState.streamsToBeRendered[myId.toString()] = localVideoRenderer;
    });
  }

  Future<bool> onWillPopNEw() {
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    var size = MediaQuery.of(context).size;
    setStatusBarColor(widget.prefs);
    return WillPopScope(
        onWillPop: onWillPopNEw,
        child: PIPView(builder: (context, isFloating) {
          return Scaffold(
              // backgroundColor: Colors.black,
              body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>?>?>(
            stream: stream as Stream<DocumentSnapshot<Map<String, dynamic>?>?>?,
            builder: (BuildContext context, snapshot) {
              if (snapshot.hasData) {
                if (snapshot.data == null) {
                  return Center(
                    child: Stack(
                      children: <Widget>[
                        onetooneview(
                            screenHeight, screenWidth, false, isuserenlarged),
                        _toolbar(context, false, 'calling'),
                        _panel(
                            status: 'calling',
                            ispeermuted: false,
                            context: context),
                      ],
                    ),
                  );
                } else if (snapshot.data != null) {
                  if (snapshot.data!.data() == null) {
                    return Center(
                      child: Stack(
                        children: <Widget>[
                          onetooneview(
                              screenHeight, screenWidth, false, isuserenlarged),
                          _toolbar(context, false, 'calling'),
                          _panel(
                              status: 'calling',
                              ispeermuted: false,
                              context: context),
                        ],
                      ),
                    );
                  } else {
                    return Center(
                      child: Stack(
                        children: <Widget>[
                          onetooneview(
                              screenHeight,
                              screenWidth,
                              snapshot.data!.data()!["STATUS"] == 'ended'
                                  ? true
                                  : false,
                              isuserenlarged),
                          snapshot.data!.data()!["STATUS"] == 'pickedup'
                              ?
                              // &&
                              //     _getRenderViews().length > 1
                              // ?
                              // Positioned(
                              //         bottom:
                              //             screenWidth > screenHeight ? 40 : 120,
                              //         right:
                              //             screenWidth > screenHeight ? 20 : 10,
                              //         child: InkWell(
                              //           onTap: () {
                              //             isuserenlarged = !isuserenlarged;
                              //             setState(() {});
                              //           },
                              //           child: Container(
                              //             height: screenWidth > screenHeight
                              //                 ? screenWidth / 4.7
                              //                 : screenHeight / 4.7,
                              //             width: screenWidth > screenHeight
                              //                 ? (screenWidth / 4.7) / 1.7
                              //                 : (screenHeight / 4.7) / 1.7,
                              //             child: _getRenderViews()[
                              //                 isuserenlarged == true ? 1 : 0],
                              //           ),
                              //         ),
                              //       )
                              getMainLayOutOfVideo(size)
                              : SizedBox(),
                          _toolbar(
                              context,
                              snapshot.data!.data()!["STATUS"] == 'pickedup'
                                  ? true
                                  : false,
                              snapshot.data!.data()!["STATUS"]),
                          _panel(
                              context: context,
                              status: snapshot.data!.data()!["STATUS"],
                              ispeermuted: snapshot.data!.data()!["ISMUTED"]),
                        ],
                      ),
                    );
                  }
                }
              } else if (!snapshot.hasData) {
                return Center(
                  child: Stack(
                    children: <Widget>[
                      onetooneview(
                          screenHeight, screenWidth, false, isuserenlarged),
                      _toolbar(context, false, 'nonetwork'),
                      _panel(
                          context: context,
                          status: 'nonetwork',
                          ispeermuted: false),
                    ],
                  ),
                );
              }
              return Center(
                child: Stack(
                  children: <Widget>[
                    onetooneview(
                        screenHeight, screenWidth, false, isuserenlarged),
                    _toolbar(context, false, 'calling'),
                    _panel(
                        context: context,
                        status: 'calling',
                        ispeermuted: false),
                  ],
                ),
              );
            },
          ));
        }));
  }

  //------ Timer Widget Section Below:
  bool flag = true;
  Stream<int>? timerStream;
  // ignore: cancel_subscriptions
  StreamSubscription<int>? timerSubscription;
  // ignore: close_sinks
  StreamController<int>? streamController;
  String hoursStr = '00';
  String minutesStr = '00';
  String secondsStr = '00';

  Stream<int> stopWatchStream() {
    // ignore: close_sinks

    Timer? timer;
    Duration timerInterval = Duration(seconds: 1);
    int counter = 0;

    void stopTimer() {
      if (timer != null) {
        timer!.cancel();
        timer = null;
        counter = 0;
        streamController!.close();
      }
    }

    void tick(_) {
      counter++;
      streamController!.add(counter);
      if (!flag) {
        stopTimer();
      }
    }

    void startTimer() {
      timer = Timer.periodic(timerInterval, tick);
    }

    streamController = StreamController<int>(
      onListen: startTimer,
      onCancel: stopTimer,
      onResume: startTimer,
      onPause: stopTimer,
    );

    return streamController!.stream;
  }

  startTimerNow() {
    timerStream = stopWatchStream();
    timerSubscription = timerStream!.listen((int newTick) {
      setState(() {
        hoursStr =
            ((newTick / (60 * 60)) % 60).floor().toString().padLeft(2, '0');
        minutesStr = ((newTick / 60) % 60).floor().toString().padLeft(2, '0');
        secondsStr = (newTick % 60).floor().toString().padLeft(2, '0');
      });
      flutterLocalNotificationsPlugin.cancelAll();
    });
  }

//------
}

class Bcg extends StatefulWidget {
  const Bcg({Key? key}) : super(key: key);

  @override
  _BcgState createState() => _BcgState();
}

class _BcgState extends State<Bcg> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corncallREDbuttonColor,
      body: Center(
        child: Text(''),
      ),
    );
  }
}
