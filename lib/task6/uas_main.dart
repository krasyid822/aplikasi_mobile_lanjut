import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import 'logic/providers/chat_provider.dart';
import 'logic/services/gemma_service.dart';
import 'ui/screens/chat_session_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final gemmaService = GemmaService();
  await gemmaService.initialize();

  runApp(const UasApp());
}

class UasApp extends StatelessWidget {
  const UasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: FutureBuilder(
        future: GemmaService().initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const AdaptiveMaterialApp(
              title: 'UAS Gemma AI',
              home: UasPage(),
            );
          }
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Menyiapkan Mesin AI..."),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
