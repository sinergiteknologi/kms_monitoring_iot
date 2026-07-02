import 'package:flutter/material.dart';
import 'package:kms_monitoring_iot/core/app_globals.dart';
import 'package:kms_monitoring_iot/core/web_mobile_shell.dart';
import 'package:kms_monitoring_iot/page/bottom_navigator_view.dart';
import 'package:kms_monitoring_iot/page/connect/connect_view.dart';
import 'package:kms_monitoring_iot/page/connect/connect_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([AppGlobals.loadTaskList(), AppGlobals.loadFinishList()]);

  final initialRoute = await _resolveInitialRoute();

  runApp(MyApp(initialRoute: initialRoute));
}

Future<String> _resolveInitialRoute() async {
  // Default aplikasi selalu masuk Connect jika tidak ada IP tersimpan
  // atau IP tersimpan tidak bisa dihubungi.
  String route = '/connect';

  if (AppGlobals.previewCardMode) {
    return '/home';
  }

  final savedIp = await ConnectViewModel.getSavedIp();

  if (savedIp == null || savedIp.trim().isEmpty) {
    AppGlobals.isConnected = false;
    return route;
  }

  final isReachable = await ConnectViewModel.verifyConnection(savedIp);
  debugPrint('Initial connection check: $savedIp => $isReachable');

  if (isReachable) {
    route = '/home';
  } else {
    AppGlobals.isConnected = false;
  }

  return route;
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppGlobals.globalNavigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return WebMobileShell(child: child);
      },
      routes: {
        '/connect': (context) => const ConnectView(),
        '/home': (context) => const BottomNavigatorView(),
      },
    );
  }
}
