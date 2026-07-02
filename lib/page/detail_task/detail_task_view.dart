import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kms_monitoring_iot/components/styles.dart';
import 'package:stacked/stacked.dart';
import 'package:kms_monitoring_iot/page/detail_task/detail_task_viewmodel.dart';

class DetailTaskView extends StatefulWidget {
  final String bomCode;
  const DetailTaskView({super.key, required this.bomCode});

  @override
  State<DetailTaskView> createState() => _DetailTaskViewState();
}

class _DetailTaskViewState extends State<DetailTaskView> {
  int selectedIndex = 0;
  final ScrollController _tabScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabScrollController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : Colors.black12;
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade50;
    return ViewModelBuilder<DetailTaskViewModel>.reactive(
      viewModelBuilder: () => DetailTaskViewModel(bomCode: widget.bomCode),
      builder: (context, vm, child) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              Scaffold(
                backgroundColor: const Color.fromARGB(234, 255, 255, 255),
                appBar: AppBar(
                  title: Text(
                    'Detail Task',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  centerTitle: false,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                ),
                body: Column(
                  children: [
                    SizedBox(height: 16),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.8),
                            Colors.white.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SingleChildScrollView(
                            controller: _tabScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(vm.taskList.length, (
                                index,
                              ) {
                                bool isSelected = selectedIndex == index;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index < vm.taskList.length - 1
                                        ? 6
                                        : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedIndex = index;
                                      });
                                    },
                                    child: Container(
                                      height: 40,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? LinearGradient(
                                                colors: [
                                                  Color(0xFF667EEA),
                                                  Color(0xFF764BA2),
                                                ],
                                              )
                                            : null,
                                        color: isSelected
                                            ? null
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Color(
                                                    0xFF667EEA,
                                                  ).withOpacity(0.4),
                                                  blurRadius: 12,
                                                  offset: Offset(0, 4),
                                                  spreadRadius: 0,
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Center(
                                        child: Text(
                                          vm.taskList[index]['ProcessName']
                                                  ?.toString() ??
                                              '-',
                                          style: GoogleFonts.poppins(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey[600],
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            fontSize: 12,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          SizedBox(height: 6),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (!_tabScrollController.hasClients) {
                                return Container(
                                  height: 6,
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }
                              final pos = _tabScrollController.position;
                              final maxScroll = pos.maxScrollExtent;
                              final offset = _tabScrollController.offset;
                              final ratio = maxScroll > 0
                                  ? (offset / maxScroll).clamp(0.0, 1.0)
                                  : 0.0;
                              final viewport = pos.viewportDimension;
                              final extent = maxScroll + viewport;
                              final thumbRatio = extent > 0
                                  ? (viewport / extent).clamp(0.1, 1.0)
                                  : 1.0;
                              final trackWidth = constraints.maxWidth;
                              final thumbWidth = (trackWidth * thumbRatio)
                                  .clamp(15.0, trackWidth);

                              final thumbStart =
                                  (trackWidth - thumbWidth) * ratio;
                              return Container(
                                height: 3,
                                margin: EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      left: thumbStart,
                                      child: Container(
                                        width: thumbWidth,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: Color(
                                            0xFF667EEA,
                                          ).withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF667EEA).withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, -5),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                          ),
                          child: IndexedStack(
                            key: ValueKey<int>(selectedIndex),
                            index: selectedIndex,
                            children: vm.taskList.map((task) {
                              return Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.confirmation_number_outlined,
                                          size: 16,
                                          color: Color(0xFF667EEA),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'FOP Number',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF667EEA,
                                            ).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            task['FOPNumber']?.toString() ??
                                                '-',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF667EEA),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      task['BOMName']?.toString() ?? '-',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.widgets_outlined,
                                          size: 16,
                                          color: Colors.grey[700],
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            task['ProdCode']?.toString() ?? '-',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.qr_code_2_rounded,
                                          size: 16,
                                          color: Colors.grey[700],
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            task['BOMCode']?.toString() ?? '-',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: vm
                                          .textEditingControllers[selectedIndex],
                                      style: GoogleFonts.poppins(fontSize: 15),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Jumlah',
                                        hintStyle: GoogleFonts.poppins(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.45),
                                          fontSize: 15,
                                        ),

                                        filled: true,
                                        fillColor: fillColor,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 16,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                            width: 1.2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.isBusy)
                const Stack(
                  children: [
                    ModalBarrier(
                      dismissible: false,
                      color: const Color.fromARGB(118, 0, 0, 0),
                    ),
                    Center(child: loadingSpinWhiteSizeBig),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
