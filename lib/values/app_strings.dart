class AppStrings {
  AppStrings._();

  static const String homeScreenHeading = "Home Screen";
}

class ErrorMessages {
  ErrorMessages._privateConstructor();

  // flutter error message
  static const String weRunIntoProblem =
      'We have run into some problem. Please try again after some moment.';

  static const String unauthorized = 'You are not authorized';
  static const String noInternet = 'Please check your internet connection';
  static const String connectionTimeout =
      'Connection timed out. Your internet connection might be slow';
  static const String networkGeneral =
      'Something went wrong.\nPlease try again later.';

  // Error State Widget
  static const String goBackRetryErrorStateWidget = 'Go back and try again';
  static const String goBackErrorStateWidget = 'Go back';
  static const String noInternetRetryErrorStateWidget =
      'Turn on your internet and try again!';

  static const String somethingWentWrong = 'Something went wrong!';
  static const String retryErrorStateWidget = 'Retry';

  // API Error Messages
  static const String error_503 = 'We are trying to fix it ASAP.';
  static const String error_404 = 'Page not found';
  static const String error_500 = 'Internal Server Error';
  static const String error_403 = 'You do not have access to this resource';
}
