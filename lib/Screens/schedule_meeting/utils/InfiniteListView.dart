//*************   © Copyrighted by Criterion Tech. *********************

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corncall/Configs/app_constants.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Services/Providers/call_history_provider.dart';
import 'package:corncall/Utils/color_detector.dart';
import 'package:corncall/Utils/theme_management.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/Providers/schdule_history_provider.dart';
import '../create_meeting.dart';

class InfiniteListView extends StatefulWidget {
  final FirestoreDataProviderScheduleHISTORY?
      firestoreDataProviderScheduleHISTORY;
  final String? datatype;
  final String? currentuseruid;
  final Widget? list;
  final Query? refdata;
  final SharedPreferences prefs;
  final bool? isreverse;
  final EdgeInsets? padding;
  final String? parentid;
  const InfiniteListView({
    this.firestoreDataProviderScheduleHISTORY,
    this.datatype,
    this.currentuseruid,
    this.isreverse,
    this.padding,
    required this.prefs,
    this.parentid,
    this.list,
    this.refdata,
    Key? key,
  }) : super(key: key);

  @override
  _InfiniteListViewState createState() => _InfiniteListViewState();
}

class _InfiniteListViewState extends State<InfiniteListView> {
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void scrollListener() {
    if (scrollController.offset >=
            scrollController.position.maxScrollExtent / 2 &&
        !scrollController.position.outOfRange) {
      if (widget.datatype == 'SCHEDULEHISTORY') {
        if (widget.firestoreDataProviderScheduleHISTORY!.hasNext) {
          widget.firestoreDataProviderScheduleHISTORY!
              .fetchNextData(widget.datatype, widget.refdata, false);
        }
      } else {}
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        physics: BouncingScrollPhysics(),
        shrinkWrap: true,
        reverse: widget.isreverse == null || widget.isreverse == false
            ? false
            : true,
        controller: scrollController,
        padding: widget.padding == null ? EdgeInsets.all(0) : widget.padding,
        children: widget.datatype == 'SCHEDULEHISTORY'
            ?
            //-----PRODUCTS

            [
               Text("data")
              ]
            : [
                InkWell(
                  onTap: () {

                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => MeetingForm(prefs: widget.prefs, currentuseruid: widget.currentuseruid)));
                  },
                  child: Container(
                    color: Theme.of(context).brightness == Brightness.light
                        ? SplashBackgroundSolidColor
                        : SplashBackgroundSolidColor,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                              getTranslated(
                                  context, 'ScheduleMeeting'),
                              style: TextStyle(
                                  color: corncallWhite,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600)),

                        ),
                      ],
                    ),
                  ),
                ),
              ],
      );
}
