import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'providers/activity_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/master_data_provider.dart';
import 'providers/prospect_provider.dart';
import 'providers/report_provider.dart';
import 'providers/spk_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => MasterDataProvider(apiService: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProspectProvider(apiService: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => SpkProvider(apiService: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportProvider(apiService: _apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ActivityProvider(apiService: _apiService),
        ),
      ],
      child: MaterialApp(
        title: 'MMSD',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) {
          if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();
          return _WebMobileFrame(child: child);
        },
        home: const SplashScreen(),
      ),
    );
  }
}

class _WebMobileFrame extends StatelessWidget {
  const _WebMobileFrame({required this.child});

  final Widget child;

  static const double _maxWidth = 430;
  static const double _maxHeight = 932;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.navyDeep,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > _maxWidth
                ? _maxWidth
                : constraints.maxWidth;
            final height = constraints.maxHeight > _maxHeight
                ? _maxHeight
                : constraints.maxHeight;
            final framed =
                constraints.maxWidth > _maxWidth ||
                constraints.maxHeight > _maxHeight;
            final media = MediaQuery.of(context).copyWith(
              size: Size(width, height),
            );
            return SizedBox(
              width: width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: framed
                      ? const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 32,
                            offset: Offset(0, 12),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(framed ? 28 : 0),
                  child: MediaQuery(data: media, child: child),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
