import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/app/user_app.dart';


// Change here to use local machine server
// const String _env = 'local';
const String _env = 'dev';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.$_env');
  runApp(const ProviderScope(child: UserApp()));
}
