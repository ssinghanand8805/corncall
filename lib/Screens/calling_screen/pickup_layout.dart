//*************   © Copyrighted by Criterion Tech. *********************

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corncall/Screens/splash_screen/splash_screen.dart';
import 'package:corncall/Services/Providers/Observer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:corncall/Models/call.dart';
import 'package:corncall/Services/Providers/user_provider.dart';
import 'package:corncall/Models/call_methods.dart';
import 'package:corncall/Screens/calling_screen/pickup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PickupLayout extends StatelessWidget {
  final Widget scaffold;
  final SharedPreferences prefs;
  final CallMethods callMethods = CallMethods();

  PickupLayout({
    required this.scaffold,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    final Observer observer = Provider.of<Observer>(context);

    return observer.isOngoingCall == true
        ? scaffold
        : (userProvider.getUser != null)
            ? StreamBuilder<DocumentSnapshot>(
                stream:
                    callMethods.callStream(phone: userProvider.getUser!.phone),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.data() != null) {
                    Call call = Call.fromMap(
                        snapshot.data!.data() as Map<dynamic, dynamic>);

                    if (!call.hasDialled!) {
                      return PickupScreen(
                        prefs: prefs,
                        call: call,
                        currentuseruid: userProvider.getUser!.phone,
                      );
                    }
                  }
                  return scaffold;
                },
              )
            : Splashscreen();
  }
}
