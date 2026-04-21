import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void configureUrlStrategyImpl() {
  // Use hash strategy so IP:port static servers can refresh deep links safely.
  setUrlStrategy(const HashUrlStrategy());
}

