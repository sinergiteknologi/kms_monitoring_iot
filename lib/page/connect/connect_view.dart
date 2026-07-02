import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:kms_monitoring_iot/page/connect/connect_viewmodel.dart';

class ConnectView extends StackedView<ConnectViewModel> {
  const ConnectView({super.key});

  @override
  Widget builder(
    BuildContext context,
    ConnectViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFF), Color(0xFFF3F5FF), Color(0xFFF8FAFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: Column(
              children: [
                const SizedBox(height: 6),

                /// HERO TOP
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF7F9FF), Color(0xFFF3F5FF)],
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          /// Circle icon
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C63FF,
                                  ).withOpacity(0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFFE9ECFF),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.router_rounded,
                              size: 46,
                              color: Color(0xFF635BFF),
                            ),
                          ),

                          const SizedBox(height: 26),

                          const Text(
                            'KMS Monitoring IoT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 31,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111C63),
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            'Masukkan IP Address server untuk memulai',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF667085),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 22),

                          /// IP Device pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEFFF),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF6D4AFF),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.phone_android_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'IP Device: ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF667085),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  viewModel.deviceIp.isEmpty
                                      ? 'Tidak tersedia'
                                      : viewModel.deviceIp,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF635BFF),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// Dekorasi kiri
                    Positioned(
                      left: 8,
                      top: 110,
                      child: Opacity(
                        opacity: 0.16,
                        child: Icon(
                          Icons.device_hub_rounded,
                          size: 92,
                          color: const Color(0xFF8D95C9).withOpacity(0.6),
                        ),
                      ),
                    ),

                    /// Dekorasi kanan atas (pengganti ilustrasi router)
                    Positioned(
                      right: 6,
                      top: 24,
                      child: Opacity(
                        opacity: 0.22,
                        child: Icon(
                          Icons.wifi_tethering_rounded,
                          size: 92,
                          color: const Color(0xFF8B7BFF).withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                // const SizedBox(height: 26),

                /// CARD FORM
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF0F2F8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2EEFF),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.device_hub_rounded,
                              color: Color(0xFF635BFF),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Koneksi Server',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111C63),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Contoh: 192.168.1.100',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7A84A0),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      Divider(
                        color: Colors.grey.shade200,
                        thickness: 1,
                        height: 1,
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'IP Address Server',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111C63),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFD9DEFF),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: viewModel.ipController,
                          keyboardType: TextInputType.url,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1F2A44),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.language_rounded,
                                color: Color(0xFF5B6BFF),
                                size: 28,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            hintText: '0.0.0.0',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9BA3B8),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xFF1E73FF), Color(0xFF7A3CFF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF5A67FF,
                                ).withOpacity(0.24),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: viewModel.isBusy
                                ? null
                                : () => viewModel.connect(
                                    ipConnect: viewModel.ipController.text,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: viewModel.isBusy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.wifi_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                            label: Text(
                              viewModel.isBusy ? 'Connecting...' : 'Connect',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                /// Footer security
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1.4,
                            color: const Color(0xFFE0E4F5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF6D4AFF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF5B63FF,
                                ).withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 1.4,
                            color: const Color(0xFFE0E4F5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                    ),
                    const Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6D4AFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  ConnectViewModel viewModelBuilder(BuildContext context) => ConnectViewModel();

  @override
  void onViewModelReady(ConnectViewModel viewModel) {
    viewModel.init();
    super.onViewModelReady(viewModel);
  }
}
