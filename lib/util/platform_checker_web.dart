// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool checkIfMobile() {
  String userAgent = html.window.navigator.userAgent.toLowerCase();
  return userAgent.contains('mobile') ||
      userAgent.contains('android') ||
      userAgent.contains('iphone') ||
      userAgent.contains('ipad') ||
      userAgent.contains('ipod');
}
