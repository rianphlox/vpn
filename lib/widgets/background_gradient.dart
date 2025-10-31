// This file contains the implementation of the BackgroundGradient widget, which provides a background with a gradient or a wallpaper.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/wallpaper_service.dart';

/// A widget that provides a background with a gradient or a wallpaper.
class BackgroundGradient extends StatelessWidget {
  /// The child widget.
  final Widget child;

  /// Creates a new instance of the [BackgroundGradient].
  const BackgroundGradient({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<WallpaperService>(
      builder: (context, wallpaperService, _) {
        // Check if wallpaper is enabled and file exists
        final wallpaperFile = wallpaperService.getWallpaperFile();

        if (wallpaperFile != null) {
          return FutureBuilder<bool>(
            future: wallpaperFile.exists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.data != true) {
                // Show gradient while loading or if file doesn't exist
                return _buildGradientBackground();
              }

              return _buildWallpaperBackground(wallpaperFile);
            },
          );
        }

        // Default gradient background
        return _buildGradientBackground();
      },
      child: child,
    );
  }

  /// Builds the gradient background.
  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.surfaceDark, AppTheme.surfaceContainer],
        ),
      ),
      child: child,
    );
  }

  /// Builds the wallpaper background.
  Widget _buildWallpaperBackground(File wallpaperFile) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(wallpaperFile),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(
              0.3,
            ), // Add overlay for better text readability
            BlendMode.darken,
          ),
        ),
      ),
      child: child,
    );
  }
}