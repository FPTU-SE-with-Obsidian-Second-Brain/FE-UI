import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/note_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SecondBrainApp());
}

class SecondBrainApp extends StatelessWidget {
  const SecondBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NoteProvider()..init()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'FPTU SE Second Brain',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        builder: (context, child) {
          // Bọc ExcludeSemantics tại cấp độ builder cao nhất của MaterialApp
          // để loại bỏ hoàn toàn việc đồng bộ cây ngữ nghĩa cho Navigator, Overlay, Tooltip và Dialog trên Windows
          return ExcludeSemantics(
            child: child ?? const SizedBox.shrink(),
          );
        },
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF9333EA), // Tím phong cách Obsidian
            onPrimary: Colors.white,
            primaryContainer: Color(0xFF581C87),
            onPrimaryContainer: Color(0xFFF3E8FF),
            secondary: Color(0xFFA855F7),
            surface: Color(0xFF18181B), // Nền tối hiện đại
            surfaceContainerHighest: Color(0xFF27272A),
            onSurface: Color(0xFFF4F4F5),
          ),
          scaffoldBackgroundColor: const Color(0xFF09090B),
          dividerColor: const Color(0xFF27272A),
          cardColor: const Color(0xFF18181B),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF18181B),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
