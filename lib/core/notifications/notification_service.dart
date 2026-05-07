import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Inicializar Timezone
    tz.initializeTimeZones();
    var timeZoneName = 'UTC';
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      timeZoneName = localTz.toString();
    } catch (e) {
      debugPrint("Error obteniendo zona horaria: $e");
    }
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Configuración Android para notificaciones simples
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
    await checkPermissions();
  }

  static const _ringtoneChannel = MethodChannel('com.abbamat.tmn/ringtone');

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool isCritical = true,
    String? customSound,
  }) async {
    String? soundToPlay = customSound;
    
    // Fallback Crítico: Si la URI es nula o no es válida (no empieza con content://), 
    // usamos la alarma predeterminada del sistema.
    if (soundToPlay == null || !soundToPlay.startsWith('content://')) {
      try {
        soundToPlay = await _ringtoneChannel.invokeMethod('getDefaultAlarmUri');
      } catch (e) {
        debugPrint("Error obteniendo URI por defecto: $e");
        soundToPlay = "content://settings/system/alarm_alert"; // URI hardcoded de respaldo absoluto
      }
    }

    // VERIFICACIÓN CRÍTICA: Print de la URI que se enviará
    debugPrint("🔔 DISPARANDO NOTIFICACIÓN - ID: $id");
    debugPrint("🔊 URI DE SONIDO: $soundToPlay");

    // Configuración del canal de notificación (Android)
    final androidDetails = AndroidNotificationDetails(
      'system_alarm_channel_v5', // Incrementado para asegurar nuevos parámetros
      'Alarmas de Medicación Críticas',
      channelDescription: 'Canal de alta importancia para asegurar que la alarma suene.',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      sound: soundToPlay != null ? UriAndroidNotificationSound(soundToPlay) : null,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint("✅ Alarma programada con éxito para: ${scheduledDate.toString()}");
    } catch (e) {
      debugPrint("❌ ERROR PROGRAMANDO ALARMA: $e");
      // Respaldo de Emergencia: Si falla la programación con sonido personalizado, intentamos con el default
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: "$body (Fallback de Sonido)",
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'emergency_fallback_channel',
            'Respaldo de Alarma',
            importance: Importance.max,
            priority: Priority.high,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> checkPermissions() async {
    try {
      final bool hasPermission = await _ringtoneChannel.invokeMethod('checkExactAlarmPermission');
      if (!hasPermission) {
        debugPrint("⚠️ No hay permiso de alarmas exactas. Solicitando...");
        await _ringtoneChannel.invokeMethod('requestExactAlarmPermission');
      }
    } catch (e) {
      debugPrint("Error verificando permisos de alarma: $e");
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_alerts',
          'Alertas Críticas',
          channelDescription: 'Canal para alertas de stock y urgencias',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}


