import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _selectedFilter = 'Hoy';
  List<Map<String, dynamic>> _allHistory = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getAllIntakeHistory();
    setState(() {
      _allHistory = data;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final now = DateTime.now();
    setState(() {
      _filteredHistory = _allHistory.where((item) {
        final date = DateTime.parse(item['timestamp']);
        if (_selectedFilter == 'Hoy') {
          return date.year == now.year && date.month == now.month && date.day == now.day;
        } else if (_selectedFilter == 'Semana') {

          return date.isAfter(now.subtract(const Duration(days: 7)));
        } else {
          return date.year == now.year && date.month == now.month;
        }
      }).toList();
    });
  }

  double _calculateCompliance() {
    if (_filteredHistory.isEmpty) return 0;
    final taken = _filteredHistory.where((item) => item['status'] == 'Tomada').length;
    return (taken / _filteredHistory.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final compliance = _calculateCompliance();

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterSelector(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.vibrantRed))
                : _filteredHistory.isEmpty
                    ? const Center(child: Text('Sin actividad en este periodo', style: TextStyle(color: AppTheme.mediumGrey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) => _buildHistoryCard(_filteredHistory[index]),
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
                'Tu Progreso',
                style: TextStyle(color: AppTheme.mediumGrey, fontSize: 14),
              ),
              Text(
                'Historial de Tomas',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: ['Hoy', 'Semana', 'Mes'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter);
                _applyFilter();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.vibrantRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  filter,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.mediumGrey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final date = DateTime.parse(item['timestamp']);
    final isTaken = item['status'] == 'Tomada';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: GlassCard(
        borderColor: AppTheme.mediumGrey.withValues(alpha: 0.05),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTaken ? AppTheme.pastelGreen : AppTheme.pastelPink,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTaken ? Icons.check_rounded : Icons.close_rounded,
                color: isTaken ? Colors.green.shade700 : Colors.red.shade700,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['med_name'] ?? 'Medicamento',
                    style: const TextStyle(color: AppTheme.darkGrey, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Registrado a las ${DateFormat('HH:mm').format(date)}',
                    style: const TextStyle(color: AppTheme.mediumGrey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('dd/MM').format(date),
                  style: const TextStyle(color: AppTheme.darkGrey, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  isTaken ? 'Completado' : 'Omitido',
                  style: TextStyle(
                    color: isTaken ? Colors.green.shade700 : Colors.red.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
