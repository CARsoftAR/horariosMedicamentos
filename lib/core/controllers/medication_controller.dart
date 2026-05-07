import '../database/database_helper.dart';
import '../notifications/notification_service.dart';

class MedicationController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  /// Procesa la toma de un medicamento: registra en historial, descuenta stock y programa la próxima toma.
  Future<void> processMedicationIntake(Map<String, dynamic> med) async {
    final int medId = med['id'];
    final String medName = med['name'];
    final int currentStock = med['stock'] ?? 0;
    final String frequency = med['frequency'] ?? 'Diaria';
    final String currentTimeStr = med['time'] ?? '08:00';

    // 1. Registrar toma y descontar stock en DB
    await _dbHelper.recordIntake(
      medId, 
      'Tomada', 
      DateTime.now().toIso8601String(), 
      'User'
    );

    // 2. Alerta de Stock Bajo
    if (currentStock - 1 < 5) {
      await _notificationService.showNotification(
        id: medId + 1000,
        title: '¡Stock Bajo!',
        body: 'Te quedan pocas pastillas de $medName (${currentStock - 1} uds.)',

      );
    }

    // 3. Cálculo de Próxima Toma
    final nextIntake = _calculateNextIntake(currentTimeStr, frequency);
    
    // 4. Reprogramar notificación
    await _notificationService.scheduleNotification(
      id: medId,
      title: 'Es hora de tu medicina: $medName',
      body: 'Dosis programada según frecuencia: $frequency',
      scheduledDate: nextIntake,
    );
  }

  DateTime _calculateNextIntake(String timeStr, String frequency) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    DateTime baseTime = DateTime(now.year, now.month, now.day, hour, minute);

    switch (frequency) {
      case 'Cada 8 horas':
        return baseTime.add(const Duration(hours: 8));
      case 'Cada 12 horas':
        return baseTime.add(const Duration(hours: 12));
      case 'Semanal':
        return baseTime.add(const Duration(days: 7));
      case 'Diaria':
      default:
        return baseTime.add(const Duration(days: 1));
    }
  }
}
