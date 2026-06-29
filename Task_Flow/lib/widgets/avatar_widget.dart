import 'package:flutter/material.dart';
import '../core/theme.dart';

class PresetAvatarInfo {
  final String id;
  final String label;
  final List<Color> colors;
  final IconData icon;

  const PresetAvatarInfo({
    required this.id,
    required this.label,
    required this.colors,
    required this.icon,
  });
}

class AvatarWidget extends StatelessWidget {
  final String avatarString;
  final double radius;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    required this.avatarString,
    this.radius = 40,
    this.onTap,
  });

  static const List<PresetAvatarInfo> presets = [
    PresetAvatarInfo(
      id: 'avatar_developer',
      label: 'Developer',
      colors: [Color(0xFF6366F1), Color(0xFF3B82F6)], // Indigo to Blue
      icon: Icons.code_rounded,
    ),
    PresetAvatarInfo(
      id: 'avatar_designer',
      label: 'Designer',
      colors: [Color(0xFFEC4899), Color(0xFFF43F5E)], // Pink to Rose
      icon: Icons.brush_rounded,
    ),
    PresetAvatarInfo(
      id: 'avatar_scientist',
      label: 'Scientist',
      colors: [Color(0xFF10B981), Color(0xFF059669)], // Teal to Emerald
      icon: Icons.science_rounded,
    ),
    PresetAvatarInfo(
      id: 'avatar_writer',
      label: 'Writer',
      colors: [Color(0xFFF59E0B), Color(0xFFD97706)], // Amber to Orange
      icon: Icons.create_rounded,
    ),
    PresetAvatarInfo(
      id: 'avatar_manager',
      label: 'Manager',
      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Purple to Indigo
      icon: Icons.trending_up_rounded,
    ),
    PresetAvatarInfo(
      id: 'avatar_gamer',
      label: 'Gamer',
      colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], // Red to Dark Red
      icon: Icons.sports_esports_rounded,
    ),
    PresetAvatarInfo(
      id: 'avatar_athlete',
      label: 'Athlete',
      colors: [Color(0xFF06B6D4), Color(0xFF0891B2)], // Cyan to Dark Cyan
      icon: Icons.directions_run_rounded,
    ),
    PresetAvatarInfo(
      id: 'avatar_musician',
      label: 'Musician',
      colors: [Color(0xFFE040FB), Color(0xFF9C27B0)], // Pink Accent to Purple
      icon: Icons.music_note_rounded,
    ),
  ];

  static PresetAvatarInfo? getPreset(String id) {
    try {
      return presets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;

    if (avatarString.isEmpty) {
      avatarWidget = CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.primarySeedColor,
        child: Icon(Icons.person_rounded, size: radius, color: Colors.white),
      );
    } else {
      final preset = getPreset(avatarString);
      if (preset != null) {
        avatarWidget = Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: preset.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: preset.colors.first.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            preset.icon,
            size: radius,
            color: Colors.white,
          ),
        );
      } else {
        avatarWidget = CircleAvatar(
          radius: radius,
          backgroundColor: AppTheme.primarySeedColor,
          child: Icon(Icons.person_rounded, size: radius, color: Colors.white),
        );
      }
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}
