// //*************   © Copyrighted by Criterion Tech. *********************

// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:corncall/Configs/Dbkeys.dart';
// import 'package:corncall/Configs/Dbpaths.dart';
// import 'package:corncall/Configs/optional_constants.dart';
// import 'package:corncall/Screens/status/components/VideoPicker/VideoPicker.dart';
// import 'package:corncall/Services/Providers/StatusProvider.dart';
// import 'package:corncall/Services/Providers/Observer.dart';
// import 'package:corncall/Services/localization/language_constants.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:path/path.dart';
// import 'dart:async';
// import 'package:provider/provider.dart';
// import 'package:video_compress/video_compress.dart' as compress;

// class StatusCameraOpener extends StatefulWidget {
//   final String currentUserNo;
//   final List<dynamic> phoneNumberVariants;
//   final Function ontabChange;
//   const StatusCameraOpener(
//       {Key? key,
//       required this.currentUserNo,
//       required this.phoneNumberVariants,
//       required this.ontabChange})
//       : super(key: key);

//   @override
//   State<StatusCameraOpener> createState() => _StatusCameraOpenerState();
// }

// class _StatusCameraOpenerState extends State<StatusCameraOpener> {
//   uploadFile(
//       {required File file,
//       String? caption,
//       double? duration,
//       required String type,
//       required String filename}) async {
//     final observer = Provider.of<Observer>(this.context, listen: false);
//     final StatusProvider statusProvider =
//         Provider.of<StatusProvider>(this.context, listen: false);
//     statusProvider.setIsLoading(true);
//     int uploadTimestamp = DateTime.now().millisecondsSinceEpoch;

//     Reference reference = FirebaseStorage.instance
//         .ref()
//         .child('+00_STATUS_MEDIA/${widget.currentUserNo}/$filename');
//     File? compressedImage;
//     File? compressedVideo;
//     File? fileToCompress;
//     if (type == Dbkeys.statustypeIMAGE) {
//       final targetPath =
//           file.absolute.path.replaceAll(basename(file.absolute.path), "") +
//               "temp.jpg";

//       compressedImage = await FlutterImageCompress.compressAndGetFile(
//         file.absolute.path,
//         targetPath,
//         quality: DpImageQualityCompress,
//         rotate: 0,
//       );
//     } else if (type == Dbkeys.statustypeVIDEO) {
//       fileToCompress = File(file.path);
//       await compress.VideoCompress.setLogLevel(0);

//       final compress.MediaInfo? info =
//           await compress.VideoCompress.compressVideo(
//         fileToCompress.path,
//         quality: IsVideoQualityCompress == true
//             ? compress.VideoQuality.MediumQuality
//             : compress.VideoQuality.HighestQuality,
//         deleteOrigin: false,
//         includeAudio: true,
//       );
//       compressedVideo = File(info!.path!);
//     }
//     await reference
//         .putFile(type == Dbkeys.statustypeIMAGE
//             ? compressedImage!
//             : type == Dbkeys.statustypeVIDEO
//                 ? compressedVideo!
//                 : file)
//         .then((uploadTask) async {
//       String url = await uploadTask.ref.getDownloadURL();
//       FirebaseFirestore.instance
//           .collection(DbPaths.collectionnstatus)
//           .doc(widget.currentUserNo)
//           .set({
//         Dbkeys.statusITEMSLIST: FieldValue.arrayUnion([
//           type == Dbkeys.statustypeVIDEO
//               ? {
//                   Dbkeys.statusItemID: uploadTimestamp,
//                   Dbkeys.statusItemURL: url,
//                   Dbkeys.statusItemTYPE: type,
//                   Dbkeys.statusItemCAPTION: caption,
//                   Dbkeys.statusItemDURATION: duration,
//                 }
//               : {
//                   Dbkeys.statusItemID: uploadTimestamp,
//                   Dbkeys.statusItemURL: url,
//                   Dbkeys.statusItemTYPE: type,
//                   Dbkeys.statusItemCAPTION: caption,
//                 }
//         ]),
//         Dbkeys.statusPUBLISHERPHONE: widget.currentUserNo,
//         Dbkeys.statusPUBLISHERPHONEVARIANTS: widget.phoneNumberVariants,
//         Dbkeys.statusVIEWERLIST: [],
//         Dbkeys.statusVIEWERLISTWITHTIME: [],
//         Dbkeys.statusPUBLISHEDON: DateTime.now(),
//         // uploadTimestamp,
//         Dbkeys.statusEXPIRININGON: DateTime.now()
//             .add(Duration(hours: observer.statusDeleteAfterInHours)),
//         // .millisecondsSinceEpoch,
//       }, SetOptions(merge: true)).then((value) {
//         statusProvider.setIsLoading(false);
//       });
//     }).onError((error, stackTrace) {
//       statusProvider.setIsLoading(false);
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     widget.ontabChange();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: listv,
//     );
//   }
// }
