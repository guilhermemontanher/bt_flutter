import 'dart:async';

import 'package:bt_flutter/model/bluetooth_item.dart';
import 'package:bt_flutter/pages/bluetooth_page.dart';
import 'package:bt_flutter/pages/bluetooth_page_2.dart';
import 'package:bt_flutter/utils/nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class ListBluetooth extends StatefulWidget {
  @override
  _ListBluetoothState createState() => _ListBluetoothState();
}

class _ListBluetoothState extends State<ListBluetooth> {
  FlutterBlue f = FlutterBlue.instance;

  //List<BluetoothItem> bluetoothList = List<BluetoothItem>();
  List<ScanResult> bluetoothList = List<ScanResult>();

  StreamSubscription<ScanResult> scan;

  var scanOrStop = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scanBluetooth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de dispositivos"),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                if (!scanOrStop) {
                  _scanBluetooth();
                } else {
                  scan.cancel();
                }

                scanOrStop = !scanOrStop;
              })
        ],
      ),
      body: _body(),
    );
  }

  _body() {
    return ListView.builder(
        itemCount: bluetoothList.length,
        itemBuilder: (context, idx) {
          final result = bluetoothList[idx];

          return Container(
            child: InkWell(
              onTap: () {
                _onClickItem(context, result.device);
              },
              onLongPress: () {
                _onLongClickItem(context, result.device);
              },
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: Icon(
                              Icons.bluetooth_audio,
                              color: Colors.blueAccent,
                            ),
                          ),
                          Expanded(
                            flex: 12,
                            child: Text(
                              result.rssi.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 22,
                              ),
                            ),
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Name:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 25,
                            ),
                          ),
                          Text(
                            result.device.name,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "MAC:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 25,
                            ),
                          ),
                          Text(
                            result.device.id.id,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  void _onClickItem(BuildContext context, BluetoothDevice device) {
    scan.cancel();
    //push(context, BluetoothPage(device.name, f, device));
    pushReplacement(context, BluetoothPage2(device.name, f, device));
  }

  void _onLongClickItem(BuildContext context, device) {}

  _scanBluetooth() {
    print("Start scan....");
    setState(() {
      bluetoothList = List<ScanResult>();
    });
    scan = f.scan().listen((scanResult) {
      //if (scanResult.advertisementData.connectable) {
      if (bluetoothList.isEmpty) {
        bluetoothList.add(scanResult);
        /* bluetoothList.add(BluetoothItem(scanResult.device.name,
            scanResult.device.id.id, scanResult.rssi.toString()));*/
      } else {
        var btNoExist = true;
        for (ScanResult d in bluetoothList) {
          if (d.device.id.id == scanResult.device.id.id) {
            btNoExist = false;
          }
        }

        if (btNoExist) {
          if (scanResult.device.name != "") {
            setState(() {
              bluetoothList.add(scanResult);
              /*bluetoothList.add(BluetoothItem(
                  scanResult.device.name +
                      "\n" +
                      scanResult.device.type.toString(),
                  scanResult.device.id.id,
                  scanResult.rssi.toString()));*/
            });
          }
        }
      }
      //}
    });
  }
}
