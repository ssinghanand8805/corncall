//*************   © Copyrighted by Criterion Tech. *********************

// ignore: todo
//TODO:---- All localizations settings----

class Language {
  final int id;
  final String flag;
  final String name;
  final String languageCode;
  final String languageNameInEnglish;

  Language(this.id, this.flag, this.name, this.languageCode,
      this.languageNameInEnglish);

  static List<Language> languageList() {
    return <Language>[
      Language(1, "🇺🇸", "English", "en", "English"),
      Language(2, "🇮🇳", "Hindi", "hi", "Hindi"),
      Language(3, "🇵🇰", "Urdu", "ur", "Urdu"),
      Language(4, "🇸🇦", "Arabic", "ar", "Arabic"),
    ];
  }
}
