//*************   © Copyrighted by Criterion Tech. *********************

import 'package:corncall/Configs/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Splashscreen extends StatelessWidget {
  final bool? isShowOnlySpinner;

  Splashscreen({this.isShowOnlySpinner = false});
  @override
  Widget build(BuildContext context) {
    return IsSplashOnlySolidColor == true || this.isShowOnlySpinner == true
        ? Scaffold(
            backgroundColor: SplashBackgroundSolidColor,
            body: Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(corncallSECONDARYolor)),
            ))
        : SafeArea(
          child: Scaffold(
              backgroundColor: SplashBackgroundSolidColor,
              body: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Corncall",style: TextStyle(
                          letterSpacing: 2,
                          fontFamily: FONTFAMILY_NAME,
                          textBaseline: TextBaseline.ideographic,
                          color: corncallWhite,fontSize: 40,fontWeight: FontWeight.w800),),
                      Lottie.asset("assets/images/splashJson.json",width: 120,height: 120),
                    ],
                  ),
              //     Image.asset(
              //   '$SplashPath',
              //   width: double.infinity,
              //   fit: MediaQuery.of(context).size.height >
              //           MediaQuery.of(context).size.width
              //       ? BoxFit.cover
              //       : BoxFit.fitHeight,
              //   height: MediaQuery.of(context).size.height,
              // )
              ),
            ),
        );
  }
}
