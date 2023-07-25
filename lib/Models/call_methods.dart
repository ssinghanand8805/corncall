//*************   © Copyrighted by Criterion Tech. *********************

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corncall/Configs/Dbpaths.dart';
import 'package:corncall/Models/call.dart';
import 'package:flutter/material.dart';

class CallMethods {
  Stream<DocumentSnapshot> callStream({String? phone}) =>
      FirebaseFirestore.instance
          .collection(DbPaths.collectioncall)
          .doc(phone)
          .snapshots();

  Future<bool> makeCall(
      {required Call call,
        required bool? isvideocall,
        required int timeepoch}) async {
    try {
      call.hasDialled = true;
      Map<String, dynamic> hasDialledMap = call.toMap(call);

      call.hasDialled = false;
      Map<String, dynamic> hasNotDialledMap = call.toMap(call);

      await FirebaseFirestore.instance
          .collection(DbPaths.collectioncall)
          .doc(call.callerId)
          .set(hasDialledMap, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection(DbPaths.collectioncall)
          .doc(call.receiverId)
          .set(hasNotDialledMap, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }


  Future<bool> makeCallDuringCall(
      {required Call call,
        required bool? isvideocall,
        required int timeepoch}) async {
    try {

      call.hasDialled = false;
      Map<String, dynamic> hasNotDialledMap = call.toMap(call);


      await FirebaseFirestore.instance
          .collection(DbPaths.collectioncall)
          .doc(call.receiverId)
          .set(hasNotDialledMap, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> endCall({required Call call}) async {
    try {
      await FirebaseFirestore.instance
          .collection(DbPaths.collectioncall)
          .doc(call.callerId)
          .delete();
      await FirebaseFirestore.instance
          .collection(DbPaths.collectioncall)
          .doc(call.receiverId)
          .delete();
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<bool> endCallForSpecficUser({required String userId}) async {
    try {
      await FirebaseFirestore.instance
          .collection(DbPaths.collectioncall)
          .doc(userId)
          .delete();

      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }
}
