import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Configs/Dbpaths.dart';
import '../../Configs/app_constants.dart';
import '../../Services/localization/language_constants.dart';
import '../../Utils/color_detector.dart';
import '../../Utils/theme_management.dart';

class FeedBackView extends StatefulWidget {
  final SharedPreferences prefs;
  final String currentUserNo;
  const FeedBackView(
      {super.key, required this.prefs, required this.currentUserNo});

  @override
  State<FeedBackView> createState() => _FeedBackViewState();
}

class _FeedBackViewState extends State<FeedBackView> {
  var ratingValue = 0.0;
  List request = [];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> feedbackList = [
      {"name": getTranslated(context, 'name1')},
      {"name": getTranslated(context, 'name2')},
      {"name": getTranslated(context, 'name3')},
      {"name": getTranslated(context, 'name4')},
      {"name": getTranslated(context, 'name5')},
      {"name": getTranslated(context, 'name6')},
      {"name": getTranslated(context, 'name7')},
      {"name": getTranslated(context, 'name8')},
      {"name": getTranslated(context, 'name9')}
    ];
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
                centerTitle: true,
                leading: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                  ),
                ),
                elevation: 0,
                backgroundColor: Thm.isDarktheme(widget.prefs)
                    ? corncallAPPBARcolorDarkMode
                    : corncallAPPBARcolorLightMode,
                title: Text(
                  getTranslated(context, 'feedback'),
                )),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: feedbackList.length,
                        itemBuilder: (BuildContext context, int index2) {
                          final translatedName = getTranslated(context, feedbackList[index2]["name"].toString());

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: pickTextColorBasedOnBgColorAdvanced(
                                      Thm.isDarktheme(widget.prefs)
                                          ? corncallBACKGROUNDcolorLightMode
                                          : corncallBACKGROUNDcolorDarkMode)),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 5.0,
                                          ),
                                          child: Icon(
                                            Icons.circle,
                                            size: 10,
                                            color: corncallPRIMARYcolor,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child: Text(
                                            feedbackList[index2]["name"].toString(),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                        .isDarktheme(
                                                            widget.prefs)
                                                    ? corncallBACKGROUNDcolorDarkMode
                                                    : corncallBACKGROUNDcolorLightMode)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 12.0),
                                      child: RatingBar.builder(
                                        updateOnDrag: true,
                                        initialRating: 0,
                                        minRating: 0,
                                        direction: Axis.horizontal,
                                        allowHalfRating: false,
                                        itemCount: 5,
                                        itemSize: 20,
                                        itemPadding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        itemBuilder: (context, _) => Icon(
                                          Icons.star,
                                          color: corncallPRIMARYcolor,
                                        ),
                                        onRatingUpdate: (rating) {
                                          String question = feedbackList[index2]
                                                  ["name"]
                                              .toString();
                                          String ratingValue =
                                              rating.toString();
                                          bool existingQuestion = false;
                                          for (var item in request) {
                                            if (item['question'] == question) {
                                              existingQuestion = true;
                                              print("question already adjust");
                                              item['ratingvalue'] = ratingValue;
                                              break;
                                            }
                                          }
                                          if (!existingQuestion) {
                                            request.add({
                                              'question': question,
                                              'ratingvalue': ratingValue
                                            });
                                          }
                                          print(request);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        style: ButtonStyle(
                            minimumSize:
                                MaterialStateProperty.all<Size>(Size(100, 40)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                              corncallPRIMARYcolor,
                            ),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                            ))),
                        child: Text(
                          getTranslated(context, "submit"),
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () async {
                          var d = DateTime.now().millisecondsSinceEpoch;
                          await FirebaseFirestore.instance
                              .collection(DbPaths.collectionusers)
                              .doc(widget.currentUserNo)
                              .collection('feedback')
                              .doc(d.toString())
                              .set({"feedback": request.toString()},
                                  SetOptions(merge: true));
                          Navigator.of(context).pop();
                          Corncall.toast(getTranslated(context, "thankforfeedback"));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            )));
  }
}
