//*************   © Copyrighted by Criterion Tech. *********************

import 'package:flutter/material.dart';

//*--App Colors : Replace with your own colours---
//-**********---------- WHATSAPP Color Theme: ----------****************---------------

// Unique Color for your App -----

final corncallPRIMARYcolor = Color(0xff826be3); // you may change this as per your theme. This applies to large buttons, tabs, text heading etc.
final corncallbluelightcolor = Color(0xff826be3); // you may change this as per your theme. This applies to large buttons, tabs, text heading etc.
final corncallbluehighlightcolor = Color(0xffA79ECF); // you may change this as per your theme. This applies to large buttons, tabs, text heading etc.
final corncallSECONDARYolor = Color(0xFF684BE2); // you may change this as per your theme. This applies to small buttons, icons & highlights
final corncallchatBoxColor = Color(0xff684BE2); // you may change this as per your theme. This applies to small buttons, icons & highlights

const SplashBackgroundSolidColor = Color(0xFF684BE2); // you may change this as per your theme. Applies this colors to fill the areas around splash screen.  Color Code: 0xFF00A980 for Whatsapp theme & 0xFFFFFFFF for messenger theme.
const IsSplashOnlySolidColor = false;

// light mode colors -----
final corncallAPPBARcolorLightMode =
    Color(0xff684BE2); // you may change this as per your theme
final corncallBACKGROUNDcolorLightMode = Color(0xfff4f5f6);
final corncallCONTAINERboxColorLightMode = Colors.white;
final corncallDIALOGColorLightMode = Colors.white;
final corncallCHATBACKGROUNDLightMode = new Color(0xffe8ded5);
// dark mode colors -----
final corncallAPPBARcolorDarkMode = Color(0xff1d2931);
final corncallBACKGROUNDcolorDarkMode = Color(0xff0c151c);
final corncallCONTAINERboxColorDarkMode = Color(0xff111920);
final corncallDIALOGColorDarkMode = Color(0xff202e35);
final corncallCHATBACKGROUNDDarkMode = new Color(0xff0e1116);
// other universal colors -----
final corncallWhite = Colors.white;
final corncallBlack = new Color(0xFF1E1E1E);
final corncallGrey = Color(0xff8596a0);
final corncallREDbuttonColor = new Color(0xFFEF4B5B);
final corncallCHATBUBBLEcolor = new Color(0xFFe9fedf);
final corncallOurchatcolor = new Color(0xFF684BE2);
final corncallOppositechatcolor = new Color(0xFFdadaf5);

//-*********---------- MESSENGER Color Theme:  ----****************---------- Remove below comments & add comment above color values for Messenger theme //------------



//*--Admob Configurations- (By default Test Ad Units pasted)----------
const IsBannerAdShow =
    false; // Set this to 'true' if you want to show Banner ads throughout the app
const Admob_BannerAdUnitID_Android =
    'ca-app-pub-3940256099942544/6300978111'; // Test Id: 'ca-app-pub-3940256099942544/6300978111'
const Admob_BannerAdUnitID_Ios =
    'ca-app-pub-3940256099942544/2934735716'; // Test Id: 'ca-app-pub-3940256099942544/2934735716'
const IsInterstitialAdShow =
    false; // Set this to 'true' if you want to show Interstitial ads throughout the app
const Admob_InterstitialAdUnitID_Android =
    'ca-app-pub-3940256099942544/1033173712'; // Test Id:  'ca-app-pub-3940256099942544/1033173712'
const Admob_InterstitialAdUnitID_Ios =
    'ca-app-pub-3940256099942544/4411468910'; // Test Id: 'ca-app-pub-3940256099942544/4411468910'
const IsVideoAdShow =
    false; // Set this to 'true' if you want to show Video ads throughout the app
const Admob_RewardedAdUnitID_Android =
    'ca-app-pub-3940256099942544/5224354917'; // Test Id: 'ca-app-pub-3940256099942544/5224354917'
const Admob_RewardedAdUnitID_Ios =
    'ca-app-pub-3940256099942544/1712485313'; // Test Id: 'ca-app-pub-3940256099942544/1712485313'

//*--Agora Configurations---
const Agora_APP_IDD =
    'b131a2bf0c9a48e4bf316fc36fe6e122'; // Grab it from: https://www.agora.io/en/
const dynamic Agora_TOKEN = null;
    //'007eJxTYEj5znlg9l+BCY1+Xaa13zsf71i0onPZtkXS8t83mbXbKfMrMCQZGhsmGiWlGSRbJppYpJokpRkbmqUlG5ulpZqlGhoZ3T3VlNIQyMig53eLlZEBAkF8FgZDI2MTBgYAuo4gFQ==';
    //null; // not required until you have planned to setup high level of authentication of users in Agora.

//*--Giphy Configurations---
const GiphyAPIKey =
    'COTGNiGXNRtFnZcTMokAp9xhzTgJcYnH'; // Grab it from: https://developers.giphy.com/

//*--App Configurations---
const Appname =
    'Corncall'; //app name shown evrywhere with the app where required
const DEFAULT_COUNTTRYCODE_ISO =
    'IN'; //default country ISO 2 letter for login screen
const DEFAULT_COUNTTRYCODE_NUMBER =
    '+91'; //default country code number for login screen
const FONTFAMILY_NAME =
    "Poppins"; // make sure you have registered the font in pubspec.yaml

const FONTFAMILY_NAME_ONLY_LOGO =
    null; // make sure you have registered the font in pubspec.yaml

//--WARNING----- PLEASE DONT EDIT THE BELOW LINES UNLESS YOU ARE A DEVELOPER -------
const SplashPath = 'assets/images/splash.png';
const AppLogoPathDarkModeLogo = 'assets/images/applogo_dark.png';
const AppLogoPathLightModeLogo = 'assets/images/applogo_dark.png';
