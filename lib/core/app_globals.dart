import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AppGlobals {
  AppGlobals._();

  static const String _taskListKey = 'task_list';
  static const bool previewCardMode = false;

  static final GlobalKey<NavigatorState> globalNavigatorKey =
      GlobalKey<NavigatorState>();

  // ── Auth / Koneksi ──────────────────────────────────────────
  static String accountID = 'KMS';
  static String objectID = 'KMS';
  static String serverIp = '';

  // ── User ────────────────────────────────────────────────────
  static String userName = 'Admin';
  static String userRole = '';

  // ── App State ───────────────────────────────────────────────
  static bool isConnected = false;

  // ── Finish Refresh Trigger ──────────────────────────────────
  static final StreamController<void> _finishRefreshController =
      StreamController<void>.broadcast();

  static Stream<void> get finishRefreshStream =>
      _finishRefreshController.stream;

  static void triggerFinishRefresh() {
    _finishRefreshController.add(null);
  }

  // ── Finish Count (dari API) ─────────────────────────────────
  static final StreamController<int> _finishCountFromApiController =
      StreamController<int>.broadcast();

  static Stream<int> get finishCountFromApiStream =>
      _finishCountFromApiController.stream;

  static int _finishCountFromApi = 0;
  static int get finishCountFromApi => _finishCountFromApi;

  static void setFinishCount(int count) {
    _finishCountFromApi = count;
    _finishCountFromApiController.add(count);
  }

  // ── Ongoing Auto-Refresh Trigger ────────────────────────────
  static final StreamController<bool> _ongoingTimerController =
      StreamController<bool>.broadcast();

  /// Emit `true` untuk start timer, `false` untuk stop
  static Stream<bool> get ongoingTimerStream => _ongoingTimerController.stream;

  static void startOngoingTimer() => _ongoingTimerController.add(true);
  static void stopOngoingTimer() => _ongoingTimerController.add(false);

  // ── Ongoing Refresh Trigger ─────────────────────────────────
  static final StreamController<void> _ongoingRefreshController =
      StreamController<void>.broadcast();

  /// Emit event ini untuk trigger OngoingView refresh dari luar
  static Stream<void> get ongoingRefreshStream =>
      _ongoingRefreshController.stream;

  static void triggerOngoingRefresh() {
    _ongoingRefreshController.add(null);
  }

  // ── Ongoing Count (dari API) ────────────────────────────────
  static final StreamController<int> _ongoingCountController =
      StreamController<int>.broadcast();

  static Stream<int> get ongoingCountStream => _ongoingCountController.stream;

  static int _ongoingCount = 0;
  static int get ongoingCount => _ongoingCount;

  static void setOngoingCount(int count) {
    _ongoingCount = count;
    _ongoingCountController.add(count);
  }

  // ── Task / Counting List ────────────────────────────────────
  static final StreamController<int> _taskCountController =
      StreamController<int>.broadcast();

  static Stream<int> get taskCountStream => _taskCountController.stream;

  static List<Map<String, dynamic>> _taskList = [];

  static List<Map<String, dynamic>> get taskList => _taskList;

  // ── Finish List ─────────────────────────────────────────────
  static final StreamController<int> _finishCountController =
      StreamController<int>.broadcast();

  static Stream<int> get finishCountStream => _finishCountController.stream;

  static List<Map<String, dynamic>> _finishList = [];

  static List<Map<String, dynamic>> get finishList => _finishList;

  static Future<void> addToFinishList(Map<String, dynamic> item) async {
    _finishList.add(item);
    _finishCountController.add(_finishList.length);
    await _persistFinish();
  }

  static Future<void> clearFinishList() async {
    _finishList.clear();
    _finishCountController.add(0);
    await _persistFinish();
  }

  static Future<void> _persistFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('finish_list', jsonEncode(_finishList));
  }

  static Future<void> loadFinishList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('finish_list');
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _finishList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      _finishCountController.add(_finishList.length);
    }
  }

  /// Load taskList dari SharedPreferences saat app start
  static Future<void> loadTaskList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_taskListKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _taskList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      _taskCountController.add(_taskList.length);
    }
  }

  /// Simpan taskList ke SharedPreferences
  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_taskListKey, jsonEncode(_taskList));
  }

  static set taskList(List<Map<String, dynamic>> value) {
    _taskList = value;
    _taskCountController.add(_taskList.length);
    _persist();
  }

  /// Persist manual — dipakai saat update item by index langsung
  static Future<void> persistTaskList() async {
    await _persist();
    _taskCountController.add(_taskList.length);
  }

  /// Tambah item, notify stream, dan persist
  static Future<void> addTask(Map<String, dynamic> item) async {
    _taskList.add(item);
    _taskCountController.add(_taskList.length);
    await _persist();
  }

  /// Hapus item berdasarkan index, notify stream, dan persist
  static Future<void> removeTaskAt(int index) async {
    _taskList.removeAt(index);
    _taskCountController.add(_taskList.length);
    await _persist();
    if (_taskList.isEmpty) {
      _taskCountController.add(0); // pastikan listener menerima sinyal kosong
    }
  }

  /// Cek apakah SensorID sudah ada di taskList
  static bool isSensorRunning(String sensorID) {
    return _taskList.any((item) => item['SensorID']?.toString() == sensorID);
  }

  /// Hapus item berdasarkan SensorID dan persist
  static Future<void> removeTaskBySensorID(String sensorID) async {
    _taskList.removeWhere((item) => item['SensorID']?.toString() == sensorID);
    _taskCountController.add(_taskList.length);
    await _persist();
    if (_taskList.isEmpty) {
      _taskCountController.add(0);
    }
  }

  /// Reset semua task dan persist
  static Future<void> clearTaskList() async {
    _taskList.clear();
    _taskCountController.add(0);
    await _persist();
  }
}
