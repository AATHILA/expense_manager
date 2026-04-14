import 'package:expense_manager_project/blocs/theme/theme_event.dart';
import 'package:expense_manager_project/blocs/theme/theme_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../../services/storage_services.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<LoadTheme>(_onLoadTheme);
    on<ToggleTheme>(_onToggleTheme);
    on<SetTheme>(_onSetTheme);

    // Load theme on initialization
    add(const LoadTheme());
  }

  Future<void> _onLoadTheme(
      LoadTheme event,
      Emitter<ThemeState> emit,
      ) async {
    try {
      final isDarkMode = await StorageService.getThemeModeAsync();
      final themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      emit(state.copyWith(themeMode: themeMode));
    } catch (e) {
      // Default to light mode on error
      emit(state.copyWith(themeMode: ThemeMode.light));
    }
  }

  Future<void> _onToggleTheme(
      ToggleTheme event,
      Emitter<ThemeState> emit,
      ) async {
    try {
      final newThemeMode = state.isDarkMode ? ThemeMode.light : ThemeMode.dark;
      final isDarkMode = newThemeMode == ThemeMode.dark;
      await StorageService.setThemeMode(isDarkMode);
      emit(state.copyWith(themeMode: newThemeMode));
    } catch (e) {
      // Ignore error and keep current theme
    }
  }

  Future<void> _onSetTheme(
      SetTheme event,
      Emitter<ThemeState> emit,
      ) async {
    try {
      final isDarkMode = event.themeMode == ThemeMode.dark;
      await StorageService.setThemeMode(isDarkMode);
      emit(state.copyWith(themeMode: event.themeMode));
    } catch (e) {
      // Ignore error and keep current theme
    }
  }
}

