import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:station_msloyalty/AppConfig.dart';
import 'package:station_msloyalty/SplashScreen.dart';
import 'package:station_msloyalty/ThemeProvider.dart';
import 'package:station_msloyalty/Constants/StyleConstants.dart';
import 'package:station_msloyalty/config.dart' as Config;
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadConfig();
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );

  print("Supabase Initialized Successfully!");
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final botToastBuilder = BotToastInit();
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'POS Loyalty System',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        child = botToastBuilder(context, child);
        return child;
      },
      themeMode: themeProvider.themeMode,
      theme: StyleConstants.getLightTheme(),
      darkTheme: StyleConstants.getDarkTheme(),
      home: SplashScreen(),
    );
  }
}
