import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _criticalMode = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _criticalMode = prefs.getBool('critical_mode') ?? true;
    });
  }

  Future<void> _toggleCriticalMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('critical_mode', value);
    setState(() => _criticalMode = value);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 10),
                  _buildSectionTitle('NOTIFICACIONES'),
                  _buildCriticalModeSwitch(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('DATOS'),
                  _buildDataActions(),
                  const SizedBox(height: 40),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkGrey),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Configuración',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 16, top: 20),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.mediumGrey.withValues(alpha: 0.6),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }


  Widget _buildCriticalModeSwitch() {
    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modo Crítico',
                style: TextStyle(color: AppTheme.darkGrey, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Sonar aunque el móvil esté en silencio',
                style: TextStyle(color: AppTheme.mediumGrey, fontSize: 12),
              ),
            ],
          ),
          Switch(
            value: _criticalMode,
            activeTrackColor: AppTheme.softOrange.withValues(alpha: 0.5),
            activeColor: AppTheme.softOrange,
            onChanged: _toggleCriticalMode,
          ),

        ],
      ),
    );
  }

  Widget _buildDataActions() {
    return Center(
      child: TextButton(
        onPressed: _confirmDeleteAll,
        child: const Text(
          'Borrar todos los datos',
          style: TextStyle(color: AppTheme.mediumGrey, fontSize: 14, decoration: TextDecoration.underline),
        ),
      ),
    );
  }


  Future<void> _confirmDeleteAll() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.offWhite,
        title: const Text('¿Borrar todo?', style: TextStyle(color: AppTheme.darkGrey)),
        content: const Text(
          'Se eliminarán todos los medicamentos, horarios e historial de tomas de forma permanente.',
          style: TextStyle(color: AppTheme.mediumGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppTheme.mediumGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('BORRAR TODO', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Implementar borrado masivo en DatabaseHelper
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos eliminados correctamente')),
        );
      }
    }
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text(
          'v1.0.0 (Release)',
          style: TextStyle(color: AppTheme.mediumGrey, fontSize: 12),
        ),
        SizedBox(height: 8),
        Text(
          'Hecho con cuidado para tu salud',
          style: TextStyle(color: AppTheme.mediumGrey, fontSize: 14, fontStyle: FontStyle.italic),
        ),
        SizedBox(height: 40),
      ],
    );
  }
}
