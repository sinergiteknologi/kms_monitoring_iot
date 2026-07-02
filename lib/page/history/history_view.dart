import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kms_monitoring_iot/components/fop_card.dart';
import 'package:kms_monitoring_iot/components/styles.dart';
import 'package:kms_monitoring_iot/page/history/histoy_viewmodel.dart';
import 'package:stacked/stacked.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HistoryViewModel>.reactive(
      viewModelBuilder: () => HistoryViewModel(),
      onViewModelReady: (vm) => vm.fetchHistory(),
      builder: (context, vm, child) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => vm.fetchHistory(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    _buildListHeader(),
                    const SizedBox(height: 22),
                    _buildSearchBox(vm),
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

  // ── Header — sama seperti task_list_view ──────────────────────
  Widget _buildListHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task History',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                'Riwayat task counting yang sudah selesai',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Search box — gaya sama dengan input di task_list_view ─────
  Widget _buildSearchBox(HistoryViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: vm.setSearchQuery,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Icon(
              Icons.search_rounded,
              color: Color(0xFF98A2B3),
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
          hintText: 'Cari FOP Number / SO / Deskripsi',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF98A2B3),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          suffixIcon: vm.searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    vm.clearSearch();
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF98A2B3),
                    size: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────
  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Belum ada history',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Data task yang selesai akan muncul di sini.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
