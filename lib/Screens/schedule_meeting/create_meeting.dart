import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Configs/Dbpaths.dart';
import '../../Configs/app_constants.dart';
import '../../Models/scheduleMeeting.dart';
import '../../Services/Providers/SmartContactProviderWithLocalStoreData.dart';
import '../../Services/Providers/user_provider.dart';
import '../../Services/localization/language_constants.dart';
import '../../Utils/theme_management.dart';

class MeetingForm extends StatefulWidget {
  final SharedPreferences prefs;
  final String? currentuseruid;

  const MeetingForm({super.key, required this.prefs,required this.currentuseruid});
  @override
  _MeetingFormState createState() => _MeetingFormState();
}

class _MeetingFormState extends State<MeetingForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController meetingController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserList();

    random();
    password();
  }
  void _saveScheduleMeetings() async {


    List idOnly = [];
    selectedUser.forEach((element) {
      idOnly.add(element['id']);
    });

    var hostName = '';
    if(selectedValue == 'Select Self as Host')
    {
      var selfuserData = await FirebaseFirestore.instance.collection(DbPaths.collectionusers).doc(widget.currentuseruid).get();
      UserModel? user;
      if (selfuserData.data() != null) {
        user = UserModel.fromMap(selfuserData.data()!);
      }
      hostName = user!.name.toString();
      //return user;
    }
    else
    {
      var selfuserData = await FirebaseFirestore.instance.collection(DbPaths.collectionusers).doc(selectedValue).get();
      UserModel? user;
      if (selfuserData.data() != null) {
        user = UserModel.fromMap(selfuserData.data()!);
      }
      hostName = user!.name.toString();
    }

    // List allUsers = usersList.split(', ');
    // print("11111111111111111111${allUsers}");

    final message = ScheduleMeeting(
      title: _titleController.text.toString(),
      hostId: selectedValue == 'Select Self as Host' ? widget.currentuseruid : selectedValue,
      meetingId: meetingController.text.toString(),
      meetingPassword: passwordController.text.toString(),
      startTime: _selectedDateTime.toString(),
      hostName: hostName,
      duration: int.parse(durationController.text.toString()),
      usersList:idOnly.toString(),
      createdById: widget.currentuseruid,
      isWebinar: false,
    );
    // print("22222222222222222222222$hostId");
    var mId = DateTime.now().millisecondsSinceEpoch.toString();
    // var selfuserData =
    // await firestore.collection('users').doc(auth.currentUser?.uid).get();



    await FirebaseFirestore.instance
        .collection(DbPaths.collectionusers)
        .doc(widget.currentuseruid)
        .collection('scheduleMeeting')
        .doc(mId)
        .set(
      message.toMap(),
    );
    idOnly.forEach((element) async  {
      if(element != widget.currentuseruid) {
        var mId = DateTime.now().millisecondsSinceEpoch.toString();
        // var selfuserData =
        // await firestore.collection('users').doc(auth.currentUser?.uid).get();


        await FirebaseFirestore.instance
            .collection(DbPaths.collectionusers)
            .doc(element)
            .collection('scheduleMeeting')
            .doc(mId)
            .set(
          message.toMap(),
        );
      }
    });

  }
  final rng = Random();
  random() {
    var randomNumber = rng.nextInt(100000000).toString();
    print("random number: $randomNumber");
    meetingController = TextEditingController(text: randomNumber.toString());
  }

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(rng.nextInt(_chars.length))));

  password() {
    final password = getRandomString(6);
    passwordController.text = password;
    print("password : $password");
  }
  List<LocalUserData> localUsersLIST = [];
  String localUsersSTRING = "";
getUserList()
{
  localUsersSTRING = widget.prefs.getString('localUsersSTRING') ?? "";
  if (localUsersSTRING != "") {
    localUsersLIST = LocalUserData.decode(localUsersSTRING);
    localUsersLIST
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
 setState(() {

 });


  }
}
  List selectedUser = [];
  final List<String> dropdownItems = ['Option 1', 'Option 2', 'Option 3'];
  final TextEditingController _textEditingController = TextEditingController();
  String? selectedValue;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Thm.isDarktheme(widget.prefs)
          ? corncallCONTAINERboxColorDarkMode
          : Colors.white,
      appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon( Icons.arrow_back_ios,size: 20,),
          ),
          elevation: 0,
          backgroundColor: Thm.isDarktheme(widget.prefs)
              ? corncallAPPBARcolorDarkMode
              : corncallAPPBARcolorLightMode,
          title: Text( getTranslated(
              context, 'Createmeeting'),)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration:  InputDecoration(
                  labelText: getTranslated(
                      context, 'MeetingTitle'),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return getTranslated(
                        context, 'Pleaseenteratitle');
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                controller: durationController,
                decoration:  InputDecoration(
                  labelText: getTranslated(
                      context, 'Duration'),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return getTranslated(
                        context, 'Pleaseenteratimelimit');
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                controller: meetingController,
                decoration:  InputDecoration(
                  labelText: getTranslated(
                      context, 'Id'),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return getTranslated(
                        context, 'Pleaseenteraid');
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                controller: passwordController,
                decoration:  InputDecoration(
                  labelText: getTranslated(
                      context, 'Password'),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return getTranslated(
                        context,'validPassword');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                height: 60,
                child: InputDecorator(
                  decoration:  InputDecoration(
                    labelText: getTranslated(
                        context,'Selectanoption'),
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      // isExpanded: true,
                      value: selectedValue,
                      onChanged: (newValue) {
                        setState(() {
                          selectedValue = newValue!;
                          _textEditingController.text = newValue;
                        });
                      },
                      items: localUsersLIST.map((val) {
                        return DropdownMenuItem<String>(
                          value: val.id,
                          child: Text(val.name),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                  height: 62,
                  child: FormField(
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return getTranslated(context,'Pleaseselecthost');
                        }
                        return null;
                      },
                      autovalidateMode:
                      AutovalidateMode.onUserInteraction,
                      initialValue: "_selectedUsers",
                      builder: (field) {
                        var list = localUsersLIST.map((val) {
                          return {
                            'id': val.id,
                            'label': val.name
                          };
                        }).toList();
                        return InputDecorator(
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(5.0),
                                  borderSide: const BorderSide(
                                      color: Colors.grey, width: 2.0)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(5.0),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1.0)),
                              errorBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(5.0),
                                  borderSide: BorderSide(
                                      color: Colors.red.shade700,
                                      width: 1.0)),
                              focusedErrorBorder: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.circular(5.0),
                                  borderSide: BorderSide(
                                      color: Colors.red.shade900,
                                      width: 2.0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: MultiSelectDropdown(
                                list: list,
                                initiallySelected: const [],
                                includeSearch: true,
                                includeSelectAll: true,
                                isLarge: true,
                                boxDecoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(15),
                                ),
                                onChange: (newList) {
                                  print(newList);
                                  selectedUser = newList;
                                },
                                numberOfItemsLabelToShow: 2,
                                whenEmpty: getTranslated(context,'Selectusers'),
                              ),
                            ));
                      })),
              const SizedBox(height: 16.0),
              ElevatedButton(

                onPressed: () async {
                  final selectedDateTime = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );

                  if (selectedDateTime != null) {
                    final selectedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );

                    if (selectedTime != null) {
                      setState(() {
                        _selectedDateTime = DateTime(
                          selectedDateTime.year,
                          selectedDateTime.month,
                          selectedDateTime.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                      });
                    }
                  }
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Thm.isDarktheme(widget.prefs)
                          ? corncallAPPBARcolorDarkMode
                          : corncallAPPBARcolorLightMode,),
                ),
                child:  Text(
                  getTranslated(context,'SelectDateandTime'),

                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                _selectedDateTime != null
                    ? getTranslated(context,'SelectedDateandTime')+" : ${DateFormat('dd-MM-yyyy hh:mm a').format(_selectedDateTime!)}"
                    : getTranslated(context,'NoDateandTimeSelected'),
                style:  TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _selectedDateTime != null) {
                    // Dispatch the form submitted event
                    _saveScheduleMeetings();
                    Navigator.pop(context);
                  }
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Thm.isDarktheme(widget.prefs)
                          ? corncallAPPBARcolorDarkMode
                          : corncallAPPBARcolorLightMode,),
                ),
                child:  Text(
                  getTranslated(
                      context, 'ScheduleMeeting'),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
