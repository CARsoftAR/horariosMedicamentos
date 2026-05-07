import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';


class AddMedicationScreen extends StatefulWidget {
  final Map<String, dynamic>? medication;

  const AddMedicationScreen({super.key, this.medication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _stockController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _frequency = 'Diaria';
  String? _selectedSound;
  final List<String> _frequencies = ['Diaria', 'Cada 8 horas', 'Cada 12 horas', 'Semanal'];
  
  static const _ringtoneChannel = MethodChannel('com.abbamat.tmn/ringtone');

  Future<void> _pickRingtone() async {
    try {
      final String? uri = await _ringtoneChannel.invokeMethod('pickRingtone', {
        'existingUri': _selectedSound,
      });
      if (uri != null) {
        setState(() {
          _selectedSound = uri;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sonido seleccionado correctamente'))
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking ringtone: $e");
    }
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _isEditing = true;
      _nameController.text = widget.medication!['name'] ?? '';
      _dosageController.text = widget.medication!['dosage'] ?? '';
      _stockController.text = (widget.medication!['stock'] ?? 20).toString();
      _frequency = widget.medication!['frequency'] ?? 'Diaria';
      _selectedSound = widget.medication!['sound_uri'] ?? widget.medication!['alarm_sound'];

      
      if (widget.medication!['time'] != null) {
        final parts = widget.medication!['time'].split(':');
        if (parts.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveMedication() async {
    try {
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ingresa el nombre del medicamento'))
        );
        return;
      }

      final medData = {
        'name': _nameController.text,
        'dosage': _dosageController.text,
        'stock': int.tryParse(_stockController.text) ?? 20,
        'color': AppTheme.primaryRed.toARGB32(),
        'icon': Icons.medication.codePoint,
        'frequency': _frequency,
        'sound_uri': _selectedSound,
      };

      final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      int medId;
      if (_isEditing) {
        medId = widget.medication!['id'];
        await _dbHelper.updateMedication(medId, medData);
        await _dbHelper.updateMedicationSchedule(medId, timeStr);
      } else {
        medId = await _dbHelper.insertMedication(medData);
        await _dbHelper.insertSchedule({
          'med_id': medId,
          'time': timeStr,
          'active': 1,
        });
      }

      // Programar Notificación
      final prefs = await SharedPreferences.getInstance();
      final isCritical = prefs.getBool('critical_mode') ?? true;
      final notificationService = NotificationService();
      
      final now = DateTime.now();
      DateTime scheduledDate = DateTime(
        now.year, now.month, now.day, 
        _selectedTime.hour, _selectedTime.minute
      );
      
      // Si la hora ya pasó hoy, programar para mañana
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await notificationService.scheduleNotification(
        id: medId,
        title: '¡Es hora de tu medicina!',
        body: 'Toma ${_nameController.text} (${_dosageController.text})',
        scheduledDate: scheduledDate,
        isCritical: isCritical,
        customSound: _selectedSound,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error al guardar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.redAccent)
        );
      }
    }
  }


  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.offWhite,
        title: const Text('¿Eliminar medicamento?', style: TextStyle(color: AppTheme.darkGrey)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: AppTheme.mediumGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.mediumGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteMedication(widget.medication!['id']);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppTheme.offWhite,
              title: Text(_isEditing ? 'Editar Medicamento' : 'Nuevo Medicamento', 
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkGrey),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.pastelRed),
                    onPressed: _confirmDelete,
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('Nombre del Medicamento', _nameController, Icons.medication),
                      const SizedBox(height: 20),
                      _buildTextField('Dosis (ej: 500mg, 1 cápsula)', _dosageController, Icons.straighten),
                      const SizedBox(height: 20),
                      _buildTextField('Stock Inicial', _stockController, Icons.inventory_2_outlined, keyboardType: TextInputType.number),
                      const SizedBox(height: 30),
                      const Text('Hora de la toma', style: TextStyle(color: AppTheme.mediumGrey, fontSize: 14)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          _buildBubble(
                            _selectedTime.format(context), 
                            true, 
                            Icons.access_time, 
                            onTap: () => _selectTime(context),
                            color: AppTheme.softRed
                          ),

                        ],
                      ),
                      const SizedBox(height: 30),
                      const Text('Frecuencia', style: TextStyle(color: AppTheme.mediumGrey, fontSize: 14)),
                      const SizedBox(height: 10),
                      Column(
                        children: _frequencies.map((f) {
                          final isSelected = _frequency == f;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: SizedBox(
                              width: double.infinity,
                              child: _buildBubble(
                                f, 
                                isSelected, 
                                null, 
                                onTap: () => setState(() => _frequency = f),
                                color: isSelected ? AppTheme.softRed : AppTheme.pastelPink
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 30),
                      const Text('Sonido de Alarma', style: TextStyle(color: AppTheme.mediumGrey, fontSize: 14)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _pickRingtone,
                          icon: const Icon(Icons.music_note_rounded),
                          label: Text(
                            _selectedSound == null ? 'SELECCIONAR TONO NATIVO' : 'CAMBIAR SONIDO',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.pastelYellow,
                            foregroundColor: Colors.orange.shade800,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      if (_selectedSound != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'URI: ${_selectedSound!.split('/').last}',
                            style: const TextStyle(fontSize: 10, color: AppTheme.mediumGrey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _saveMedication,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.softRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: Text(
                            _isEditing ? 'ACTUALIZAR CAMBIOS' : 'GUARDAR MEDICAMENTO',
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Future<void> _playPreview(String soundName) async {
    try {
      await _audioPlayer.stop();
      debugPrint("Simulando vista previa de 2 segundos para: $soundName");
    } catch (e) {
      debugPrint("Error en preview de audio: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.mediumGrey, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppTheme.darkGrey),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.softRed, size: 20),
            filled: true,
            fillColor: Colors.white,

            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppTheme.pastelRed, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppTheme.pastelRed, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppTheme.softRed, width: 2),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildBubble(String label, bool isSelected, IconData? icon, {required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? Colors.transparent : AppTheme.pastelRed, width: 1.5),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppTheme.mediumGrey),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.darkGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
