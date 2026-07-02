import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kms_monitoring_iot/components/counting_card.dart';
import 'package:kms_monitoring_iot/core/app_globals.dart';
import 'package:kms_monitoring_iot/page/ongoing_proses/ongoing_viewmodel.dart';
import 'package:stacked/stacked.dart';

class OngoingView extends StatelessWidget {
  const OngoingView({super.key});

  List<Map<String, dynamic>> _items(OngoingViewModel vm) {
    if (vm.ongoingList.isNotEmpty) return vm.ongoingList;
    if (!AppGlobals.previewCardMode) return [];
    return [
      {
        'SensorName': 'COUNTING SENSOR A01',
        'ProcesID': 'PROC-0001',
        'RefNumber': 'FOP-2026-000123',
        'StartDate': '2026-05-29T15:20:00',
        'EndDate': null,
        'TotalCount': 128,
        'CountValue': 128,
      },
      {
        'SensorName': 'COUNTING SENSOR B02',
        'ProcesID': 'PROC-0002',
        'RefNumber': 'FOP-2026-000124',
        'StartDate': '2026-05-29T15:35:00',
        'EndDate': null,
        'TotalCount': 75,
        'CountValue': 75,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<OngoingViewModel>.reactive(
      viewModelBuilder: () => OngoingViewModel(),
      onViewModelReady: (vm) => vm.getOngoingList(),
      builder: (context, vm, child) {
        final items = _items(vm);
        return Stack(
          children: [
            items.isEmpty
                ? _EmptyOngoing(onRefresh: vm.getOngoingList)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final e = items[index];
                      return CountingCard(
                        isEditCount: true,
                        sensorID: e['SensorName']?.toString() ?? '-',
                        procesID: e['ProcesID']?.toString() ?? '-',
                        refNumber: e['RefNumber']?.toString() ?? '-',
                        startDate: e['StartDate']?.toString() ?? '-',
                        endDate: e['EndDate']?.toString() ?? '-',
                        totalCount: e['TotalCount']?.toString() ?? '0',
                        countValue: e['CountValue']?.toString() ?? '0',
                        product: e['Product']?.toString().isNotEmpty == true
                            ? e['Product'].toString()
                            : e['ProductCode']?.toString().isNotEmpty == true
                            ? e['ProductCode'].toString()
                            : e['ProdCode']?.toString().isNotEmpty == true
                            ? e['ProdCode'].toString()
                            : e['ProductName']?.toString(),
                        countFormula:
                            e['CountingFormula']?.toString().isNotEmpty == true
                            ? e['CountingFormula'].toString()
                            : e['CountFormula']?.toString().isNotEmpty == true
                            ? e['CountFormula'].toString()
                            : e['Formula']?.toString(),
                        onSave: () => _onSave(context, vm, index, e),
                      );
                    },
                  ),
            Positioned(
              top: 0,
              right: 18,
              child: _FloatingRefresh(
                onTap: vm.getOngoingList,
                color: const Color(0xFF4F46E5),
              ),
            ),
            if (vm.isBusy) const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }

  Future<void> _onSave(
    BuildContext context,
    OngoingViewModel vm,
    int index,
    Map<String, dynamic> item,
  ) async {
    final result = await _showSaveDialog(context, item);
    if (result == null || !context.mounted) return;

    if (vm.ongoingList.isEmpty && AppGlobals.previewCardMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview mode: submit adjustment berhasil'),
        ),
      );
      return;
    }

    final success = await vm.saveTotalCount(
      index: index,
      adjustmentValue: result.adjustmentValue,
      totalCount: result.totalCount,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Total Count berhasil disimpan'
              : 'Gagal menyimpan Total Count',
        ),
      ),
    );
  }

  Future<_SaveDialogResult?> _showSaveDialog(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final countValue = _toInt(item['CountValue']);
    final adjustment = TextEditingController(text: '0');
    int total = countValue;

    return showDialog<_SaveDialogResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          void sync(String value) {
            setState(() => total = countValue + (int.tryParse(value) ?? 0));
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            title: Text(
              'Save Adjustment',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogNumberBox(
                  label: 'Count Value',
                  value: '$countValue',
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adjustment,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  inputFormatters: [_SignedIntegerInputFormatter()],
                  onChanged: sync,
                  decoration: InputDecoration(
                    labelText: 'Adjustment Value',
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                    prefixIcon: const Icon(Icons.tune_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _DialogNumberBox(
                  label: 'Total Count',
                  value: '$total',
                  color: const Color(0xFF16A34A),
                  highlight: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _SaveDialogResult(
                    adjustmentValue: int.tryParse(adjustment.text) ?? 0,
                    totalCount: total,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Submit',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DialogNumberBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool highlight;
  const _DialogNumberBox({
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.10) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingRefresh extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  const _FloatingRefresh({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.refresh_rounded, color: color, size: 32),
        ),
      ),
    );
  }
}

class _EmptyOngoing extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyOngoing({required this.onRefresh});
  @override
  Widget build(BuildContext context) => Center(
    child: TextButton.icon(
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh_rounded),
      label: Text(
        'Refresh On Process',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _SignedIntegerInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty || text == '-' || RegExp(r'^-?\d+$').hasMatch(text))
      return newValue;
    return oldValue;
  }
}

class _SaveDialogResult {
  final int adjustmentValue;
  final int totalCount;
  const _SaveDialogResult({
    required this.adjustmentValue,
    required this.totalCount,
  });
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
