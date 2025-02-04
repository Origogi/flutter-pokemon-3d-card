import 'dart:io' show Platform;

bool checkIfMobile() {
  return Platform.isAndroid || Platform.isIOS;
}