
import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:janus_client/janus_client.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_icons/flutter_icons.dart';
// import './participants_model.dart';
import 'colors.dart';
import 'Meeting_User_Model.dart';

class ParticipantsPage extends StatefulWidget {

  const ParticipantsPage({
    Key? key,
  }) : super(key: key);
  @override
  _ParticipantsPageState createState() => _ParticipantsPageState();
}

class _ParticipantsPageState extends State<ParticipantsPage> {
  @override
  Widget build(BuildContext context) {
    final userList = [];
    var participantsCount = userList!.length;
    var size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: mainColor,

      appBar:  AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 10),
            child: Text(
              "Close",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.blue[600]),
            ),
          ),
        ),
        centerTitle: true,
        title: Text("Participants ($participantsCount)",style: TextStyle(color: Colors.black,fontSize: 16),),
      ),

      bottomSheet: Container(
        width: size.width,
        height: 55,
        decoration: BoxDecoration(color: Colors.grey[50]),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Padding(
                padding: const EdgeInsets.only(left: 10,top: 5),
                child: Container(
                  decoration: BoxDecoration(
                      color: Color(0xffe4e4ed),
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      "Invite",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(right: 10,top: 5),
                child: Container(
                  decoration: BoxDecoration(
                      color: Color(0xffe4e4ed),
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      "Mute all",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 15, bottom: 70),
            child: Column(
                children: List.generate(userList.length, (index) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 20, right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                          image: NetworkImage(userList![index].profile.toString()),
                                          fit: BoxFit.cover)),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  userList![index].display.toString(),
                                  style: TextStyle(fontSize: 16),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  userList![index].isAudioOn == false
                                      ? Icons.mic
                                      : Icons.mic_off,
                                  color: userList![index].isAudioOn == false ? Colors.grey : Colors.red,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  userList![index].isVideoOn == false
                                      ? Icons.videocam
                                      : Icons.videocam_off,
                                  color: userList![index].isVideoOn == false ? Colors.grey : Colors.red,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Divider()
                    ],
                  );
                })),
          ))
    );
  }


}