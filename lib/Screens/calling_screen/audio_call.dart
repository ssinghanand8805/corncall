//*************   © Copyrighted by Criterion Tech. *********************

import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/setStatusBarColor.dart';
import 'package:corncall/widgets/Common/cached_image.dart';
import 'package:corncall/Utils/call_utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:janus_client/janus_client.dart';
import 'package:lottie/lottie.dart';
import 'package:pip_view/pip_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../Models/DataModel.dart';
import '../../Services/Providers/SmartContactProviderWithLocalStoreData.dart';
import '../../Services/Providers/user_provider.dart';
import '../../Utils/theme_management.dart';
import 'package:logging/logging.dart';

import '../call_history/callhistory.dart';
class AudioCall extends StatefulWidget {
  final String? channelName;
  final Call call;
  final SharedPreferences prefs;
  final String? currentuseruid;
  const AudioCall(
      {Key? key,
        required this.call,
        required this.prefs,
        required this.currentuseruid,
        this.channelName,})
      : super(key: key);

  @override
  _AudioCallState createState() => _AudioCallState();
}

class _AudioCallState extends State<AudioCall> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  // late RtcEngine _engine;

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
  late JanusTextRoomPlugin textRoom;
  late StreamRenderer localScreenSharingRenderer;
  late StreamRenderer localVideoRenderer;
  int incomingBandwidth = 0;
  int outgoingBandwidth = 0;
  DataModel? _cachedModel;
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
    myRoom =  int.parse(widget.channelName!);
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
            audioRecv: false,  videoRecv: false);
        // printLongString('RRRRRRRRR${ses.sdp}');
        // await videoPlugin.configure(bitrate: 3000000, sessionDescription: ses);

        await videoPlugin.publishMedia(bitrate: 32000, offer: ses);
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
        final info = 'onJoinChannel: ${widget.channelName}, uid: ${widget.currentuseruid}';
        _infoStrings.add(info);
      });
      await FirebaseFirestore.instance
          .collection(DbPaths.collectionusers)
          .doc(widget.call.callerId)
          .collection(DbPaths.collectioncallhistory)
          .doc(widget.call.timeepoch.toString())
          .set({
        'TYPE': 'OUTGOING',
        'ISVIDEOCALL': widget.call.isvideocall,
        'PEER': widget.call.receiverId,
        'TARGET': widget.call.receiverId,
        'TIME': widget.call.timeepoch,
        'DP': widget.call.receiverPic,
        'ISMUTED': false,
        'ISJOINEDEVER': false,
        'STATUS': 'calling',
        'STARTED': null,
        'ENDED': null,
        'CALLERNAME': widget.call.callerName,
        'CHANNEL': widget.channelName,
        'UID': widget.currentuseruid,
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection(DbPaths.collectionusers)
          .doc(widget.call.receiverId)
          .collection(DbPaths.collectioncallhistory)
          .doc(widget.call.timeepoch.toString())
          .set({
        'TYPE': 'INCOMING',
        'ISVIDEOCALL': widget.call.isvideocall,
        'PEER': widget.call.callerId,
        'TARGET': widget.call.receiverId,
        'TIME': widget.call.timeepoch,
        'DP': widget.call.callerPic,
        'ISMUTED': false,
        'ISJOINEDEVER': true,
        'STATUS': 'missedcall',
        'STARTED': null,
        'ENDED': null,
        'CALLERNAME': widget.call.callerName,
        'CHANNEL': widget.channelName,
        'UID': widget.currentuseruid,
      }, SetOptions(merge: true));

      _playCallingTone();
      _users.add(myId!);
      print('^^^^^^^^^^^^^^^${widget.currentuseruid!}');
      inCallUserList.add(widget.currentuseruid!);
      callUserList.add(widget.call.receiverId!);
      setState(() {

      });
    }

    Wakelock.enable();
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
            : widget.call.receiverName, id: myId, pin: myPin);
    print("***********************");
    await Helper.setSpeakerphoneOn(isspeaker);
    setState(() {
      isspeaker = !isspeaker;
    });
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
            Dbkeys.audioCallMade: FieldValue.increment(1),
          }, SetOptions(merge: true));
          FirebaseFirestore.instance
              .collection(DbPaths.collectionusers)
              .doc(widget.call.receiverId)
              .set({
            Dbkeys.audioCallRecieved: FieldValue.increment(1),
          }, SetOptions(merge: true));
          FirebaseFirestore.instance
              .collection(DbPaths.collectiondashboard)
              .doc(DbPaths.docchatdata)
              .set({
            Dbkeys.audiocallsmade: FieldValue.increment(1),
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

      if(event.plugindata?.data['videoroom'] != null)
      {
        print('@@@@@@@@@@@@@@@@@@@@@@@@@@@@${event}');
        if(event.plugindata?.data['error_code'] == 427)
        {
          print('room already exists..now join');
          await joinRoom();
        }
        else if(event.plugindata?.data['videoroom'] == 'created')
        {
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
          audioRecv: false, videoRecv: false);
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

  textRoomsetup(uName) async {
    await textRoom.setup();
    textRoom.onData?.listen((event) async {
      if (RTCDataChannelState.RTCDataChannelOpen == event) {
        textRoom.joinRoom(myRoom!, uName, display: widget.currentuseruid == widget.call.callerId
            ? widget.call.callerName
            : widget.call.receiverName);
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
            if(inCallUserList.contains(userDetails!.phone!))
            {
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
    // destroy sdk
    // _engine.leaveChannel();
    // _engine.destroy();

    streamController!.done;
    streamController!.close();
    if(timerSubscription != null)
    {
      timerSubscription!.cancel();
    }


    super.dispose();
  }

  Stream<DocumentSnapshot>? stream;
  Stream<DocumentSnapshot>? stream2;
  @override
  void initState() {
    super.initState();
    initialize();
    stream = FirebaseFirestore.instance
        .collection(DbPaths.collectionusers)
        .doc(widget.currentuseruid == widget.call.callerId
        ? widget.call.receiverId
        : widget.call.callerId)
        .collection(DbPaths.collectioncallhistory)
        .doc(widget.call.timeepoch.toString())
        .snapshots();
    // stream?.listen((snapshot) {
    //   if (!snapshot.exists) {
    //     // Document has been deleted
    //    // print('Document deleted');
    //     final deleteListener = snapshot.reference.snapshots().listen((deletedSnapshot) {
    //       if (!deletedSnapshot.exists) {
    //         // Document has been deleted
    //         print('Document deleted');
    //         // Handle the deletion event here
    //
    //         // Cancel the second listener since we no longer need it
    //      //   deleteListener.cancel();
    //       }
    //     });
    //    // _onCallEnd(context);
    //     // Handle the deletion event here
    //   }
    //
    // });
    // stream2 = FirebaseFirestore.instance
    //     .collection(DbPaths.collectioncall)
    //     .doc(widget.currentuseruid)
    //     .snapshots();

    // stream2?.listen((event) {
    //
    //   var da = event.data();
    //   if(da != null)
    //     {
    //       Call call = Call.fromMap(da as Map<dynamic, dynamic>);
    //       if(call.agoraToken != null && call.agoraToken != '' && call.agoraToken!.isNotEmpty )
    //       {
    //         if(!isAlready)
    //           {
    //             print("1111111111111");
    //             print(event.data());
    //             // initialize agora sdk
    //             initialize2(call.agoraToken);
    //           }
    //
    //       }
    //     }
    //
    //
    // });
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final observer = Provider.of<Observer>(this.context, listen: false);
      observer.setisOngoingCall(true);
    });
  }

  String? mp3Uri;

  AudioCache audioCache = AudioCache();
  final player = AudioPlayer();
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
      setState(() {

      });
    } catch (e) {
      print(e);
    }
  }

  bool isspeaker = false;
  bool isAlready = false;
  // Future<void> initialize2(token) async {
  //   if (Agora_APP_IDD.isEmpty) {
  //     setState(() {
  //       _infoStrings.add(
  //         'Agora_APP_ID missing, please provide your Agora_APP_ID in app_constant.dart',
  //       );
  //       _infoStrings.add('Agora Engine is not starting');
  //     });
  //     return;
  //   }
  //
  //   await _initAgoraRtcEngine();
  //   _addAgoraEventHandlers();
  //
  //   await _engine.disableVideo();
  //   await _engine.joinChannel(token, widget.channelName!, null, 0);
  //   setState(() {
  //     isAlready = true;
  //   });
  // }

  // Future<void> _initAgoraRtcEngine() async {
  //   _engine = await RtcEngine.create(Agora_APP_IDD);
  //   await _engine.setEnableSpeakerphone(isspeaker);
  //   await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
  //   await _engine.setClientRole(widget.role!);
  // }

  bool isPickedup = false;
  bool isOtherUserpicked = false;
  bool isalreadyendedcall = false;
  // void _addAgoraEventHandlers() {
  //   _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
  //     setState(() {
  //       final info = 'onError: $code';
  //       _infoStrings.add(info);
  //     });
  //   },
  //       joinChannelSuccess: (channel, uid, elapsed) async {
  //     if (widget.call.callerId == widget.currentuseruid) {
  //       setState(() {
  //         final info = 'onJoinChannel: $channel, uid: $uid';
  //         _infoStrings.add(info);
  //       });
  //       await FirebaseFirestore.instance
  //           .collection(DbPaths.collectionusers)
  //           .doc(widget.call.callerId)
  //           .collection(DbPaths.collectioncallhistory)
  //           .doc(widget.call.timeepoch.toString())
  //           .set({
  //         'TYPE': 'OUTGOING',
  //         'ISVIDEOCALL': widget.call.isvideocall,
  //         'PEER': widget.call.receiverId,
  //         'TARGET': widget.call.receiverId,
  //         'TIME': widget.call.timeepoch,
  //         'DP': widget.call.receiverPic,
  //         'ISMUTED': false,
  //         'ISJOINEDEVER': false,
  //         'STATUS': 'calling',
  //         'STARTED': null,
  //         'ENDED': null,
  //         'CALLERNAME': widget.call.callerName,
  //         'CHANNEL': channel,
  //         'UID': uid,
  //       }, SetOptions(merge: true));
  //       await FirebaseFirestore.instance
  //           .collection(DbPaths.collectionusers)
  //           .doc(widget.call.receiverId)
  //           .collection(DbPaths.collectioncallhistory)
  //           .doc(widget.call.timeepoch.toString())
  //           .set({
  //         'TYPE': 'INCOMING',
  //         'ISVIDEOCALL': widget.call.isvideocall,
  //         'PEER': widget.call.callerId,
  //         'TARGET': widget.call.receiverId,
  //         'TIME': widget.call.timeepoch,
  //         'DP': widget.call.callerPic,
  //         'ISMUTED': false,
  //         'ISJOINEDEVER': true,
  //         'STATUS': 'missedcall',
  //         'STARTED': null,
  //         'ENDED': null,
  //         'CALLERNAME': widget.call.callerName,
  //         'CHANNEL': channel,
  //         'UID': uid,
  //       }, SetOptions(merge: true));
  //       _playCallingTone();
  //     }
  //
  //     Wakelock.enable();
  //   },
  //       leaveChannel: (stats) {
  //     _stopCallingSound();
  //
  //     setState(() {
  //       _infoStrings.add('onLeaveChannel');
  //       _users.clear();
  //     });
  //     if (isalreadyendedcall == false) {
  //       FirebaseFirestore.instance
  //           .collection(DbPaths.collectionusers)
  //           .doc(widget.call.callerId)
  //           .collection(DbPaths.collectioncallhistory)
  //           .doc(widget.call.timeepoch.toString())
  //           .set({
  //         'STATUS': 'ended',
  //         'ENDED': DateTime.now(),
  //       }, SetOptions(merge: true));
  //       FirebaseFirestore.instance
  //           .collection(DbPaths.collectionusers)
  //           .doc(widget.call.receiverId)
  //           .collection(DbPaths.collectioncallhistory)
  //           .doc(widget.call.timeepoch.toString())
  //           .set({
  //         'STATUS': 'ended',
  //         'ENDED': DateTime.now(),
  //       }, SetOptions(merge: true));
  //
  //     }
  //     Wakelock.disable();
  //   },
  //       userJoined: (uid, elapsed) {
  //     startTimerNow();
  //
  //     setState(() {
  //       final info = 'userJoined: $uid';
  //       _infoStrings.add(info);
  //       _users.add(uid);
  //     });
  //     isPickedup = true;
  //     setState(() {});
  //     if (widget.currentuseruid == widget.call.callerId) {
  //       _stopCallingSound();
  //
  //       FirebaseFirestore.instance
  //           .collection(DbPaths.collectionusers)
  //           .doc(widget.call.callerId)
  //           .collection(DbPaths.collectioncallhistory)
  //           .doc(widget.call.timeepoch.toString())
  //           .set({
  //         'STARTED': DateTime.now(),
  //         'STATUS': 'pickedup',
  //         'ISJOINEDEVER': true,
  //       }, SetOptions(merge: true));
  //       FirebaseFirestore.instance
  //           .collection(DbPaths.collectionusers)
  //           .doc(widget.call.receiverId)
  //           .collection(DbPaths.collectioncallhistory)
  //           .doc(widget.call.timeepoch.toString())
  //           .set({
  //         'STARTED': DateTime.now(),
  //         'STATUS': 'pickedup',
  //       }, SetOptions(merge: true));
  //       FirebaseFirestore.instance
  //           .collection(DbPaths.collectionusers)
  //           .doc(widget.call.callerId)
  //           .set({
  //         Dbkeys.audioCallMade: FieldValue.increment(1),
  //       }, SetOptions(merge: true));
  //       FirebaseFirestore.instance
  //           .collection(DbPaths.collectionusers)
  //           .doc(widget.call.receiverId)
  //           .set({
  //         Dbkeys.audioCallRecieved: FieldValue.increment(1),
  //       }, SetOptions(merge: true));
  //       FirebaseFirestore.instance
  //           .collection(DbPaths.collectiondashboard)
  //           .doc(DbPaths.docchatdata)
  //           .set({
  //         Dbkeys.audiocallsmade: FieldValue.increment(1),
  //       }, SetOptions(merge: true));
  //     }
  //     Wakelock.enable();
  //   },
  //       userOffline: (uid, elapsed) async {
  //     setState(() {
  //       final info = 'userOffline: $uid';
  //       _infoStrings.add(info);
  //       _users.remove(uid);
  //     });
  //     _stopCallingSound();
  //     if (isalreadyendedcall == false) {
  //       FirebaseFirestore.instance
  //           .collection(DbPaths.collectionusers)
  //           .doc(widget.call.callerId)
  //           .collection(DbPaths.collectioncallhistory)
  //           .doc(widget.call.timeepoch.toString())
  //           .set({
  //         'STATUS': 'ended',
  //         'ENDED': DateTime.now(),
  //       }, SetOptions(merge: true));
  //       FirebaseFirestore.instance
  //           .collection(DbPaths.collectionusers)
  //           .doc(widget.call.receiverId)
  //           .collection(DbPaths.collectioncallhistory)
  //           .doc(widget.call.timeepoch.toString())
  //           .set({
  //         'STATUS': 'ended',
  //         'ENDED': DateTime.now(),
  //       }, SetOptions(merge: true));
  //     }
  //   },
  //       firstRemoteVideoFrame: (uid, width, height, elapsed) {
  //     setState(() {
  //       final info = 'firstRemoteVideo: $uid ${width}x $height';
  //       _infoStrings.add(info);
  //     });
  //   })
  //   );
  // }

  Widget _toolbar(
      bool isshowspeaker,
      String? status,
      BuildContext context,
      ) {
    // if (widget.role == ClientRole.Audience) return Container();

    final observer = Provider.of<Observer>(this.context, listen: true);
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          status == 'ended' || status == 'rejected'
              ? SizedBox(height: 42, width: 42)
              : RawMaterialButton(
            onPressed: () async {
              setState(() {
                audioEnabled = !audioEnabled;
              });
              await _onToggleMute(videoPlugin?.webRTCHandle?.peerConnection, 'audio', audioEnabled);
              setState(() {
                localVideoRenderer.isAudioMuted = !audioEnabled;
              });
            },
            child: Icon(
              !audioEnabled ? Icons.mic_off : Icons.mic,
              color: !audioEnabled ? Colors.white : colorCallbuttons,
              size: 22.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: !audioEnabled ? colorCallbuttons : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
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
          isshowspeaker == true
              ? RawMaterialButton(
            onPressed: _onToggleSpeaker,
            child: Icon(
              !isspeaker
                  ? Icons.volume_up
                  : Icons.volume_mute_rounded,
              color: !isspeaker ? Colors.white : colorCallbuttons,
              size: 22.0,
            ),
            shape: CircleBorder(),
            elevation: 2.0,
            fillColor: !isspeaker ? colorCallbuttons : Colors.white,
            padding: const EdgeInsets.all(12.0),
          )
              : SizedBox(height: 42, width: 42),
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
            width: 0,
          ),
        ],
      ),
    );
  }

  audioscreenForPORTRAIT({
    required BuildContext context,
    String? status,
    bool? ispeermuted,
  }) {
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;
    if (status == 'rejected') {
      print('HHHHHHHHHHHHHHHHHHHHHHHH');
      _stopCallingSound();
    }
    return Container(
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            color: Thm.isDarktheme(widget.prefs)
                ? corncallAPPBARcolorDarkMode
                : corncallAPPBARcolorLightMode,
            height: h / 4,
            width: w,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 17,
                      color: Colors.white38,
                    ),
                    SizedBox(
                      width: 6,
                    ),
                    Text(
                      getTranslated(context, 'endtoendencryption'),
                      style: TextStyle(
                          color: Colors.white38, fontWeight: FontWeight.w400),
                    ),
                    isPickedup ? IconButton(
                      onPressed: () async {
                        showBottomDialog(context);
                      }, icon: Icon(Icons.person_add),
                    ) : Container()
                  ],
                ),
                // SizedBox(height: h / 35),
                SizedBox(
                  height: h / 9,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 7),
                      SizedBox(
                        width: w / 1.1,
                        child: Text(
                          widget.call.callerId == widget.currentuseruid
                              ? widget.call.receiverName!
                              : widget.call.callerName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: pickTextColorBasedOnBgColorAdvanced(
                                Thm.isDarktheme(widget.prefs)
                                    ? corncallAPPBARcolorDarkMode
                                    : corncallAPPBARcolorLightMode),
                            fontSize: 27,
                          ),
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        IsRemovePhoneNumberFromCallingPageWhenOnCall == true
                            ? ''
                            : widget.call.callerId == widget.currentuseruid
                            ? widget.call.receiverId!
                            : widget.call.callerId!,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: pickTextColorBasedOnBgColorAdvanced(
                              Thm.isDarktheme(widget.prefs)
                                  ? corncallAPPBARcolorDarkMode
                                  : corncallAPPBARcolorLightMode)
                              .withOpacity(0.34),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                // SizedBox(height: h / 25),
                status == 'pickedup'
                    ? Text(
                  "$hoursStr:$minutesStr:$secondsStr",
                  style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.green[300],
                      fontWeight: FontWeight.w600),
                )
                    : Text(
                  status == 'pickedup'
                      ? getTranslated(context, 'picked')
                      : status == 'nonetwork'
                      ? getTranslated(context, 'connecting')
                      : status == 'ringing' || status == 'missedcall'
                      ? getTranslated(context, 'calling')
                      : status == 'calling'
                      ? getTranslated(
                      context,
                      widget.call.receiverId ==
                          widget.currentuseruid
                          ? 'connecting'
                          : 'calling')
                      : status == 'pickedup'
                      ? getTranslated(context, 'oncall')
                      : status == 'ended'
                      ? getTranslated(
                      context, 'callended')
                      : status == 'rejected'
                      ? getTranslated(
                      context, 'callrejected')
                      : getTranslated(
                      context, 'plswait'),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: status == 'pickedup'
                        ? corncallPRIMARYcolor
                        : pickTextColorBasedOnBgColorAdvanced(
                        Thm.isDarktheme(widget.prefs)
                            ? corncallAPPBARcolorDarkMode
                            : corncallAPPBARcolorLightMode)
                        .withOpacity(0.6),
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          Stack(
            children: [
              widget.call.callerId == widget.currentuseruid
                  ? widget.call.receiverPic == null ||
                  widget.call.receiverPic == '' ||
                  status == 'ended' ||
                  status == 'rejected'
                  ? Container(
                height: w + (w / 11),
                width: w,
                color: Colors.white12,
                child: Icon(
                  status == 'ended'
                      ? Icons.person_off
                      : status == 'rejected'
                      ? Icons.call_end_rounded
                      : Icons.person,
                  size: 140,
                  color: Thm.isDarktheme(widget.prefs)
                      ? corncallAPPBARcolorDarkMode
                      : corncallAPPBARcolorLightMode,
                ),
              )
                  : Stack(
                children: [
                  Container(
                      height: w + (w / 11),
                      width: w,
                      color: Colors.white12,
                      child: CachedNetworkImage(
                        imageUrl: widget.call.callerId ==
                            widget.currentuseruid
                            ? widget.call.receiverPic!
                            : widget.call.callerPic!,
                        fit: BoxFit.cover,
                        height: w + (w / 11),
                        width: w,
                        placeholder: (context, url) => Center(
                            child: Container(
                              height: w + (w / 11),
                              width: w,
                              color: Colors.white12,
                              child: Icon(
                                status == 'ended'
                                    ? Icons.person_off
                                    : status == 'rejected'
                                    ? Icons.call_end_rounded
                                    : Icons.person,
                                size: 140,
                                color: Thm.isDarktheme(widget.prefs)
                                    ? corncallAPPBARcolorDarkMode
                                    : corncallAPPBARcolorLightMode,
                              ),
                            )),
                        errorWidget: (context, url, error) =>
                            Container(
                              height: w + (w / 11),
                              width: w,
                              color: Colors.white12,
                              child: Icon(
                                status == 'ended'
                                    ? Icons.person_off
                                    : status == 'rejected'
                                    ? Icons.call_end_rounded
                                    : Icons.person,
                                size: 140,
                                color: Thm.isDarktheme(widget.prefs)
                                    ? corncallAPPBARcolorDarkMode
                                    : corncallAPPBARcolorLightMode,
                              ),
                            ),
                      )),
                  Container(
                    height: w + (w / 11),
                    width: w,
                    color: Colors.black.withOpacity(0.18),
                  ),
                ],
              )
                  : widget.call.callerPic == null ||
                  widget.call.callerPic == '' ||
                  status == 'ended' ||
                  status == 'rejected'
                  ? Container(
                height: w + (w / 11),
                width: w,
                color: Colors.white12,
                child: Icon(
                  status == 'ended'
                      ? Icons.person_off
                      : status == 'rejected'
                      ? Icons.call_end_rounded
                      : Icons.person,
                  size: 140,
                  color: Thm.isDarktheme(widget.prefs)
                      ? corncallAPPBARcolorDarkMode
                      : corncallAPPBARcolorLightMode,
                ),
              )
                  : Stack(
                children: [
                  Container(
                      height: w + (w / 11),
                      width: w,
                      color: Thm.isDarktheme(widget.prefs)
                          ? corncallAPPBARcolorDarkMode
                          : corncallAPPBARcolorLightMode,
                      child: CachedNetworkImage(
                        imageUrl: widget.call.callerId ==
                            widget.currentuseruid
                            ? widget.call.receiverPic!
                            : widget.call.callerPic!,
                        fit: BoxFit.cover,
                        height: w + (w / 11),
                        width: w,
                        placeholder: (context, url) => Center(
                            child: Container(
                              height: w + (w / 11),
                              width: w,
                              color: Colors.white12,
                              child: Icon(
                                status == 'ended'
                                    ? Icons.person_off
                                    : status == 'rejected'
                                    ? Icons.call_end_rounded
                                    : Icons.person,
                                size: 140,
                                color: Thm.isDarktheme(widget.prefs)
                                    ? corncallAPPBARcolorDarkMode
                                    : corncallAPPBARcolorLightMode,
                              ),
                            )),
                        errorWidget: (context, url, error) =>
                            Container(
                              height: w + (w / 11),
                              width: w,
                              color: Colors.white12,
                              child: Icon(
                                status == 'ended'
                                    ? Icons.person_off
                                    : status == 'rejected'
                                    ? Icons.call_end_rounded
                                    : Icons.person,
                                size: 140,
                                color: Thm.isDarktheme(widget.prefs)
                                    ? corncallAPPBARcolorDarkMode
                                    : corncallAPPBARcolorLightMode,
                              ),
                            ),
                      )),
                  Container(
                    height: w + (w / 11),
                    width: w,
                    color: Colors.black.withOpacity(0.18),
                  ),
                ],
              ),
              // widget.call.callerId == widget.currentuseruid
              //     ? widget.call.receiverPic == null ||
              //             widget.call.receiverPic == '' ||
              //             status == 'ended' ||
              //             status == 'rejected'
              //         ? SizedBox()
              //         : Container(
              //             height: w + (w / 11),
              //             width: w,
              //             color: Colors.black.withOpacity(0.3),
              //           )
              //     : widget.call.callerPic == null ||
              //             widget.call.callerPic == '' ||
              //             status == 'ended' ||
              //             status == 'rejected'
              //         ? SizedBox()
              //         : Container(
              //             height: w + (w / 11),
              //             width: w,
              //             color: Colors.black.withOpacity(0.3),
              //           ),
              Positioned(
                  bottom: 20,
                  child: Container(
                    width: w,
                    height: 20,
                    child: Center(
                      child: status == 'pickedup'
                          ? ispeermuted == true
                          ? Text(
                        getTranslated(context, 'muted'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.yellow,
                          fontSize: 16,
                        ),
                      )
                          : SizedBox(
                        height: 0,
                      )
                          : SizedBox(
                        height: 0,
                      ),
                    ),
                  )),
            ],
          ),
          SizedBox(height: h / 7),
        ],
      ),
    );
  }

  audioscreenForLANDSCAPE({
    required BuildContext context,
    String? status,
    bool? ispeermuted,
  }) {
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;
    if (status == 'rejected') {
      print('HHHHHHHHHHHHHHHHHHHHHHHH');
      _stopCallingSound();
    }
    return Container(
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            status == 'nonetwork'
                ? getTranslated(context, 'connecting')
                : status == 'ringing' || status == 'missedcall'
                ? getTranslated(context, 'calling')
                : status == 'calling'
                ? getTranslated(context, 'calling')
                : status == 'pickedup'
                ? getTranslated(context, 'oncall')
                : status == 'ended'
                ? getTranslated(context, 'callended')
                : status == 'rejected'
                ? getTranslated(context, 'callrejected')
                : getTranslated(context, 'plswait'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: status == 'pickedup'
                  ? corncallPRIMARYcolor
                  : pickTextColorBasedOnBgColorAdvanced(
                  Thm.isDarktheme(widget.prefs)
                      ? corncallAPPBARcolorDarkMode
                      : corncallAPPBARcolorLightMode),
              fontSize: 25,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              status == 'pickedup'
                  ? getTranslated(context, 'picked')
                  : getTranslated(context, 'voice'),
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: status == 'pickedup'
                    ? corncallPRIMARYcolor
                    : corncallPRIMARYcolor,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 25),
          status != 'pickedup'
              ? SizedBox()
              : Text(
            "$hoursStr:$minutesStr:$secondsStr",
            style: TextStyle(
                fontSize: 24.0,
                color: Colors.cyan,
                fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 45),
          status == 'pickedup'
              ? widget.call.callerId == widget.currentuseruid
              ? widget.call.receiverPic == null
              ? SizedBox(
            height: w > h ? 60 : 140,
          )
              : CachedImage(
            widget.call.callerId == widget.currentuseruid
                ? widget.call.receiverPic
                : widget.call.callerPic,
            isRound: true,
            height: w > h ? 60 : 140,
            width: w > h ? 60 : 140,
            radius: w > h ? 70 : 168,
          )
              : widget.call.callerPic == null
              ? SizedBox(
            height: w > h ? 60 : 140,
          )
              : CachedImage(
            widget.call.callerId == widget.currentuseruid
                ? widget.call.receiverPic
                : widget.call.callerPic,
            isRound: true,
            height: w > h ? 60 : 140,
            width: w > h ? 60 : 140,
            radius: w > h ? 70 : 168,
          )
              : Container(
            height: w > h ? 60 : 140,
            width: w > h ? 60 : 140,
            child: Icon(
              status == 'ended' ||
                  status == 'rejected' ||
                  status == 'pickedup'
                  ? Icons.call_end_sharp
                  : Icons.call,
              size: w > h ? 60 : 140,
              color: pickTextColorBasedOnBgColorAdvanced(
                  Thm.isDarktheme(widget.prefs)
                      ? corncallAPPBARcolorDarkMode
                      : corncallAPPBARcolorLightMode)
                  .withOpacity(0.25),
            ),
          ),
          SizedBox(height: 45),
          Text(
            widget.call.callerId == widget.currentuseruid
                ? widget.call.receiverName!
                : widget.call.callerName!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pickTextColorBasedOnBgColorAdvanced(
                  Thm.isDarktheme(widget.prefs)
                      ? corncallAPPBARcolorDarkMode
                      : corncallAPPBARcolorLightMode),
              fontSize: 22,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            IsRemovePhoneNumberFromCallingPageWhenOnCall == true
                ? ''
                : widget.call.callerId == widget.currentuseruid
                ? widget.call.receiverId!
                : widget.call.callerId!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pickTextColorBasedOnBgColorAdvanced(
                  Thm.isDarktheme(widget.prefs)
                      ? corncallAPPBARcolorDarkMode
                      : corncallAPPBARcolorLightMode)
                  .withOpacity(0.54),
              fontSize: 19,
            ),
          ),
          SizedBox(
            height: h / 10,
          ),
          status == 'pickedup'
              ? ispeermuted == true
              ? Text(
            getTranslated(context, 'muted'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
              fontSize: 19,
            ),
          )
              : SizedBox(
            height: 0,
          )
              : SizedBox(
            height: 0,
          )
        ],
      ),
    );
  }

  Widget _panel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: ListView.builder(
            reverse: true,
            itemCount: _infoStrings.length,
            itemBuilder: (BuildContext context, int index) {
              if (_infoStrings.isEmpty) {
                return SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                  horizontal: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  TextEditingController controller = TextEditingController();
  var ratingValue = 0.0;
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
            "Call Feedback",
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
                  "Submit"
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
    final Observer observer = Provider.of<Observer>(context, listen: false);
    stopWatchStream();
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
    _stopCallingSound();
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
   _onToggleMute(RTCPeerConnection? peerConnection, String kind, bool enabled) async {


    var transrecievers = (await peerConnection?.getTransceivers())?.where((element) => element.sender.track?.kind == kind).toList();
    if (transrecievers?.isEmpty == true) {
    return;
    }
    await transrecievers?.first.setDirection(enabled ? TransceiverDirection.SendOnly : TransceiverDirection.Inactive);

    // var rm = localVideoRenderer;
    // if ( rm!.mediaStream?.getAudioTracks()!.isNotEmpty == true) {
    //   rm.mediaStream?.getAudioTracks()[0].enabled = muted;
    //
    // }
    // setState(() {
    //   muted = !muted;
    // });
    _stopCallingSound();

    // _engine.muteLocalAudioStream(muted);
    FirebaseFirestore.instance
        .collection(DbPaths.collectionusers)
        .doc(widget.currentuseruid)
        .collection(DbPaths.collectioncallhistory)
        .doc(widget.call.timeepoch.toString())
        .set({'ISMUTED': !audioEnabled}, SetOptions(merge: true));
  }

  void _onToggleSpeaker() async {
    await Helper.setSpeakerphoneOn(isspeaker);
    setState(() {
      isspeaker = !isspeaker;
    });

    // _engine.setEnableSpeakerphone(isspeaker);
  }

  Future<bool> onWillPopNEw() {
    return Future.value(false);
  }
  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }
  List<LocalUserData> _selectedList = [];
  List<String> inCallUserList = [];
  List<String> callUserList = [];
  call(BuildContext context, bool isvideocall,String peerNo,String photoUrl,String peerNickName) async {
    var mynickname = widget.prefs.getString(Dbkeys.nickname) ?? '';

    var myphotoUrl = widget.prefs.getString(Dbkeys.photoUrl) ?? '';

    CallUtils.dialDuringCall(
        prefs: widget.prefs,
        currentuseruid: widget.currentuseruid,
        fromDp: myphotoUrl,
        toDp: photoUrl,
        fromUID: widget.currentuseruid,
        fromFullname: mynickname,
        toUID: peerNo,
        toFullname: peerNickName,
        context: context,
        isvideocall: isvideocall);

  }
  endCall(String userId)
  {
    CallUtils.endCallForSpecficUser(userId:userId);
    int index = callUserList.indexWhere((element) => element == userId);
    if (index != -1) {
      callUserList.removeAt(index);
    } else {

    }

  }
  void showBottomDialog(BuildContext context) {
    showGeneralDialog(
      barrierLabel: "showGeneralDialog",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      context: context,
      pageBuilder: (context, _, __) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Consumer<SmartContactProviderWithLocalStoreData>(
                builder: (context, contactsProvider, _child) {
                  return Scaffold(
                    appBar: AppBar(
                      elevation: 0.4,
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
                      title: _selectedList.length == 0
                          ? Text(
                        getTranslated(
                            this.context, 'selectcontacts'),
                        style: TextStyle(
                          fontSize: 18,
                          color: pickTextColorBasedOnBgColorAdvanced(
                              Thm.isDarktheme(widget.prefs)
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
                            getTranslated(
                                this.context, 'selectcontacts') + ' In Call',
                            style: TextStyle(
                              fontSize: 18,
                              color: pickTextColorBasedOnBgColorAdvanced(Thm
                                  .isDarktheme(widget.prefs)
                                  ? corncallAPPBARcolorDarkMode
                                  : corncallAPPBARcolorLightMode),
                            ),
                            textAlign: TextAlign.left,
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Text('${_selectedList.length} ${getTranslated(
                              this.context, 'selected')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: pickTextColorBasedOnBgColorAdvanced(Thm
                                  .isDarktheme(widget.prefs)
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
                            Icons.call,
                            color: pickTextColorBasedOnBgColorAdvanced(Thm
                                .isDarktheme(widget.prefs)
                                ? corncallAPPBARcolorDarkMode
                                : corncallAPPBARcolorLightMode),
                          ),
                          onPressed: () async {
                            // List<String> listusers = [];
                            List<String> listmembers =
                            [];
                            for (var element
                            in _selectedList) {
                              await contactsProvider
                                  .fetchFromFiretsoreAndReturnData(
                                  widget.prefs, element.id, (peerDoc) async {
                                listmembers
                                    .add(element.id);

                                if (peerDoc.data()![Dbkeys
                                    .notificationTokens] !=
                                    null) {
                                  if (peerDoc
                                      .data()![Dbkeys
                                      .notificationTokens]
                                      .length >
                                      0) {
                                    print(
                                        peerDoc.data()![Dbkeys.notificationTokens]
                                            .last);

                                    call(context, false,
                                        peerDoc.data()![Dbkeys.phone],
                                        peerDoc.data()![Dbkeys.photoUrl],
                                        peerDoc.data()![Dbkeys.nickname]);
                                    callUserList.add(
                                        peerDoc.data()![Dbkeys.phone]);
                                    setState(() {

                                    });
                                    // targetUserNotificationTokens
                                    //     .add(peerDoc
                                    //     .data()![
                                    // Dbkeys
                                    //     .notificationTokens]
                                    //     .last);

                                  }
                                  else {
                                    print('User Offline');
                                  }
                                }
                              });
                            }
                            DateTime time =
                            DateTime.now();
                            setState(() {

                            });
                            setStateIfMounted(() {
                              // iscreatinggroup = true;
                            });

                            Map<String, dynamic>
                            docmap = {
                              Dbkeys.groupMEMBERSLIST:
                              FieldValue
                                  .arrayUnion(
                                  listmembers)
                            };

                            _selectedList.forEach(
                                    (element) async {
                                  docmap.putIfAbsent(
                                      '${element.id}-joinedOn',
                                          () =>
                                      time
                                          .millisecondsSinceEpoch);
                                  docmap.putIfAbsent(
                                      '${element.id}',
                                          () =>
                                      time
                                          .millisecondsSinceEpoch);
                                });
                            setStateIfMounted(() {});

                          },
                        )
                      ],
                    ),
                    // key: _scaffold,
                    body: RefreshIndicator(
                        onRefresh: () {
                          return contactsProvider.fetchContacts(
                              context,
                              _cachedModel,
                              widget.currentuseruid!,
                              widget.prefs);
                        },
                        child: contactsProvider
                            .alreadyJoinedSavedUsersPhoneNameAsInServer
                            .length ==
                            0
                            ? ListView(
                            shrinkWrap: true,
                            children: [
                              Padding(
                                  padding: EdgeInsets.only(
                                      top: MediaQuery
                                          .of(
                                          context)
                                          .size
                                          .height /
                                          2.5),
                                  child: Center(
                                    child: Text(
                                        getTranslated(
                                            context,
                                            'nosearchresult'),
                                        textAlign: TextAlign
                                            .center,
                                        style: TextStyle(
                                            fontSize: 18,
                                            color:
                                            corncallGrey)),
                                  ))
                            ])
                            : Padding(
                          padding: EdgeInsets.only(
                              bottom:
                              _selectedList.length == 0
                                  ? 0
                                  : 80),
                          child: Stack(
                            children: [
                              FutureBuilder(
                                  future: Future.delayed(
                                      Duration(seconds: 2)),
                                  builder: (c, s) =>
                                  s.connectionState ==
                                      ConnectionState
                                          .done
                                      ? Container(
                                    alignment:
                                    Alignment
                                        .topCenter,
                                    child:
                                    Padding(
                                      padding:
                                      EdgeInsets.all(
                                          30),
                                      child: Card(
                                        elevation:
                                        0.5,
                                        color: Colors
                                            .grey[
                                        100],
                                        child: Container(
                                            padding: EdgeInsets.fromLTRB(
                                                8, 10, 8, 10),
                                            child: RichText(
                                              textAlign:
                                              TextAlign.center,
                                              text:
                                              TextSpan(
                                                children: [
                                                  WidgetSpan(
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .only(
                                                          bottom: 2.5, right: 4),
                                                      child: Icon(
                                                        Icons.contact_page,
                                                        color: corncallPRIMARYcolor
                                                            .withOpacity(0.7),
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  TextSpan(
                                                      text: getTranslated(
                                                          this.context,
                                                          'nosavedcontacts'),
                                                      // text:
                                                      //     'No Saved Contacts available for this task',
                                                      style: TextStyle(
                                                          color: corncallPRIMARYcolor
                                                              .withOpacity(0.7),
                                                          height: 1.3,
                                                          fontSize: 13,
                                                          fontWeight: FontWeight
                                                              .w400)),
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
                                          AlwaysStoppedAnimation<Color>(
                                              corncallSECONDARYolor),
                                        )),
                                  )),
                              Container(
                                color: Thm.isDarktheme(
                                    widget.prefs)
                                    ? corncallCONTAINERboxColorDarkMode
                                    : corncallCONTAINERboxColorLightMode,
                                child: ListView.builder(
                                  physics:
                                  AlwaysScrollableScrollPhysics(),
                                  padding:
                                  EdgeInsets.all(10),
                                  itemCount: contactsProvider
                                      .alreadyJoinedSavedUsersPhoneNameAsInServer
                                      .length,
                                  itemBuilder:
                                      (context, idx) {
                                    String phone =
                                        contactsProvider
                                            .alreadyJoinedSavedUsersPhoneNameAsInServer[
                                        idx]
                                            .phone;
                                    Widget? alreadyAddedUser = null;
                                    return alreadyAddedUser ??
                                        FutureBuilder<
                                            LocalUserData?>(
                                            future: contactsProvider
                                                .fetchUserDataFromnLocalOrServer(
                                                widget
                                                    .prefs,
                                                phone),
                                            builder: (BuildContext
                                            context,
                                                AsyncSnapshot<
                                                    LocalUserData?>
                                                snapshot) {

                                              if (snapshot
                                                  .hasData) {
                                                LocalUserData
                                                user = snapshot.data!;

                                                // print("^^^^^^^^^^^^^^${user.id}");
                                                return inCallUserList.contains(
                                                    user.id) ? SizedBox(
                                                  height: 0,
                                                ) :
                                                Container(
                                                    color: Thm.isDarktheme(
                                                        widget.prefs)
                                                        ? corncallCONTAINERboxColorDarkMode
                                                        : corncallCONTAINERboxColorLightMode,
                                                    child:
                                                    Column(
                                                      children: [
                                                        ListTile(
                                                          tileColor: Thm
                                                              .isDarktheme(
                                                              widget.prefs)
                                                              ? corncallCONTAINERboxColorDarkMode
                                                              : corncallCONTAINERboxColorLightMode,
                                                          leading: customCircleAvatar(
                                                            url: user.photoURL,
                                                            radius: 22.5,
                                                          ),
                                                          trailing: callUserList.contains(
                                                              user.id) ? Icon(
                                                            Icons.call_end,
                                                            color: Colors
                                                                .red,
                                                            size: 40.0,
                                                          ) : Container(
                                                            decoration: BoxDecoration(
                                                              border: Border.all(
                                                                  color: corncallGrey,
                                                                  width: 1),
                                                              borderRadius: BorderRadius
                                                                  .circular(5),
                                                            ),
                                                            child: _selectedList
                                                                .lastIndexWhere((
                                                                element) =>
                                                            element.id ==
                                                                phone) >= 0
                                                                ? Icon(
                                                              Icons.check,
                                                              size: 19.0,
                                                              color: corncallPRIMARYcolor,
                                                            )
                                                                :  Icon(
                                                              Icons.check,
                                                              color: Colors
                                                                  .transparent,
                                                              size: 19.0,
                                                            ),
                                                          ),
                                                          title:  Row(
                                                            children: [
                                                              Text(user.name,
                                                                  style: TextStyle(
                                                                    color: pickTextColorBasedOnBgColorAdvanced(
                                                                        Thm
                                                                            .isDarktheme(
                                                                            widget
                                                                                .prefs)
                                                                            ? corncallCONTAINERboxColorDarkMode
                                                                            : corncallCONTAINERboxColorLightMode),
                                                                  )),
                                                              callUserList
                                                                  .contains(user.id)
                                                                  ?   Lottie.asset("assets/sounds/112098-call.json",width: 60,height: 40) : Container()
                                                            ],
                                                          ),

                                                          subtitle: Text(phone,
                                                              style: TextStyle(
                                                                  color: corncallGrey)),
                                                          contentPadding: EdgeInsets
                                                              .symmetric(
                                                              horizontal: 10.0,
                                                              vertical: 0.0),
                                                          onTap: () {
                                                            if(callUserList.contains(
                                                                user.id))
                                                            {
                                                              //end call here
                                                              endCall(user.id);
                                                              setState(() {

                                                              });
                                                            }
                                                            else {
                                                              if (_selectedList
                                                                  .indexWhere((
                                                                  element) =>
                                                              element.id ==
                                                                  phone) >= 0) {
                                                                _selectedList
                                                                    .removeAt(
                                                                    _selectedList
                                                                        .indexWhere((
                                                                        element) =>
                                                                    element.id ==
                                                                        phone));
                                                                setStateIfMounted(() {});
                                                              } else {
                                                                _selectedList.add(
                                                                    user);

                                                                setStateIfMounted(() {});
                                                              }
                                                              setState(() {

                                                              });
                                                            }
                                                          },
                                                        ),
                                                        Divider()
                                                      ],
                                                    ));
                                              }
                                              return SizedBox(
                                                height: 0,
                                              );
                                            });
                                  },
                                ),
                              ),
                            ],
                          ),
                        )),
                  );
                },
              );
            }
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


  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    var h = MediaQuery.of(context).size.height;
    setStatusBarColor(widget.prefs);
    return WillPopScope(
        onWillPop: onWillPopNEw,
        child: h > w && ((h / w) > 1.5)
            ? PIPView(builder: (context, isFloating) {
          return Scaffold(
              backgroundColor: Thm.isDarktheme(widget.prefs)
                  ? corncallAPPBARcolorDarkMode
                  : corncallAPPBARcolorLightMode,
              body:
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>?>?>(
                stream: stream
                as Stream<DocumentSnapshot<Map<String, dynamic>?>?>?,
                builder: (BuildContext context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data == null) {
                      return Center(
                        child: Stack(
                          children: <Widget>[
                            Visibility(
                              visible: false,
                              child: GridView.builder(
                                  shrinkWrap: true,
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2),
                                  itemCount: videoState.streamsToBeRendered.entries.length,
                                  itemBuilder: (context, index) {
                                    List<StreamRenderer> items = videoState
                                        .streamsToBeRendered.entries
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
                                                  "Video Paused By " +
                                                      remoteStream.publisherName!,
                                                  style:
                                                  const TextStyle(color: Colors.black)),
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
                                          alignment: AlignmentDirectional.bottomStart,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Visibility(
                                                  visible: raiseHandUserList.contains(
                                                      remoteStream.id.toString()) ==
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
                                                            contentPadding:
                                                            const EdgeInsets.all(10),
                                                            insetPadding: EdgeInsets.zero,
                                                            content: Container(
                                                              width: double.maxFinite,
                                                              padding: EdgeInsets.zero,
                                                              child: Stack(
                                                                children: [
                                                                  Positioned.fill(
                                                                      child: Padding(
                                                                        padding:
                                                                        const EdgeInsets.all(
                                                                            0),
                                                                        child: RTCVideoView(
                                                                          remoteStream
                                                                              .videoRenderer,
                                                                        ),
                                                                      )),
                                                                  Align(
                                                                    alignment:
                                                                    Alignment.topRight,
                                                                    child: IconButton(
                                                                        onPressed: () {
                                                                          Navigator.of(
                                                                              context)
                                                                              .pop(
                                                                              fullScreenDialog);
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
                                  }),
                            ),
                            audioscreenForPORTRAIT(
                                context: context,
                                status: 'calling',
                                ispeermuted: false),
                            _panel(),
                            _toolbar(false, 'calling', context),
                          ],
                        ),
                      );
                    }
                    else {
                      if (snapshot.data!.data() == null) {
                        return Center(
                          child: Stack(
                            children: <Widget>[
                              audioscreenForPORTRAIT(
                                  context: context,
                                  status: 'calling',
                                  ispeermuted: false),
                              _panel(),
                              _toolbar(false, 'calling', context),
                            ],
                          ),
                        );
                      }
                      else {
                        return Center(
                          child: Stack(
                            children: <Widget>[
                              // _viewRows(),
                              audioscreenForPORTRAIT(
                                  context: context,
                                  status:
                                  snapshot.data!.data()!["STATUS"],
                                  ispeermuted:
                                  snapshot.data!.data()!["ISMUTED"]),

                              _panel(),
                              _toolbar(
                                  snapshot.data!.data()!["STATUS"] ==
                                      'pickedup'
                                      ? true
                                      : false,
                                  snapshot.data!.data()!["STATUS"],
                                  context),
                            ],
                          ),
                        );
                      }
                    }
                  }
                  else if (!snapshot.hasData) {
                    return Center(
                      child: Stack(
                        children: <Widget>[
                          // _viewRows(),
                          audioscreenForPORTRAIT(
                              context: context,
                              status: 'nonetwork',
                              ispeermuted: false),
                          _panel(),
                          _toolbar(false, 'nonetwork', context),
                        ],
                      ),
                    );
                  }

                  return Center(
                    child: Stack(
                      children: <Widget>[
                        // _viewRows(),
                        audioscreenForPORTRAIT(
                            context: context,
                            status: 'calling',
                            ispeermuted: false),
                        _panel(),
                        _toolbar(false, 'calling', context),
                      ],
                    ),
                  );
                },
              ));
        })
            : PIPView(builder: (context, isFloating) {
          return Scaffold(
              backgroundColor: Thm.isDarktheme(widget.prefs)
                  ? corncallAPPBARcolorDarkMode
                  : corncallAPPBARcolorLightMode,
              body:
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>?>?>(
                stream: stream
                as Stream<DocumentSnapshot<Map<String, dynamic>?>?>?,
                builder: (BuildContext context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data == null) {
                      return Center(
                        child: Stack(
                          children: <Widget>[
                            audioscreenForLANDSCAPE(
                                context: context,
                                status: 'calling',
                                ispeermuted: false),
                            _panel(),
                            _toolbar(false, 'calling', context),
                          ],
                        ),
                      );
                    } else {
                      if (snapshot.data!.data() == null) {
                        return Center(
                          child: Stack(
                            children: <Widget>[
                              audioscreenForLANDSCAPE(
                                  context: context,
                                  status: 'calling',
                                  ispeermuted: false),
                              _panel(),
                              _toolbar(false, 'calling', context),
                            ],
                          ),
                        );
                      } else {

                        return Center(
                          child: Stack(
                            children: <Widget>[
                              // _viewRows(),
                              audioscreenForLANDSCAPE(
                                  context: context,
                                  status:
                                  snapshot.data!.data()!["STATUS"],
                                  ispeermuted:
                                  snapshot.data!.data()!["ISMUTED"]),
                              _panel(),
                              _toolbar(
                                  snapshot.data!.data()!["STATUS"] ==
                                      'pickedup'
                                      ? true
                                      : false,
                                  snapshot.data!.data()!["STATUS"],
                                  context),
                            ],
                          ),
                        );
                      }
                    }
                  }
                  else if (!snapshot.hasData) {
                    return Center(
                      child: Stack(
                        children: <Widget>[
                          // _viewRows(),
                          audioscreenForLANDSCAPE(
                              context: context,
                              status: 'nonetwork',
                              ispeermuted: false),
                          _panel(),
                          _toolbar(false, 'nonetwork', context),
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Stack(
                      children: <Widget>[
                        // _viewRows(),
                        audioscreenForLANDSCAPE(
                            context: context,
                            status: 'calling',
                            ispeermuted: false),
                        _panel(),
                        _toolbar(false, 'calling', context),
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
