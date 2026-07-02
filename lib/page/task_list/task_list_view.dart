import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kms_monitoring_iot/components/fop_card.dart';
import 'package:kms_monitoring_iot/components/scanner_view.dart';
import 'package:kms_monitoring_iot/components/styles.dart';
import 'package:kms_monitoring_iot/page/task_list/task_list_viewmodel.dart';
import 'package:stacked/stacked.dart';

class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  static final TextInputFormatter _decimalInputFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final text = newValue.text;
        if (text.isEmpty || RegExp(r'^\d*([.,]\d*)?$').hasMatch(text)) {
          return newValue;
        }
        return oldValue;
      });

  Future<void> _scan(
    BuildContext context,
    TextEditingController controller,
    String title,
  ) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ScannerView(title: title)),
    );
    if (result != null && result.isNotEmpty) {
      controller.text = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<TaskListViewModel>.reactive(
      viewModelBuilder: () => TaskListViewModel(),
      onViewModelReady: (vm) async {
        await vm.getCounting();
        vm.resumeTimerIfNeeded();
        vm.getDataProcess();
      },
      builder: (context, vm, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => vm.getCounting(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    _buildStartCountingCard(context, vm),
                    const SizedBox(height: 22),
                    _buildListHeader(),
                    const SizedBox(height: 8),
                    _buildFilterRow(context, vm),
                    const SizedBox(height: 12),
                    if (vm.fopList.isEmpty)
                      _buildEmptyCard()
                    else
                      ...vm.fopList.map((item) => FopCard(fopData: item)),
                  ],
                ),
              ),
              if (vm.isBusy) Center(child: loadingSpinWhiteSizeBig),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartCountingCard(BuildContext context, TaskListViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _circleIcon(
                Icons.qr_code_scanner_rounded,
                const Color(0xFF2563EB),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai Counting',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scan FOP Number dan Process ID untuk memulai counting baru.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.35,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5EAF3)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _scanInputRow(
                  context: context,
                  controller: vm.fopPlanning,
                  title: 'FOP Number',
                  hint: 'Scan / Input FOP Number',
                  iconColor: const Color(0xFF7C3AED),
                  errorText: vm.errorFopPlanning,
                  scanTitle: 'Scan FOP Number',
                  onChanged: (_) {
                    vm.errorFopPlanning = null;
                    vm.notifyListeners();
                  },
                ),
                _thinDivider(),
                _scanInputRow(
                  context: context,
                  controller: vm.inputProduk,
                  title: 'Input Produk',
                  hint: 'Scan / Input Kode Produk',
                  iconColor: const Color(0xFF059669),
                  errorText: null,
                  scanTitle: 'Scan Kode Produk',
                  onChanged: (_) => vm.notifyListeners(),
                ),
                _thinDivider(),
                _scanInputRow(
                  context: context,
                  controller: vm.inputKodeMesin,
                  title: 'Process ID',
                  hint: 'Scan / Input Process ID',
                  iconColor: const Color(0xFF2563EB),
                  errorText: vm.errorKodeMesin,
                  scanTitle: 'Scan Process ID',
                  onChanged: (_) {
                    vm.errorKodeMesin = null;
                    vm.notifyListeners();
                  },
                ),
                _thinDivider(),
                _numberInputRow(vm),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: vm.isBusy ? null : () => vm.postCounting(context),
              icon: const Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white,
              ),
              label: Text(
                'Start Counting',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF0866F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_rounded,
                size: 18,
                color: Colors.blueGrey.shade400,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data yang baru saja ditambahkan masuk ke On Process.',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF7A8499),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scanInputRow({
    required BuildContext context,
    required TextEditingController controller,
    required String title,
    required String hint,
    required Color iconColor,
    required String? errorText,
    required String scanTitle,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _softIcon(Icons.qr_code_2_rounded, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                labelText: title,
                hintText: hint,
                errorText: errorText,
                labelStyle: GoogleFonts.poppins(
                  color: const Color(0xFF344054),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF98A2B3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                errorStyle: GoogleFonts.poppins(fontSize: 11),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _scan(context, controller, scanTitle),
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFF0866F2),
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE5EAF3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberInputRow(TaskListViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _softIcon(Icons.numbers_rounded, const Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: vm.countingFormula,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_decimalInputFormatter],
              onChanged: (_) {
                vm.errorCountingFormula = null;
                vm.notifyListeners();
              },
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                labelText: 'Counting Formula',
                hintText: 'Masukkan Counting Formula (boleh desimal)',
                errorText: vm.errorCountingFormula,
                labelStyle: GoogleFonts.poppins(
                  color: const Color(0xFF344054),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF98A2B3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                errorStyle: GoogleFonts.poppins(fontSize: 11),
              ),
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5EAF3)),
            ),
            child: const Icon(Icons.tag_rounded, color: Color(0xFF0866F2)),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Task',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
               
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(BuildContext context, TaskListViewModel vm) {
    final hasFilter =
        vm.selectedCategory != null || vm.selectedProcessName != null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Tombol filter
          GestureDetector(
            onTap: () => _showFilterSheet(context, vm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasFilter ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasFilter
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE5EAF3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: hasFilter ? Colors.white : const Color(0xFF667085),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Filter',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: hasFilter ? Colors.white : const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Active filter chips
          if (vm.selectedCategory != null) ...[
            const SizedBox(width: 8),
            _filterChip(
              label: vm.selectedCategory!,
              color: const Color(0xFF7C3AED),
              onRemove: () => vm.setCategory(null),
            ),
          ],
          if (vm.selectedProcessName != null) ...[
            const SizedBox(width: 8),
            _filterChip(
              label: vm.selectedProcessName!,
              color: const Color(0xFF059669),
              onRemove: () => vm.setProcessName(null),
            ),
          ],
          if (hasFilter) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => vm.clearFilters(),
              child: Text(
                'Reset',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 13, color: color),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, TaskListViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Filter Data',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Kategori
                  Text(
                    'Kategori',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vm.availableCategories.map((cat) {
                      final isSelected = vm.selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {});
                          vm.setCategory(isSelected ? null : cat);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Filter Process Name
                  Text(
                    'Process',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF344054),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: vm.availableProcessNames.map((name) {
                      final isSelected = vm.selectedProcessName == name;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {});
                          vm.setProcessName(isSelected ? null : name);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF059669)
                                : const Color(
                                    0xFF059669,
                                  ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF059669),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Reset button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        vm.clearFilters();
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Reset Filter',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Belum ada task',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE5EAF3)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.045),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _circleIcon(IconData icon, Color color) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  Widget _softIcon(IconData icon, Color color, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }

  Widget _thinDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFE5EAF3));
  }
}
