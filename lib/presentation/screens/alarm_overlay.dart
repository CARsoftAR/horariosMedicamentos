import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';



class AlarmOverlay extends StatelessWidget {
  final int id;
  final String medicationName;

  const AlarmOverlay({super.key, required this.id, required this.medicationName});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          gradient: RadialGradient(
            colors: [
              AppTheme.pastelPink,
              Colors.white,
            ],
            center: Alignment.center,
            radius: 1.0,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                size: 80,
                color: AppTheme.vibrantRed,
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '$medicationName\n¡Es tu hora!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 80),
              _buildActionButton(
                label: 'TOMAR',
                color: AppTheme.softOrange,
                textColor: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                label: 'POSPONER',
                color: AppTheme.lightGrey.withValues(alpha: 0.3),
                textColor: AppTheme.mediumGrey,
                onPressed: () => Navigator.pop(context),
              ),


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 250,
      height: 65,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
