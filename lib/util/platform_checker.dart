// platform_check.dart
import 'platform_checker_stub.dart'
    if (dart.library.html) 'platform_checker_web.dart'
    if (dart.library.io) 'platform_checker_mobile.dart';

class PlatformChecker {
  static bool get isMobile => checkIfMobile();
}
