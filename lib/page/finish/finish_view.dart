import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kms_monitoring_iot/core/app_globals.dart';
import 'package:kms_monitoring_iot/page/finish/finish_viewmodel.dart';
import 'package:stacked/stacked.dart';

class FinishView extends StatelessWidget {
  const FinishView({super.key});

  List<Map<String, dynamic>> _items(FinishViewModel vm) {
    if (vm.finishList.isNotEmpty) return vm.finishList;
    if (!AppGlobals.previewCardMode) return [];
    return [
      {
        'SensorName': 'MESIN-PREVIEW-01',
        'RefNumber': 'FOP-PREVIEW-001',
        'ProcesID': 'PROC-20260529-001',
        'CustomerName': 'PT. Sinar Abadi',
        'ProductCode': 'PRD-001',
        'ProductQTY': '1,200 PCS',
        'StartDate': '2026-05-29T15:20:00',
        'EndDate': '2026-05-29T16:45:00',
        'CountValue': 128,
        'AdjustValue': 12,
        'TotalCount': 140,
      },
      {
        'SensorName': 'MESIN-PREVIEW-02',
        'RefNumber': 'FOP-PREVIEW-002',
        'ProcesID': 'PROC-20260529-002',
        'CustomerName': 'PT. Cahaya Makmur',
        'ProductCode': 'PRD-002',
        'ProductQTY': '800 PCS',
        'StartDate': '2026-05-29T15:35:00',
        'EndDate': '2026-05-29T16:10:00',
        'CountValue': 75,
        'AdjustValue': -5,
        'TotalCount': 70,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<FinishViewModel>.reactive(
      viewModelBuilder: () => FinishViewModel(),
      onViewModelReady: (vm) => vm.getFinishList(),
      builder: (context, vm, child) {
        final items = _items(vm);
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: [
                _HeaderRow(
                  title: 'Daftar Finish',
                  subtitle: 'Task yang sudah selesai',
                ),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  _EmptyFinish(onRefresh: vm.getFinishList)
                else
                  ...items.map((e) => _FinishCard(item: e)).toList(),
              ],
            ),
            Positioned(
              top: 0,
              right: 18,
              child: _FloatingRefresh(onTap: vm.getFinishList),
            ),
            if (vm.isBusy) const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeaderRow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list_rounded, size: 18),
          label: Text(
            'Filter',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            side: BorderSide(color: Colors.grey.shade200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _FinishCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _FinishCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final adjust = _toInt(item['AdjustValue']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                  ),
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withOpacity(0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'FINISHED',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _v(item, ['SensorName', 'ObjectCode'], 'COUNTING SENSOR'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Proses selesai',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: Color(0xFF16A34A),
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  decoration: _innerBox(),
                  child: Column(
                    children: [
                      _InfoLine(
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF7C3AED),
                        label: 'Reference Number',
                        value: _v(item, ['RefNumber', 'FOPNumber'], '-'),
                      ),
                      const Divider(height: 1, indent: 52),
                      _InfoLine(
                        icon: Icons.assignment_outlined,
                        color: const Color(0xFF2563EB),
                        label: 'Process ID',
                        value: _v(item, ['ProcesID', 'ProcessID'], '-'),
                      ),
                      const Divider(height: 1, indent: 52),
                      _InfoLine(
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFFF59E0B),
                        label: 'Product',
                        value: _v(item, [
                          'Product',
                          'ProductCode',
                          'ProdCode',
                          'ProductName',
                          'ItemCode',
                        ], '-'),
                      ),
                      const Divider(height: 1, indent: 52),
                      _InfoLine(
                        icon: Icons.play_circle_outline_rounded,
                        color: const Color(0xFF10B981),
                        label: 'Start Date',
                        value: _fmt(item['StartDate']),
                      ),
                      const Divider(height: 1, indent: 52),
                      _InfoLine(
                        icon: Icons.stop_circle_outlined,
                        color: const Color(0xFFEF4444),
                        label: 'End Date',
                        value: _fmt(item['EndDate']),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Container(
                  decoration: _innerBox(),
                  child: Column(
                    children: [
                      _MetricLine(
                        label: 'Counting',
                        value: _v(item, ['CountValue'], '0'),
                        color: const Color(0xFF2563EB),
                        icon: Icons.sensors_rounded,
                      ),
                      const Divider(height: 1),
                      _MetricLine(
                        label: 'Adjust Value',
                        value: '${adjust >= 0 ? '+' : ''}$adjust',
                        color: adjust < 0
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF16A34A),
                        icon: Icons.auto_fix_high_rounded,
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAFBF1),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Counting',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF15803D),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _v(item, ['TotalCount', 'TotalCounting'], '0'),
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _InfoLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MetricLine({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingRefresh extends StatelessWidget {
  final VoidCallback onTap;
  const _FloatingRefresh({required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
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
      child: const Icon(
        Icons.refresh_rounded,
        color: Color(0xFF16A34A),
        size: 32,
      ),
    ),
  );
}

class _EmptyFinish extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyFinish({required this.onRefresh});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 44,
          color: Color(0xFF94A3B8),
        ),
        Text(
          'Belum ada finish process',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
        TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Refresh'),
        ),
      ],
    ),
  );
}

BoxDecoration _cardDecoration({double radius = 24}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0xFFE2E8F0)),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ],
);
BoxDecoration _innerBox() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: const Color(0xFFE2E8F0)),
);
String _v(Map<String, dynamic> item, List<String> keys, String fallback) {
  for (final k in keys) {
    final v = item[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
  }
  return fallback;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _fmt(dynamic value) {
  final s = value?.toString() ?? '';
  if (s.isEmpty || s == 'null' || s == '-') return '-';
  try {
    return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(s));
  } catch (_) {
    return s;
  }
}
