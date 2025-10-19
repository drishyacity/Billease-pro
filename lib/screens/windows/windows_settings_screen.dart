import 'package:flutter/material.dart';
import 'package:billease_pro/screens/settings/settings_screen.dart';

class WindowsSettingsScreen extends StatelessWidget {
  const WindowsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: SettingsScreen(),
    );
  }
}
