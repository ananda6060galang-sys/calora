import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/providers/profile_provider.dart';
import '../../diary/providers/diary_provider.dart';
import '../../profile/providers/weight_log_provider.dart';

/// Severity drives the leading icon tint, not decoration: every reminder
/// marks a real state derived from the user's own data (R-38/R-17).
enum ReminderKind { logMeal, protein, weight, streak }

class AppReminder {
  const AppReminder({
    required this.kind,
    required this.titleKey,
    required this.bodyKey,
    this.bodyArgs = const [],
  });

  final ReminderKind kind;
  final String titleKey;
  final String bodyKey;
  final List<String> bodyArgs;
}

/// Builds the in-app reminder list purely from local data that already
/// exists (diary, weight logs, profile). Nothing is fabricated: when the
/// user has nothing to act on, the list is empty and the screen shows an
/// honest "all caught up" state (R-27/R-38).
///
/// Scheduled OS push and food-request status reminders are intentionally
/// left out until Supabase is wired, so no reminder depends on data the
/// app cannot yet read.
final remindersProvider = Provider<List<AppReminder>>((ref) {
  final entries = ref.watch(diaryProvider);
  final profile = ref.watch(userProfileProvider);
  final streak = ref.watch(diaryLoggingStreakProvider);
  final weightLogs = ref.watch(weightLogProvider);
  final now = DateTime.now();

  final todayEntries =
      entries.where((e) => DateUtils.isSameDay(e.date, now)).toList();
  final loggedMeals = todayEntries.map((e) => e.meal.toLowerCase()).toSet();

  final reminders = <AppReminder>[];

  // 1. Nothing logged yet today.
  if (todayEntries.isEmpty) {
    reminders.add(const AppReminder(
      kind: ReminderKind.logMeal,
      titleKey: 'notifications.logTodayTitle',
      bodyKey: 'notifications.logTodayBody',
    ));
  } else {
    // 1b. Some meals logged but dinner is missing later in the day.
    final hasEarlierMeal =
        loggedMeals.contains('breakfast') || loggedMeals.contains('lunch');
    if (now.hour >= 18 &&
        hasEarlierMeal &&
        !loggedMeals.contains('dinner')) {
      reminders.add(const AppReminder(
        kind: ReminderKind.logMeal,
        titleKey: 'notifications.dinnerTitle',
        bodyKey: 'notifications.dinnerBody',
      ));
    }

    // 2. Protein still well short late in the day.
    final proteinToday =
        todayEntries.fold<double>(0, (sum, e) => sum + e.proteinG);
    final proteinGap = profile.proteinTargetG - proteinToday;
    if (now.hour >= 15 &&
        profile.proteinTargetG > 0 &&
        proteinGap >= profile.proteinTargetG * 0.4) {
      reminders.add(AppReminder(
        kind: ReminderKind.protein,
        titleKey: 'notifications.proteinTitle',
        bodyKey: 'notifications.proteinBody',
        bodyArgs: ['${proteinGap.round()}'],
      ));
    }
  }

  // 3. Weight not updated in a week or more.
  if (weightLogs.isEmpty) {
    reminders.add(const AppReminder(
      kind: ReminderKind.weight,
      titleKey: 'notifications.weightFirstTitle',
      bodyKey: 'notifications.weightFirstBody',
    ));
  } else {
    final daysSince = DateUtils.dateOnly(now)
        .difference(DateUtils.dateOnly(weightLogs.last.loggedDate))
        .inDays;
    if (daysSince >= 7) {
      reminders.add(AppReminder(
        kind: ReminderKind.weight,
        titleKey: 'notifications.weightStaleTitle',
        bodyKey: 'notifications.weightStaleBody',
        bodyArgs: ['$daysSince'],
      ));
    }
  }

  // 4. Celebrate an active logging streak.
  if (streak >= 3) {
    reminders.add(AppReminder(
      kind: ReminderKind.streak,
      titleKey: 'notifications.streakTitle',
      bodyKey: 'notifications.streakBody',
      bodyArgs: ['$streak'],
    ));
  }

  return reminders;
});

/// Tracks keys of reminders that have been viewed by the user.
class ViewedNotificationsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void markAllAsViewed(List<AppReminder> reminders) {
    state = reminders
        .map((r) => '${r.kind.name}_${r.titleKey}_${r.bodyArgs.join("_")}')
        .toSet();
  }

  void reset() {
    state = <String>{};
  }
}

final viewedNotificationsProvider =
    NotifierProvider<ViewedNotificationsNotifier, Set<String>>(
  ViewedNotificationsNotifier.new,
);

/// Indicates whether there are unread notifications to display with a red dot.
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final reminders = ref.watch(remindersProvider);
  if (reminders.isEmpty) return false;

  final viewedKeys = ref.watch(viewedNotificationsProvider);
  final currentKeys = reminders
      .map((r) => '${r.kind.name}_${r.titleKey}_${r.bodyArgs.join("_")}')
      .toSet();
  return currentKeys.difference(viewedKeys).isNotEmpty;
});

