import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'core/notifications/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:background_fetch/background_fetch.dart';
import 'core/database/database_helper.dart';

// Tarea de fondo para reactivar alarmas
@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }
  
  // Reactivar alarmas
  final dbHelper = DatabaseHelper();
  final notificationService = NotificationService();
  await notificationService.init();
  
  final medications = await dbHelper.getAllMedications();
  for (var med in medications) {
    if (med['time'] != null) {
      final parts = med['time'].split(':');
      final now = DateTime.now();
      final scheduledDate = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      
      await notificationService.scheduleNotification(
        id: med['id'],
        title: '¡Es hora de tu medicina!',
        body: 'Toma ${med['name']} (${med['dosage']})',
        scheduledDate: scheduledDate.isBefore(now) ? scheduledDate.add(const Duration(days: 1)) : scheduledDate,
      );
    }
  }
  
  BackgroundFetch.finish(taskId);
}

void main() async {

  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es_ES', null);

    
    // Inicializar servicios esenciales con manejo de errores
    await NotificationService().init().catchError((e) {
      debugPrint("Error inicializando notificaciones: $e");
    });
    
    // Configurar BackgroundFetch
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
    BackgroundFetch.configure(BackgroundFetchConfig(
      minimumFetchInterval: 15,
      stopOnTerminate: false,
      enableHeadless: true,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresStorageNotLow: false,
      requiresDeviceIdle: false,
      requiredNetworkType: NetworkType.NONE,
      startOnBoot: true,
    ), (String taskId) async {
      // Tarea periódica normal
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      BackgroundFetch.finish(taskId);
    });

  } catch (e) {
    debugPrint("Error crítico en arranque: $e");
  }
  
  runApp(const MedicationApp());
}


class MedicationApp extends StatelessWidget {
  const MedicationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
