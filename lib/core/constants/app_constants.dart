class AppConstants {
  AppConstants._();

  static const String baseUrlProd = 'https://omkarsutar.github.io/';
  static const String baseUrlLocal = 'http://localhost:3000/';
  static const String appPath = 'OrderAppOperationsV01';

  /* static const String baseUrlProd = 'https://orderzapp.github.io/';
  static const String baseUrlLocal = 'http://localhost:3000/';
  static const String appPath = 'OrderZAppV01/'; */

  static const String webAppProdUrl = '$baseUrlProd$appPath/';
  static const String webAppLocalUrl = '$baseUrlLocal$appPath/';
  static const String webAppHashUrl = '$baseUrlProd$appPath/#';

  static const String baseUrlProdRetailerApp = 'https://orderzapp.github.io/';
  static const String appPathRetailerApp = 'OrderZAppV01';

  static const String webAppUrlRetailerApp =
      '$baseUrlProdRetailerApp$appPathRetailerApp';

  static const String webAppHashUrlRetailerApp =
      '$baseUrlProdRetailerApp$appPathRetailerApp/#';
}
