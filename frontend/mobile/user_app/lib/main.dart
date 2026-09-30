import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/app/user_app.dart';
import 'package:user_app/features/preview/preview_app.dart';

// Change here to use local machine server
const String _env = String.fromEnvironment('ENV', defaultValue: 'local');
// const String _env = 'dev';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('TEST_MODE')) {
    runApp(const PreviewApp());
    return;
  }
  await dotenv.load(fileName: '.env.$_env');
  runApp(const ProviderScope(child: UserApp()));
}
