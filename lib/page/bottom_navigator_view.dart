import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kms_monitoring_iot/core/app_globals.dart';
import 'package:kms_monitoring_iot/page/connect/connect_viewmodel.dart';
import 'package:kms_monitoring_iot/page/finish/finish_view.dart';
import 'package:kms_monitoring_iot/page/history/history_view.dart';
import 'package:kms_monitoring_iot/page/ongoing_proses/ongoing_view.dart';
import 'package:kms_monitoring_iot/page/task_list/task_list_view.dart';

class BottomNavigatorView extends StatefulWidget {
  const BottomNavigatorView({super.key});

  @override
  State<BottomNavigatorView> createState() => _BottomNavigatorViewState();
}

class _BottomNavigatorViewState extends State<BottomNavigatorView> {
  int selectedIndex = AppGlobals.previewCardMode ? 1 : 0;
  int _taskCount = AppGlobals.ongoingCount;
  int _finishCount = AppGlobals.finishCountFromApi;

  StreamSubscription<int>? _ongoingCountSubscription;
  StreamSubscription<int>? _finishCountSubscription;

  final List<_MenuItem> _menus = const [
    _MenuItem('Task List', Icons.assignment_outlined),
    _MenuItem('On Process', Icons.wifi_tethering_rounded),
    _MenuItem('Finish Process', Icons.check_circle_rounded),
    _MenuItem('Task History', Icons.history_rounded),
  ];

  @override
  void initState() {
    super.initState();

    _ongoingCountSubscription = AppGlobals.ongoingCountStream.listen((count) {
      if (mounted) setState(() => _taskCount = count);
    });

    _finishCountSubscription =
        AppGlobals.finishCountFromApiStream.listen((count) {
      if (mounted) setState(() => _finishCount = count);
    });
  }

  @override
  void dispose() {
    _ongoingCountSubscription?.cancel();
    _finishCountSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FC),
        body: Column(
          children: [
            _buildCompactHeader(context),
            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: const [
                  TaskListView(),
                  OngoingView(),
                  FinishView(),
                  HistoryView(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomMenu(),
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Halo Admin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Selamat bekerja!',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.86),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await ConnectViewModel.clearSavedIp();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/connect');
              }
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 26),
            style: IconButton.styleFrom(
              fixedSize: const Size(52, 52),
              backgroundColor: Colors.white.withOpacity(0.16),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMenu() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_menus.length, (index) {
          final item = _menus[index];
          final selected = selectedIndex == index;
          final badge = index == 1
              ? _taskCount
              : index == 2
                  ? _finishCount
                  : 0;
          final color = index == 2 ? const Color(0xFF16A34A) : const Color(0xFF2563EB);

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => setState(() => selectedIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, color: selected ? color : const Color(0xFF687084), size: 25),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected ? color : const Color(0xFF687084),
                          ),
                        ),
                      ],
                    ),
                    if (badge > 0)
                      Positioned(
                        top: -4,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: index == 2 ? const Color(0xFF16A34A) : Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            '$badge',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  const _MenuItem(this.label, this.icon);
}
