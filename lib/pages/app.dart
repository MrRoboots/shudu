import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:useful_tools/useful_tools.dart';
import 'package:flutter/services.dart';
import '../event/export.dart';
import '../provider/export.dart';
import 'home/home_page.dart';

class ShuduApp extends StatelessWidget {
  const ShuduApp({Key? key, required this.mode}) : super(key: key);
  final ThemeMode mode;
  @override
  Widget build(BuildContext context) {
    return Selector<OptionsNotifier, List>(
      selector: (context, opt) {
        return [
          opt.options.themeMode,
          opt.options.platform,
          opt.options.showPerformanceOverlay,
        ];
      },
      builder: (context, list, _) {
        final themeMode = list[0] ?? mode;
        return MaterialApp(
          themeMode: themeMode,
          title: 'shudu',
          theme: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Color.fromARGB(255, 15, 152, 231),
                secondary: Color.fromARGB(255, 179, 179, 179),
                onPrimary: Color.fromARGB(255, 245, 245, 245),
                onSurface: Color.fromARGB(255, 17, 30, 41),
              ),
              splashColor: Color.fromARGB(255, 212, 212, 212),
              scrollbarTheme: ScrollbarThemeData(radius: Radius.circular(6)),
              platform: list[1] ?? defaultTargetPlatform,
              pageTransitionsTheme: const PageTransitionsTheme(builders: {
                TargetPlatform.iOS: SlidePageTransition(),
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()
              }),
              appBarTheme:
                  AppBarTheme(systemOverlayStyle: getOverlayStyle(dark: true))),
          darkTheme: ThemeData.dark().copyWith(
            splashColor: Color.fromARGB(255, 212, 212, 212),
            scrollbarTheme: ScrollbarThemeData(radius: Radius.circular(6)),
            platform: list[1] ?? defaultTargetPlatform,
            colorScheme: const ColorScheme.dark(secondary: Colors.grey),
            pageTransitionsTheme: const PageTransitionsTheme(builders: {
              TargetPlatform.iOS: SlidePageTransition(),
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()
              }),
              appBarTheme:
                  AppBarTheme(systemOverlayStyle: getOverlayStyle(dark: true))
          ),
          showPerformanceOverlay: list[2] ?? false,
          home: Builder(builder: (context) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
                value:
                    getOverlayStyle(dark: context.isDarkMode, statusDark: true),
                child: const MyHomePage());
          }),
          navigatorObservers: [
            context.read<OptionsNotifier>().routeObserver,
            Nav.observer
          ],
        );
      },
    );
  }
}

class MulProvider extends StatelessWidget {
  const MulProvider({Key? key, required this.mode}) : super(key: key);

  final ThemeMode mode;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => Repository.create()..init()),
        ChangeNotifierProvider(
            create: (context) => OptionsNotifier(context.read())..init()),
        ChangeNotifierProvider(
          create: (context) => BookIndexNotifier(repository: context.read()),
        ),
        ChangeNotifierProvider(
            create: (context) => SearchNotifier(context.read())..init()),
        ChangeNotifierProvider(
            create: (context) =>
                ContentNotifier(repository: context.read())..initConfigs()),
        ChangeNotifierProvider(
          create: (context) => BookCacheNotifier(context.read())..load(),
        ),
        ChangeNotifierProvider(create: (_) => TextStyleConfig()),
      ],
      child: GetMaterialApp(home: ShuduApp(mode: mode)),
    );
  }
}
