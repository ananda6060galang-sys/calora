import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';

enum MealReminderKind { breakfast, lunch, dinner }

class MealReminderConfig {
  const MealReminderConfig({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  MealReminderConfig copyWith({
    bool? enabled,
    int? hour,
    int? minute,
  }) {
    return MealReminderConfig(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  String formatTime() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
      };

  factory MealReminderConfig.fromMap(Map<String, dynamic> map) {
    return MealReminderConfig(
      enabled: map['enabled'] as bool? ?? true,
      hour: map['hour'] as int? ?? 8,
      minute: map['minute'] as int? ?? 0,
    );
  }
}

class MealRemindersState {
  const MealRemindersState({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  final MealReminderConfig breakfast;
  final MealReminderConfig lunch;
  final MealReminderConfig dinner;

  MealRemindersState copyWith({
    MealReminderConfig? breakfast,
    MealReminderConfig? lunch,
    MealReminderConfig? dinner,
  }) {
    return MealRemindersState(
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
    );
  }

  static const defaultState = MealRemindersState(
    breakfast: MealReminderConfig(enabled: true, hour: 8, minute: 0),
    lunch: MealReminderConfig(enabled: true, hour: 12, minute: 30),
    dinner: MealReminderConfig(enabled: true, hour: 19, minute: 0),
  );
}

class MealReminderNotifier extends StateNotifier<MealRemindersState> {
  MealReminderNotifier() : super(MealRemindersState.defaultState) {
    _loadAndSchedule();
  }

  static const String _storageKey = 'calora_meal_reminders_config_v1';

  Future<void> _loadAndSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final Map<String, dynamic> data = json.decode(raw);
        state = MealRemindersState(
          breakfast: MealReminderConfig.fromMap(data['breakfast'] ?? {}),
          lunch: MealReminderConfig.fromMap(data['lunch'] ?? {}),
          dinner: MealReminderConfig.fromMap(data['dinner'] ?? {}),
        );
      }
      await _syncSchedules();
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'breakfast': state.breakfast.toMap(),
        'lunch': state.lunch.toMap(),
        'dinner': state.dinner.toMap(),
      };
      await prefs.setString(_storageKey, json.encode(map));
      await _syncSchedules();
    } catch (_) {}
  }

  Future<void> _syncSchedules() async {
    final ns = NotificationService.instance;
    await ns.initialize();

    // ID 101: Breakfast
    if (state.breakfast.enabled) {
      await ns.scheduleDailyMealReminder(
        id: 101,
        title: 'Waktunya Sarapan Sehat! 🌅',
        body: 'Jangan lewatkan sarapan. Catat energimu hari ini di Calora.',
        hour: state.breakfast.hour,
        minute: state.breakfast.minute,
        payload: 'meal:breakfast',
      );
    } else {
      await ns.cancelReminder(101);
    }

    // ID 102: Lunch
    if (state.lunch.enabled) {
      await ns.scheduleDailyMealReminder(
        id: 102,
        title: 'Saatnya Makan Siang! ☀️',
        body: 'Jaga nutrisi & target kalorimu. Yuk log menu makan siangmu!',
        hour: state.lunch.hour,
        minute: state.lunch.minute,
        payload: 'meal:lunch',
      );
    } else {
      await ns.cancelReminder(102);
    }

    // ID 103: Dinner
    if (state.dinner.enabled) {
      await ns.scheduleDailyMealReminder(
        id: 103,
        title: 'Waktunya Makan Malam! 🌙',
        body: 'Lengkapi catatan nutrisi harianmu sebelum istirahat malam ini.',
        hour: state.dinner.hour,
        minute: state.dinner.minute,
        payload: 'meal:dinner',
      );
    } else {
      await ns.cancelReminder(103);
    }
  }

  Future<void> toggleReminder(MealReminderKind kind, bool enabled) async {
    switch (kind) {
      case MealReminderKind.breakfast:
        state = state.copyWith(breakfast: state.breakfast.copyWith(enabled: enabled));
        break;
      case MealReminderKind.lunch:
        state = state.copyWith(lunch: state.lunch.copyWith(enabled: enabled));
        break;
      case MealReminderKind.dinner:
        state = state.copyWith(dinner: state.dinner.copyWith(enabled: enabled));
        break;
    }
    await _save();
  }

  Future<void> updateTime(MealReminderKind kind, int hour, int minute) async {
    switch (kind) {
      case MealReminderKind.breakfast:
        state = state.copyWith(breakfast: state.breakfast.copyWith(hour: hour, minute: minute));
        break;
      case MealReminderKind.lunch:
        state = state.copyWith(lunch: state.lunch.copyWith(hour: hour, minute: minute));
        break;
      case MealReminderKind.dinner:
        state = state.copyWith(dinner: state.dinner.copyWith(hour: hour, minute: minute));
        break;
    }
    await _save();
  }

  Future<void> sendTestReminder() async {
    await NotificationService.instance.showTestNotification(
      title: 'Pengingat Makan Calora Aktif! 🥑',
      body: 'Notifikasi pengingat makan berhasil disetel. Calora siap mengingatkanmu!',
    );
  }
}

final mealReminderProvider =
    StateNotifierProvider<MealReminderNotifier, MealRemindersState>((ref) {
  return MealReminderNotifier();
});
