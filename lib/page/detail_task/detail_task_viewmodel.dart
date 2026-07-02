import 'package:flutter/material.dart';
import 'package:kms_monitoring_iot/service/api_services.dart';
import 'package:stacked/stacked.dart';

class DetailTaskViewModel extends FutureViewModel {
  String? bomCode;
  DetailTaskViewModel({required this.bomCode});
  final ApiServices _apiServices = ApiServices();
  List<TextEditingController> textEditingControllers = [];
  List<dynamic> taskList = [];

  getData() async {
    setBusy(true);
    print("bomCode : $bomCode");
    try {
      final response = await _apiServices.post('/getDetailTaskList', {
        'host': 'IMPLEMENTSERVER',
        'dbName': 'VenusERP20',
        'BOMCode': bomCode,
      });
      print("response : $response");
      if (response['status'] == true) {
        textEditingControllers = List.generate(response['data'].length, (index) => TextEditingController());
        taskList = response['data'];
      } else {
        throw response['message'];
      }
    } catch (e) {
      print("error : $e");
      setBusy(false);
    } finally {
      setBusy(false);
    }
  }

  @override
  Future<void> futureToRun() async {
    await getData();
  }
}
