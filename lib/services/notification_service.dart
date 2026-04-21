import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> init() async {
    await AwesomeNotifications().initialize(
      null, // default icon
      [
        NotificationChannel(
          channelKey: 'daily_reminder',
          channelName: 'Daily Reminders',
          channelDescription: 'Notifications for daily events and quests',
          defaultColor: const Color(0xFF00E5FF),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
    );

    // Request permissions
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> scheduleDailyReminder() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1,
          channelKey: 'daily_reminder',
          title: '🐍 Don\'t Miss Today\'s Special Event!',
          body: 'A new daily challenge is waiting for you with extra rewards. Come play now!',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'PLAY',
            label: 'PLAY NOW',
          ),
          NotificationActionButton(
            key: 'QUESTS',
            label: 'VIEW QUESTS',
          ),
        ],
        schedule: NotificationCalendar(
          hour: 10,
          minute: 0,
          second: 0,
          millisecond: 0,
          repeats: true,
        ),
      );
    } catch (e) {
      debugPrint("Could not schedule notification: $e");
    }
  }

  Future<void> notifyQuestAlmostComplete(String questTitle) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) return;

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 2,
          channelKey: 'daily_reminder',
          title: '🏆 Almost There!',
          body: 'You\'re 80% done with quest: "$questTitle". Finish it for big rewards!',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Progress,
        ),
      );
    } catch (e) {
      debugPrint("Could not send quest notification: $e");
    }
  }

  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }
}
