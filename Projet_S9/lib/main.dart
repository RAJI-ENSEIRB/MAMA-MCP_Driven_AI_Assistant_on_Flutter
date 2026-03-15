import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_state.dart';
import 'mcp_server/mcp_server.dart';
import 'ui/profile/user_profile.dart';
import 'models/identity_profile.dart';
import 'models/habitat_profile.dart';
import 'models/family_profile.dart';
import 'models/health_profile.dart';
import 'models/profession_profile.dart';
import 'models/mobility_profile.dart';
import 'models/social_profile.dart';
import 'models/chat_message.dart';
import 'models/conversation.dart';
import 'auth/auth_state.dart';
import 'ui/auth/auth_gate.dart';
import 'onboarding/onboarding_flow.dart';
import 'ui/theme/theme_provider.dart';
import 'ui/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String colorFor(Level level) {
    if (level == Level.SEVERE) return "\x1B[31m"; // Rouge
    if (level == Level.WARNING) return "\x1B[33m"; // Jaune
    if (level == Level.INFO) return "\x1B[32m"; // Vert
    return "\x1B[0m"; // Défault
  }

  String formatTimestamp(DateTime t) {
    final dd = t.day.toString().padLeft(2, '0');
    final mm = t.month.toString().padLeft(2, '0');
    final yy = (t.year % 100).toString().padLeft(2, '0');

    final hh = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');

    return "$dd/$mm/$yy $hh:$min:$ss";
  }

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final color = colorFor(record.level);
    final text =
        "[${record.level.name}] "
        "${formatTimestamp(record.time)} "
        "${record.loggerName.padRight(10)} "
        "${record.message}";

    debugPrint("$color$text\x1B[0m");
  });

  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }
  await Hive.initFlutter();

  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(IdentityProfileAdapter());
  Hive.registerAdapter(HabitatProfileAdapter());
  Hive.registerAdapter(FamilyProfileAdapter());
  Hive.registerAdapter(HealthProfileAdapter());
  Hive.registerAdapter(ProfessionProfileAdapter());
  Hive.registerAdapter(MobilityProfileAdapter());
  Hive.registerAdapter(SocialProfileAdapter());
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(ConversationAdapter());

  await Hive.openBox<UserProfile>('user_profile');
  await Hive.openBox<IdentityProfile>('identity_box');
  await Hive.openBox<HabitatProfile>('habitat_box');
  await Hive.openBox<FamilyProfile>('family_box');
  await Hive.openBox<HealthProfile>('health_box');
  await Hive.openBox<ProfessionProfile>('profession_box');
  await Hive.openBox<MobilityProfile>('mobility_box');
  await Hive.openBox<SocialProfile>('social_box');
  await Hive.openBox<ChatMessage>('chat_messages');
  await Hive.openBox<Conversation>('conversations');

  //permet de reset pour tester l'onboarding, A ENLEVER APRES TEST
  //await Hive.box<IdentityProfile>('identity_box').clear();
  //await Hive.box<HabitatProfile>('habitat_box').clear();
  //await Hive.box<FamilyProfile>('family_box').clear();
  //await Hive.box<HealthProfile>('health_box').clear();
  //await Hive.box<ProfessionProfile>('profession_box').clear();
  //await Hive.box<MobilityProfile>('mobility_box').clear();
  //await Hive.box<SocialProfile>('social_box').clear();

  final mcpInstance = McpServerInstance();
  try {
    await mcpInstance.createMcpServer();
  } catch (e) {
    debugPrint('Failed to create MCP server: $e');
  }
  runApp(const MyApp());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyAppState()),
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => MamaThemeProvider()),
      ],
      child: Consumer<MamaThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MAMA',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
            routes: {'/auth': (context) => const AuthGate()},
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    final identityBox = Hive.box<IdentityProfile>('identity_box');
    final hasIdentity = identityBox.isNotEmpty;

    if (!hasIdentity) {
      return const OnboardingFlow();
    }

    return const AuthGate();
  }
}
