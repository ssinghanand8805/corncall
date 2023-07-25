import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:corncall/Configs/Dbkeys.dart';
import 'package:corncall/Configs/Dbpaths.dart';
import 'package:corncall/Models/DataModel.dart';
import 'package:corncall/Services/localization/language_constants.dart';
import 'package:corncall/Utils/open_settings.dart';
import 'package:corncall/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUserData {
  final lastUpdated, userType;
  final Int8List? photoBytes;
  final String id, name, photoURL, aboutUser;
  final List<dynamic> idVariants;

  LocalUserData({
    required this.id,
    required this.idVariants,
    required this.userType,
    required this.aboutUser,
    required this.lastUpdated,
    required this.name,
    required this.photoURL,
    this.photoBytes,
  });

  factory LocalUserData.fromJson(Map<String, dynamic> jsonData) {
    return LocalUserData(
      id: jsonData['id'],
      aboutUser: jsonData['about'],
      idVariants: jsonData['idVars'],
      name: jsonData['name'],
      photoURL: jsonData['url'],
      photoBytes: jsonData['bytes'],
      userType: jsonData['type'],
      lastUpdated: jsonData['time'],
    );
  }

  Map<String, dynamic> toMapp(LocalUserData user) {
    return {
      'id': user.id,
      'about': user.aboutUser,
      'idVars': user.idVariants,
      'name': user.name,
      'url': user.photoURL,
      'bytes': user.photoBytes,
      'type': user.userType,
      'time': user.lastUpdated,
    };
  }

  static Map<String, dynamic> toMap(LocalUserData user) => {
        'id': user.id,
        'about': user.aboutUser,
        'idVars': user.idVariants,
        'name': user.name,
        'url': user.photoURL,
        'bytes': user.photoBytes,
        'type': user.userType,
        'time': user.lastUpdated,
      };

  static String encode(List<LocalUserData> users) => json.encode(
        users
            .map<Map<String, dynamic>>((user) => LocalUserData.toMap(user))
            .toList(),
      );

  static List<LocalUserData> decode(String users) =>
      (json.decode(users) as List<dynamic>)
          .map<LocalUserData>((item) => LocalUserData.fromJson(item))
          .toList();
}

class SmartContactProviderWithLocalStoreData with ChangeNotifier {
  //********---LOCAL STORE USER DATA PREVIUSLY FETCHED IN PREFS::::::::-----
  int daysToUpdateCache = 7;
  var usersDocsRefinServer =
      FirebaseFirestore.instance.collection(DbPaths.collectionusers);
  List<LocalUserData> localUsersLIST = [];
  String localUsersSTRING = "";
 List adminList = [
  {"name": "Anand", "number":"+919305647493"},
  {"name": "Israr Sir", "number": "+918840888300"},
  {"name": "Testtt", "number": "2345678910"},
  {"name": "Aman Home", "number": "+918115389357"},
  {"name": "Aman Home", "number": "+916390319914"},
  ];

  List serverList = <DeviceContactIdAndName>[];
  List<DeviceContactIdAndName> get getServerList => List<DeviceContactIdAndName>.from(serverList.map((e) => DeviceContactIdAndName.fromJson(e)));
  List finalAddedList2 = [];
 newListAsComparedWith(){
   List serverPhoneList = alreadyJoinedSavedUsersPhoneNameAsInServer.map((e) => e.phone.toString().trim()).toList();
   List contactList = contactsBookContactList!.entries.map((e) => e.key.toString().trim()).toList();
   print("server list $serverPhoneList");
   print("contact list $contactList");
  adminList.forEach((element1){
    DeviceContactIdAndName devObj = DeviceContactIdAndName(phone: element1['number'],name: element1['name']);
    serverPhoneList.forEach((element2) {
      if(element2.toString().trim() == element1['number'].toString().trim()){
        print("contains element0000 $element2");
        print("DEV PHONE NUMBER ${devObj.phone}");
        if(serverList.map((e) => e.phone).toList().contains(devObj.phone) == false){
          serverList.add(devObj);
          //notifyListeners();
        }
      }
    });
    contactList.forEach((element3) {
      if(element3.toString().trim() == element1['number'].toString().trim()){
        print("contains element111 $element3");
        if(finalAddedList2.contains(element1) == false){
          finalAddedList2.add(element1);
         // notifyListeners();
        }

      }
    });
  });
  print("final list 112 $serverList");
  print("final list $finalAddedList2");
 }


  addORUpdateLocalUserDataMANUALLY(
      {required SharedPreferences prefs,
      required LocalUserData localUserData,
      required bool isNotifyListener}) {
    int ind =
        localUsersLIST.indexWhere((element) => element.id == localUserData.id);
    if (ind >= 0) {
      if (localUsersLIST[ind].name.toString() !=
              localUserData.name.toString() ||
          localUsersLIST[ind].photoURL.toString() !=
              localUserData.photoURL.toString()) {
        localUsersLIST.removeAt(ind);
        localUsersLIST.insert(ind, localUserData);
        localUsersLIST.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (isNotifyListener == true) {
          notifyListeners();
        }
        saveFetchedLocalUsersInPrefs(prefs);
      }
    } else {
      localUsersLIST.add(localUserData);
      localUsersLIST
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (isNotifyListener == true) {
        notifyListeners();
      }
      saveFetchedLocalUsersInPrefs(prefs);
    }
  }

  Future<LocalUserData?> fetchUserDataFromnLocalOrServer(
      SharedPreferences prefs, String userid) async {
    int ind = localUsersLIST.indexWhere((element) => element.id == userid);
    if (ind >= 0) {
      // print("LOADED ${localUsersLIST[ind].id} LOCALLY ");
      LocalUserData localUser = localUsersLIST[ind];
      if (DateTime.now()
              .difference(
                  DateTime.fromMillisecondsSinceEpoch(localUser.lastUpdated))
              .inDays >
          daysToUpdateCache) {
        DocumentSnapshot<Map<String, dynamic>> doc =
            await usersDocsRefinServer.doc(localUser.id).get();
        if (doc.exists) {
          var updatedUserData = LocalUserData(
              aboutUser: doc.data()![Dbkeys.aboutMe] ?? "",
              idVariants: doc.data()![Dbkeys.phonenumbervariants] ?? [userid],
              id: localUser.id,
              userType: 0,
              lastUpdated: DateTime.now().millisecondsSinceEpoch,
              name: doc.data()![Dbkeys.nickname],
              photoURL: doc.data()![Dbkeys.photoUrl] ?? "");
          // print("UPDATED ${localUser.id} LOCALLY AFTER EXPIRED");
          addORUpdateLocalUserDataMANUALLY(
              prefs: prefs,
              isNotifyListener: false,
              localUserData: updatedUserData);
          return Future.value(updatedUserData);
        } else {
          return Future.value(localUser);
        }
      } else {
        return Future.value(localUser);
      }
    } else {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await usersDocsRefinServer.doc(userid).get();
      if (doc.exists) {
        // print("LOADED ${doc.data()![Dbkeys.phone]} SERVER ");
        var updatedUserData = LocalUserData(
            aboutUser: doc.data()![Dbkeys.aboutMe] ?? "",
            idVariants: doc.data()![Dbkeys.phonenumbervariants] ?? [userid],
            id: doc.data()![Dbkeys.phone],
            userType: 0,
            lastUpdated: DateTime.now().millisecondsSinceEpoch,
            name: doc.data()![Dbkeys.nickname],
            photoURL: doc.data()![Dbkeys.photoUrl] ?? "");

        addORUpdateLocalUserDataMANUALLY(
            prefs: prefs,
            isNotifyListener: false,
            localUserData: updatedUserData);
        return Future.value(updatedUserData);
      } else {
        return Future.value(null);
      }
    }
  }

  fetchFromFiretsoreAndReturnData(SharedPreferences prefs, String userid,
      Function(DocumentSnapshot<Map<String, dynamic>> doc) onReturnData) async {
    var doc = await usersDocsRefinServer.doc(userid).get();
    if (doc.exists && doc.data() != null) {
      onReturnData(doc);
      addORUpdateLocalUserDataMANUALLY(
          isNotifyListener: true,
          prefs: prefs,
          localUserData: LocalUserData(
              id: userid,
              idVariants: doc.data()![Dbkeys.phonenumbervariants],
              userType: 0,
              aboutUser: doc.data()![Dbkeys.aboutMe],
              lastUpdated: DateTime.now().millisecondsSinceEpoch,
              name: doc.data()![Dbkeys.nickname],
              photoURL: doc.data()![Dbkeys.photoUrl] ?? ""));
    }
  }

  Future<bool?> fetchLocalUsersFromPrefs(SharedPreferences prefs) async {
    localUsersSTRING = prefs.getString('localUsersSTRING') ?? "";
    if (localUsersSTRING != "") {
      localUsersLIST = LocalUserData.decode(localUsersSTRING);
      localUsersLIST
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      notifyListeners();

      return true;
    } else {
      return true;
    }

  }

  saveFetchedLocalUsersInPrefs(SharedPreferences prefs) async {
    if (searchingcontactsindatabase == false) {
      localUsersSTRING = LocalUserData.encode(localUsersLIST);
      await prefs.setString('localUsersSTRING', localUsersSTRING);

      // print("SAVED ${localUsersLIST.length} LOCAL USERS - at end");
    }
  }

  //********---DEVICE CONTACT FETCH STARTS BELOW::::::::-----

  List<DeviceContactIdAndName> previouslyFetchedKEYPhoneInSharedPrefs = [];
  List<DeviceContactIdAndName> alreadyJoinedSavedUsersPhoneNameAsInServer = [];

//-------
  Map<String?, String?>? contactsBookContactList = new Map<String, String>();

  bool searchingcontactsindatabase = true;
  List<dynamic> currentUserPhoneNumberVariants = [];

  fetchContacts(BuildContext context, DataModel? model, String currentuserphone,
      SharedPreferences prefs,
      {List<dynamic>? currentuserphoneNumberVariants}) async {
    if (currentuserphoneNumberVariants != null) {
      currentUserPhoneNumberVariants = currentuserphoneNumberVariants;
    }
    await getContacts(context, model, prefs).then((value) async {
      final List<DeviceContactIdAndName> decodedPhoneStrings =
          prefs.getString('availablePhoneString') == null ||
                  prefs.getString('availablePhoneString') == ''
              ? []
              : DeviceContactIdAndName.decode(
                  prefs.getString('availablePhoneString')!);
      final List<DeviceContactIdAndName> decodedPhoneAndNameStrings =
          prefs.getString('availablePhoneAndNameString') == null ||
                  prefs.getString('availablePhoneAndNameString') == ''
              ? []
              : DeviceContactIdAndName.decode(
                  prefs.getString('availablePhoneAndNameString')!);
      previouslyFetchedKEYPhoneInSharedPrefs = decodedPhoneStrings;
      alreadyJoinedSavedUsersPhoneNameAsInServer = decodedPhoneAndNameStrings;

      var a = alreadyJoinedSavedUsersPhoneNameAsInServer;
      var b = previouslyFetchedKEYPhoneInSharedPrefs;

      alreadyJoinedSavedUsersPhoneNameAsInServer = a;
      previouslyFetchedKEYPhoneInSharedPrefs = b;

      await fetchLocalUsersFromPrefs(prefs).then((b) async {
        if (b == true) {
          await searchAvailableContactsInDb(
            context,
            currentuserphone,
            prefs,
          );
        }
      });
      // await finishLoadingTasks(context, prefs, currentuserphone, "",
      //     isrealyfinish: false);
    });
  }

  setIsLoading(bool val) {
    searchingcontactsindatabase = val;
    notifyListeners();
  }

  Future<Map<String?, String?>> getContacts(
      BuildContext context, DataModel? model, SharedPreferences prefs,
      {bool refresh = false}) async {
    Completer<Map<String?, String?>> completer =
        new Completer<Map<String?, String?>>();

    LocalStorage storage = LocalStorage(Dbkeys.cachedContacts);

    Map<String?, String?> _cachedContacts = {};

    completer.future.then((c) {
      c.removeWhere((key, val) => _isHidden(key, model));

      this.contactsBookContactList = c;
    });

    Corncall.checkAndRequestPermission(Permission.contacts).then((res) {
      if (res) {
        storage.ready.then((ready) async {
          if (ready) {
            String? getNormalizedNumber(String? number) {
              if (number == null) return null;
              return number.replaceAll(new RegExp('[^0-9+]'), '');
            }

            ContactsService.getContacts(withThumbnails: false)
                .then((Iterable<Contact> contacts) async {
              contacts.where((c) => c.phones!.isNotEmpty).forEach((Contact p) {
                if (p.displayName != null && p.phones!.isNotEmpty) {
                  List<String?> numbers = p.phones!
                      .map((number) {
                        String? _phone = getNormalizedNumber(number.value);

                        return _phone;
                      })
                      .toList()
                      .where((s) => s != null)
                      .toList();

                  numbers.forEach((number) {
                    _cachedContacts[number] = p.displayName;
                  });
                }
              });

              completer.complete(_cachedContacts);
            });
          }
          // }
        });
      } else {
        Corncall.showRationale(getTranslated(context, 'perm_contact'));
        Navigator.pushReplacement(
            context,
            new MaterialPageRoute(
                builder: (context) => OpenSettings(
                      permtype: 'contact',
                      prefs: prefs,
                    )));
      }
    }).catchError((onError) {
      Corncall.showRationale('Error occured: $onError');
    });
    notifyListeners();
    return completer.future;
  }

  String? getNormalizedNumber(String number) {
    if (number.isEmpty) {
      return null;
    }

    return number.replaceAll(new RegExp('[^0-9+]'), '');
  }

  _isHidden(String? phoneNo, DataModel? model) {
    return false;
  }

  searchAvailableContactsInDb(
    BuildContext context,
    String currentuserphone,
    SharedPreferences existingPrefs,
  ) async {
    if (existingPrefs.getString('lastTimeCheckedContactBookSavedCopy') ==
        contactsBookContactList.toString()) {
      searchingcontactsindatabase = false;
      if (previouslyFetchedKEYPhoneInSharedPrefs.length == 0 ||
          alreadyJoinedSavedUsersPhoneNameAsInServer.length == 0) {
        final List<DeviceContactIdAndName> decodedPhoneStrings =
            existingPrefs.getString('availablePhoneString') == null ||
                    existingPrefs.getString('availablePhoneString') == ''
                ? []
                : DeviceContactIdAndName.decode(
                    existingPrefs.getString('availablePhoneString')!);
        final List<DeviceContactIdAndName> decodedPhoneAndNameStrings =
            existingPrefs.getString('availablePhoneAndNameString') == null ||
                    existingPrefs.getString('availablePhoneAndNameString') == ''
                ? []
                : DeviceContactIdAndName.decode(
                    existingPrefs.getString('availablePhoneAndNameString')!);
        previouslyFetchedKEYPhoneInSharedPrefs = decodedPhoneStrings;
        alreadyJoinedSavedUsersPhoneNameAsInServer = decodedPhoneAndNameStrings;
      }
print('##############${alreadyJoinedSavedUsersPhoneNameAsInServer.toString()}');
      notifyListeners();

      // print(
      //     '11. SKIPPED SEARCHING - AS ${contactsBookContactList!.entries.length} CONTACTS ALREADY CHECKED IN DATABASE, ${alreadyJoinedSavedUsersPhoneNameAsInServer.length} EXISTS');
    } else {
      // print(
      //     '22. STARTED SEARCHING : ${contactsBookContactList!.entries.length} CONTACTS  IN DATABASE');

      contactsBookContactList!.forEach((key, value) async {
        if ((previouslyFetchedKEYPhoneInSharedPrefs
                    .indexWhere((element) => element.phone == key) <
                0) &&
            (!currentUserPhoneNumberVariants.contains(key)) &&
            localUsersLIST
                    .indexWhere((element) => element.idVariants.contains(key)) <
                0) {
          // if (!availableContactslastTime.contains(key)) {
          await FirebaseFirestore.instance
              .collection(DbPaths.collectionusers)
              .where(Dbkeys.phonenumbervariants, arrayContains: key)
              .get()
              .then((docs) async {
            if (docs.docs.length > 0) {
              // print('23. FOUND a USER in DATABASE after searching:  $key');

              if (docs.docs[0].data().containsKey(Dbkeys.joinedOn)) {
                if (alreadyJoinedSavedUsersPhoneNameAsInServer.indexWhere(
                            (element) =>
                                element.phone == docs.docs[0][Dbkeys.phone]) <
                        0 &&
                    docs.docs[0][Dbkeys.phone] != currentuserphone) {
                  docs.docs[0]
                      .data()[Dbkeys.phonenumbervariants]
                      .toList()
                      .forEach((phone) async {
                    previouslyFetchedKEYPhoneInSharedPrefs
                        .add(DeviceContactIdAndName(phone: phone ?? ''));
                  });
                  alreadyJoinedSavedUsersPhoneNameAsInServer.add(
                      DeviceContactIdAndName(
                          phone: docs.docs[0].data()[Dbkeys.phone] ?? '',
                          name: value ?? docs.docs[0].data()[Dbkeys.phone]));
                  // print('INSERTED $key IN LOCAL USER DATA LIST');
                  addORUpdateLocalUserDataMANUALLY(
                      prefs: existingPrefs,
                      localUserData: LocalUserData(
                          aboutUser: docs.docs[0].data()[Dbkeys.aboutMe] ?? "",
                          id: docs.docs[0].data()[Dbkeys.phone],
                          idVariants:
                              docs.docs[0].data()[Dbkeys.phonenumbervariants],
                          userType: 0,
                          lastUpdated: DateTime.now().millisecondsSinceEpoch,
                          name: docs.docs[0].data()[Dbkeys.nickname],
                          photoURL: docs.docs[0].data()[Dbkeys.photoUrl] ?? ""),
                      isNotifyListener: true);

                  int i = alreadyJoinedSavedUsersPhoneNameAsInServer.indexWhere(
                      (element) => element.phone == currentuserphone);
                  if (i >= 0) {
                    alreadyJoinedSavedUsersPhoneNameAsInServer..removeAt(i);
                    previouslyFetchedKEYPhoneInSharedPrefs.removeAt(i);
                  }
                }

                if (key == contactsBookContactList!.entries.last.key) {
                  finishLoadingTasks(context, existingPrefs, currentuserphone,
                      "24. SEARCHING STOPPED as users search completed in database.");
                } else {
                  if (alreadyJoinedSavedUsersPhoneNameAsInServer.length == 11) {
                    searchingcontactsindatabase = false;
                    notifyListeners();

                    // print(
                    //     '25. Now it will search in background , ${alreadyJoinedSavedUsersPhoneNameAsInServer.length} CONTACTS searched and found');
                  }
                }
              } else {
                if (key == contactsBookContactList!.entries.last.key) {
                  finishLoadingTasks(context, existingPrefs, currentuserphone,
                      '96. SEARCH COMPLETED , ${alreadyJoinedSavedUsersPhoneNameAsInServer.length}CONTACTS EXISTS IN DATABASE');
                }
              }
            } else {
              if (key == contactsBookContactList!.entries.last.key) {
                finishLoadingTasks(context, existingPrefs, currentuserphone,
                    '97. SEARCH COMPLETED - NO NEED TO SEARCH _ LAST KEY COMPLETED  , ${alreadyJoinedSavedUsersPhoneNameAsInServer.length} CONTACTS EXISTS IN DATABASE');
              } else if (contactsBookContactList!.length == 0) {
                searchingcontactsindatabase = false;
                Corncall.toast('Contact Book Empty');
                notifyListeners();
                // sortListBasedonStar(existingPrefs);
              }
            }
          });

        } else {
          // print('NO NEED TO SEARCH $key, ALREADY SEARCHED & EXISTS');
          if (key == contactsBookContactList!.entries.last.key) {
            finishLoadingTasks(context, existingPrefs, currentuserphone,
                '99.. SEARCH COMPLETED - NO NEED TO SEARCH _ LAST KEY COMPLETED  , ${alreadyJoinedSavedUsersPhoneNameAsInServer.length} CONTACTS EXISTS IN DATABASE');
          }
        }
      });
    }
  }

  finishLoadingTasks(BuildContext context, SharedPreferences existingPrefs,
      String currentuserphone, String printStatement,
      {bool isrealyfinish = true}) async {
    if (isrealyfinish == true) {
      searchingcontactsindatabase = false;
    }

    final String encodedavailablePhoneString =
        DeviceContactIdAndName.encode(previouslyFetchedKEYPhoneInSharedPrefs);
    await existingPrefs.setString(
        'availablePhoneString', encodedavailablePhoneString);

    final String encodedalreadyJoinedSavedUsersPhoneNameAsInServer =
        DeviceContactIdAndName.encode(
            alreadyJoinedSavedUsersPhoneNameAsInServer);
    await existingPrefs.setString('availablePhoneAndNameString',
        encodedalreadyJoinedSavedUsersPhoneNameAsInServer);

    if (isrealyfinish == true) {
      await existingPrefs.setString('lastTimeCheckedContactBookSavedCopy',
          contactsBookContactList.toString());
      // fetchLocalUsersFromPrefs(existingPrefs);
      notifyListeners();
    }
  }

  String getUserNameOrIdQuickly(String userid) {
    if (localUsersLIST.indexWhere((element) => element.id == userid) >= 0) {
      return localUsersLIST[
              localUsersLIST.indexWhere((element) => element.id == userid)]
          .name;
    } else {
      return 'User';
    }
  }
}

class DeviceContactIdAndName {
  final String phone;
  final String? name;

  DeviceContactIdAndName({
    required this.phone,
    this.name,
  });

  factory DeviceContactIdAndName.fromJson(Map<String, dynamic> jsonData) {
    return DeviceContactIdAndName(
      phone: jsonData['id'],
      name: jsonData['name'],
    );
  }

  static Map<String, dynamic> toMap(DeviceContactIdAndName contact) => {
        'id': contact.phone,
        'name': contact.name,
      };

  static String encode(List<DeviceContactIdAndName> contacts) => json.encode(
        contacts
            .map<Map<String, dynamic>>(
                (contact) => DeviceContactIdAndName.toMap(contact))
            .toList(),
      );

  static List<DeviceContactIdAndName> decode(String contacts) =>
      (json.decode(contacts) as List<dynamic>)
          .map<DeviceContactIdAndName>(
              (item) => DeviceContactIdAndName.fromJson(item))
          .toList();
}
