import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import 'add_medication_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'stock_cabinet_screen.dart';
import '../../core/database/database_helper.dart';

import '../../core/controllers/medication_controller.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final MedicationController _medController = MedicationController();

  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getAllMedications();
    setState(() {
      _medications = data;
      _isLoading = false;
    });
  }

  void _navigateToEdit(Map<String, dynamic> med) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicationScreen(medication: med),
      ),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
            );
            if (result == true) _loadData();
          },
          backgroundColor: AppTheme.softOrange,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 35),
        ),
      ),
      bottomNavigationBar: _buildFloatingNavigation(),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 160.0,

              floating: true,
              backgroundColor: AppTheme.offWhite,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, d MMMM', 'es_ES').format(DateTime.now()),
                                style: const TextStyle(color: AppTheme.mediumGrey, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const Text(
                                'Hola, estas son tus\nmedicinas para hoy',
                                style: TextStyle(color: AppTheme.darkGrey, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.vibrantRed.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_rounded, color: AppTheme.vibrantRed, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.vibrantRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),


            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppTheme.vibrantRed)),
              )
            else if (_medications.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('No hay medicamentos registrados', style: TextStyle(color: AppTheme.mediumGrey)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildMedicationCard(_medications[index]);
                    },
                    childCount: _medications.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildMedicationCard(Map<String, dynamic> med) {
    final String name = med['name'] ?? 'Medicamento';
    final String dosage = med['dosage'] ?? 'Sin dosis';
    final int stock = med['stock'] ?? 0;
    final bool isTaken = (med['is_taken_today'] ?? 0) > 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap: () => _navigateToEdit(med),
        borderRadius: BorderRadius.circular(24),
        child: GlassCard(
          backgroundColor: isTaken ? AppTheme.pastelGreen : Colors.white,
          borderColor: isTaken ? null : AppTheme.primaryRed.withValues(alpha: 0.2),

          child: Row(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: isTaken ? null : () async {
                      await _medController.processMedicationIntake(med);
                      _loadData();
                    },

                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: AppTheme.pastelPink.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(med['icon'] ?? Icons.medication.codePoint, fontFamily: 'MaterialIcons'), 
                        color: isTaken ? AppTheme.lightGrey : AppTheme.vibrantRed,
                        size: 28,
                      ),
                    ),
                  ),

                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isTaken ? Colors.green : (stock > 0 ? Colors.green : Colors.red),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: isTaken ? const Icon(Icons.check, size: 8, color: Colors.white) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isTaken ? AppTheme.lightGrey : AppTheme.darkGrey,
                      ),
                    ),
                    Text(
                      dosage,
                      style: TextStyle(
                        color: isTaken ? AppTheme.lightGrey : AppTheme.mediumGrey, 
                        fontSize: 13
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined, 
                          size: 12, 
                          color: isTaken ? AppTheme.lightGrey : (stock < 5 ? Colors.redAccent : AppTheme.mediumGrey)
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stock: $stock uds.',
                          style: TextStyle(
                            color: isTaken ? AppTheme.lightGrey : (stock < 5 ? Colors.redAccent : AppTheme.mediumGrey),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isTaken)
                const Icon(Icons.chevron_right, color: AppTheme.mediumGrey, size: 24)
              else
                const Icon(Icons.done_all, color: Colors.green, size: 20),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildFloatingNavigation() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.home_rounded, 'Inicio', true, () {}),
          _navItem(Icons.history_rounded, 'Historial', false, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
          }),
          _navItem(Icons.inventory_2_rounded, 'Gabinete', false, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const StockCabinetScreen()));
          }),
          _navItem(Icons.settings_rounded, 'Ajustes', false, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          }),
        ],
      ),
    );
  }


  Widget _navItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.vibrantRed.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),

        child: Row(
          children: [
            Icon(
              icon, 
              color: isActive ? AppTheme.vibrantRed : AppTheme.mediumGrey,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.vibrantRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

