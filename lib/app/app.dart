import 'dart:async';

import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'app_scope.dart';
import 'app_theme.dart';
import 'app_shell.dart';

class ResonanceApp extends StatefulWidget {
  const ResonanceApp({required this.controller, super.key});

  final AppController controller;

  @override
  State<ResonanceApp> createState() => _ResonanceAppState();
}

class _ResonanceAppState extends State<ResonanceApp> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.initialize());
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
    controller: widget.controller,
    child: MaterialApp(
      title: 'Resonance Music',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const AppShell(),
    ),
  );
}
