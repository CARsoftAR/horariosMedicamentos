import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class StockCabinetScreen extends StatefulWidget {
  const StockCabinetScreen({super.key});

  @override
  State<StockCabinetScreen> createState() => _StockCabinetScreenState();
}

class _StockCabinetScreenState extends State<StockCabinetScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.vibrantRed))
                  : _medications.isEmpty
                      ? const Center(child: Text('No hay medicamentos en el gabinete', style: TextStyle(color: AppTheme.mediumGrey)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _medications.length,
                          itemBuilder: (context, index) => _buildStockCard(_medications[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.darkGrey),
            onPressed: () => Navigator.pop(context),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventario',
                style: TextStyle(color: AppTheme.mediumGrey, fontSize: 14),
              ),
              Text(
                'Gabinete de Stock',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> med) {
    final String name = med['name'] ?? 'Medicamento';
    final int stock = med['stock'] ?? 0;
    const int maxStock = 30; // Valor de referencia para la barra de progreso
    final double progress = (stock / maxStock).clamp(0.0, 1.0);

    return GlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.black.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.softRed),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$stock',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  const Text(
                    'uds',
                    style: TextStyle(fontSize: 10, color: AppTheme.mediumGrey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stock < 5 ? 'Reponer pronto' : 'Stock suficiente',
            style: TextStyle(
              fontSize: 10,
              color: stock < 5 ? Colors.redAccent : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
