import 'package:flutter/material.dart';
import 'package:user_app/features/preview/preview_app.dart';

// Offline entry point: deliberately does not initialize auth, APIs or payments.
void main() => runApp(const PreviewApp());
