import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/router.dart';
import 'core/utils/web_url_strategy.dart';
import 'data/local/hive_service.dart';
import 'features/interaction/timer_provider.dart';
import 'core/services/ci_service.dart';
import 'core/constants/supabase_config.dart';
import 'core/constants/dev_flags.dart';
import 'core/services/supabase_smoke_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) configureUrlStrategy();

  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
  );

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint(details.stack?.toString());
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint(stack.toString());
    return true;
  };

  runApp(const ProviderScope(child: _Bootstrap()));
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<void> _initFuture;
  String _phase = '准备启动…';

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    void setPhase(String value) {
      if (!mounted) return;
      setState(() => _phase = value);
    }

    setPhase('加载本地化…');
    await initializeDateFormatting(
      'zh_CN',
      null,
    ).timeout(const Duration(seconds: 8));

    setPhase('初始化本地存储…');
    await HiveService.init().timeout(const Duration(seconds: 12));

    if (kEnableSupabaseSmokeTest) {
      setPhase('Supabase 写入自检…');
      await SupabaseSmokeTest.run().timeout(const Duration(seconds: 12));
    }

    setPhase('应用规则…');
    CIService.checkNaturalRecovery();

    setPhase('渲染界面…');
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _StartupLoadingApp(phase: _phase);
        }
        final error = snapshot.error;
        if (error != null) {
          return _StartupErrorApp(error: error, stack: snapshot.stackTrace);
        }
        return const ClarityApp();
      },
    );
  }
}

class ClarityApp extends ConsumerWidget {
  const ClarityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(interactionTimerNotifierProvider);
    return MaterialApp.router(
      title: '恋爱账单',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (timerState.status == TimerStatus.warning)
              const _GlobalWarningOverlay(),
          ],
        );
      },
    );
  }
}

class _StartupLoadingApp extends StatelessWidget {
  const _StartupLoadingApp({required this.phase});

  final String phase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: Text(
                    'CLARITY',
                    style: GoogleFonts.robotoMono(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: const Color(0xFFE6E6E6).withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '恋爱账单',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE6E6E6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CLARITY',
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: const Color(
                            0xFFE6E6E6,
                          ).withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        phase,
                        style: const TextStyle(
                          color: Color(0xFFE6E6E6),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error, required this.stack});

  final Object error;
  final StackTrace? stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Color(0xFFE6E6E6),
                  fontSize: 14,
                  height: 1.4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '启动失败',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('通常是本地存储初始化失败导致（例如 Web IndexedDB 被阻塞）。'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151922),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A3140)),
                      ),
                      child: Text(
                        stack == null ? '$error' : '$error\n\n$stack',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFFB7C0D6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlobalWarningOverlay extends StatefulWidget {
  const _GlobalWarningOverlay();

  @override
  State<_GlobalWarningOverlay> createState() => _GlobalWarningOverlayState();
}

class _GlobalWarningOverlayState extends State<_GlobalWarningOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, _) {
          return Container(
            color: const Color(
              0xFFFF3B30,
            ).withAlpha((40 + _opacity.value * 70).toInt()),
          );
        },
      ),
    );
  }
}
