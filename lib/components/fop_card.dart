import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FopCard extends StatefulWidget {
  final Map<String, dynamic> fopData;

  const FopCard({super.key, required this.fopData});

  @override
  State<FopCard> createState() => _FopCardState();
}

class _FopCardState extends State<FopCard> {
  bool _isFopExpanded = false;
  final Set<String> _expandedBoms = {};

  List<Map<String, dynamic>> get _bomList {
    final raw = widget.fopData['BOMList'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _processesForBom(String bomCode) {
    final bom = _bomList.firstWhere(
      (b) => b['BOMCode']?.toString() == bomCode,
      orElse: () => {},
    );
    final raw = bom['ProcessList'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final fop = widget.fopData;
    final fopNumber = _val(fop, ['FOPNumber', 'FOPNo', 'FopNumber']) ?? '-';
    final fopDate = _formatDate(_val(fop, ['FOPDate', 'FopDate', 'Date']));
    final soNumber = _val(fop, ['SONumber', 'SoNumber', 'SONo']) ?? '-';
    final description = _val(fop, ['Description', 'Desc', 'Notes']) ?? '-';
    final bomCount = _bomList.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFopExpanded
              ? const Color(0xFF7C3AED).withValues(alpha: 0.35)
              : const Color(0xFFE5EAF3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isFopExpanded = !_isFopExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _buildFopHeader(
              fopNumber,
              fopDate,
              soNumber,
              description,
              bomCount,
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _bomList.isEmpty
                ? _buildEmptyBom()
                : Column(
                    children: [
                      const Divider(height: 1, color: Color(0xFFE5EAF3)),
                      ..._bomList.map((bom) => _buildBomRow(bom)),
                    ],
                  ),
            crossFadeState: _isFopExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildFopHeader(
    String fopNumber,
    String fopDate,
    String soNumber,
    String description,
    int bomCount,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: Color(0xFF7C3AED),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fopNumber,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _chip(
                      Icons.calendar_today_rounded,
                      fopDate,
                      const Color(0xFF2563EB),
                    ),
                    if (soNumber != '-')
                      _chip(
                        Icons.receipt_long_rounded,
                        soNumber,
                        const Color(0xFF059669),
                      ),
                    _chip(
                      Icons.inventory_2_outlined,
                      '$bomCount BOM',
                      const Color(0xFF7C3AED),
                    ),
                  ],
                ),
                if (description != '-') ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: _isFopExpanded ? 6 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF667085),
                      height: 1.4,
                    ),
                  ),
                ],
                if (!_isFopExpanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ketuk untuk lihat detail BOM & proses',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ],
            ),
          ),
          AnimatedRotation(
            turns: _isFopExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF667085),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBom() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Tidak ada data BOM',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF667085),
        ),
      ),
    );
  }

  Widget _buildBomRow(Map<String, dynamic> bom) {
    final bomCode = _val(bom, ['BOMCode']) ?? '-';
    final bomName = _val(bom, ['BOMName']) ?? '-';
    final qty = _val(bom, ['QTY', 'Qty', 'Quantity']) ?? '-';
    final category = _val(bom, ['Category', 'Cat']) ?? '-';
    final isExpanded = _expandedBoms.contains(bomCode);
    final processes = _processesForBom(bomCode);

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedBoms.remove(bomCode);
              } else {
                _expandedBoms.add(bomCode);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bomCode,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bomName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Qty: $qty',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ),
                          if (category != '-') ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 6),
                          Text(
                            '${processes.length} proses',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF667085),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF667085),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: processes.isEmpty
              ? _buildNoProcess()
              : _buildProcessTracking(processes),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        const Divider(height: 1, color: Color(0xFFE5EAF3)),
      ],
    );
  }

  Widget _buildProcessTracking(List<Map<String, dynamic>> processes) {
    return Container(
      margin: const EdgeInsets.fromLTRB(31, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Antrean Proses',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF667085),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(processes.length, (index) {
                final p = processes[index];
                final processCode = _val(p, ['ProcessCode']) ?? '-';
                final processName = _val(p, ['ProcessName']) ?? '-';
                final statusRaw = _val(p, [
                  'Status',
                  'ProcessStatus',
                  'IsDone',
                ]);
                final isDone =
                    statusRaw == '1' ||
                    statusRaw == 'true' ||
                    statusRaw == 'Done' ||
                    statusRaw == 'Selesai';
                final activeIndex = _firstNotDone(processes);
                final isActive = !isDone && index == activeIndex;
                final isWaiting = !isDone && index > activeIndex;

                final color = isDone
                    ? const Color(0xFF16A34A)
                    : isActive
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFCBD5E1);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF2563EB,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            processCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF344054),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            processName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              height: 1.25,
                              color: isWaiting
                                  ? const Color(0xFF94A3B8)
                                  : color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Berjalan',
                                style: GoogleFonts.poppins(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (index < processes.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 13),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 2,
                              color: index < activeIndex
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFE2E8F0),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: index < activeIndex
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFCBD5E1),
                            ),
                            Container(
                              width: 18,
                              height: 2,
                              color: index < activeIndex
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  int _firstNotDone(List<Map<String, dynamic>> processes) {
    for (int i = 0; i < processes.length; i++) {
      final statusRaw = _val(processes[i], [
        'Status',
        'ProcessStatus',
        'IsDone',
      ]);
      final isDone =
          statusRaw == '1' ||
          statusRaw == 'true' ||
          statusRaw == 'Done' ||
          statusRaw == 'Selesai';
      if (!isDone) return i;
    }
    return processes.length;
  }

  Widget _buildNoProcess() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(31, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EAF3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Text(
              'Belum ada data proses',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw == '-') return '-';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy').format(dt.toLocal());
    } catch (_) {
      return raw;
    }
  }

  String? _val(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final v = map[key];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return null;
  }
}
