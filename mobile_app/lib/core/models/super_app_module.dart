import 'package:flutter/material.dart';

class SuperAppModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final String screenKey;

  const SuperAppModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.screenKey,
  });
}
