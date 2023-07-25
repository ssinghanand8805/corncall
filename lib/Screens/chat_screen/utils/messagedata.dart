//*************   © Copyrighted by Criterion Tech. *********************

import 'package:cloud_firestore/cloud_firestore.dart';

class MessageData {
  dynamic lastSeen;
  QuerySnapshot snapshot;

  MessageData({
    required this.snapshot,
    required this.lastSeen,
  });
}
