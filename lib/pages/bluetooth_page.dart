import 'dart:async';

import 'package:bt_flutter/model/bluetooth_item.dart';
import 'package:bt_flutter/model/message_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';

class BluetoothPage extends StatefulWidget {
  final String deviceName;
  final FlutterBlue btInstance;
  final BluetoothDevice btDevice;

  const BluetoothPage(this.deviceName, this.btInstance, this.btDevice);

  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  var _scanSubscription;

  String get deviceName => widget.deviceName;

  FlutterBlue get btInstance => widget.btInstance;

  List<MessageItem> listMensagens;

  StreamSubscription<ScanResult> scan;

  StreamSubscription<BluetoothDeviceState> deviceConnection;

  BluetoothDevice connectedDevice;

  static final Guid UUID_SERVICE = Guid("0000ABF0-0000-1000-8000-00805F9B34FB");

  //READ, NOTIFY
  static final Guid UART_NOTIFY = Guid("0000ABF2-0000-1000-8000-00805F9B34FB");
  BluetoothCharacteristic characteristicNotify;

  //WRITE WITHOUT RESPONSE
  static final Guid UART_WRITE = Guid("0000ABF1-0000-1000-8000-00805F9B34FB");
  BluetoothCharacteristic characteristicWrite;

  final _controllerTComando = TextEditingController();

  static final String CONECTANDO = "Conectando...";
  static final String CONECTADO = "Contectado";
  static final String DESCONECTANDO = "Desconectando...";
  static final String DESCONECTADO = "Desconectado";

  String bluetoothState = DESCONECTADO;
  BluetoothDevice device1;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    listMensagens = List<MessageItem>();

    //_searchDevice(device.mac);

    Future(() => _connectToDevice(widget.btDevice));
    //_connect(widget.btDevice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(deviceName),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.bluetooth_disabled),
            onPressed: () {
              deviceConnection.cancel();
            },
          ),
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {
              _connectToDevice(device1);
              /*setState(() {
                listMensagens.clear();
              });*/
            },
          ),
        ],
      ),
      body: _body(),
    );
  }

  _body() {
    return Column(
      children: <Widget>[
        Text("Estado: $bluetoothState"),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(
                width: 250,
                child: TextFormField(
                  controller: _controllerTComando,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(hintText: "Digite um comando"),
                ),
              ),
              RaisedButton(
                child: Text("Enviar"),
                onPressed: () {
                  if (_controllerTComando.text.isNotEmpty) {
                    _write(_controllerTComando.text + "\r\n");
                    setState(() {
                      listMensagens.add(
                          MessageItem(_controllerTComando.text + "\r\n", true));
                    });
                  }
                  SystemChannels.textInput.invokeMethod("TextInput.hide");
                },
              )
            ],
          ),
        ),
        _list()
      ],
    );
  }

  _list() {
    return Expanded(
      child: ListView.builder(
          itemCount: listMensagens.length,
          itemBuilder: (context, idx) {
            final item = listMensagens[idx];

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment:
                    item.isTx ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(5),
                    width: item.msg.length > 60 ? 280 : 200,
                    color:
                        item.isTx ? Colors.greenAccent[100] : Colors.orange[50],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.isTx ? "You" : deviceName,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              color: item.isTx ? Colors.teal : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Text(
                          item.msg,
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  _searchDevice(String mac) {
    if (btInstance != null) {
      print("MATHEUS: instancia blue nao nula");
    } else {
      print("MATHEUS: Instancia nula");
    }

    scan = btInstance.scan().listen((ScanResult scanResult) {
      if (mac == scanResult.device.id.id) {
        scan.cancel();
        print("MATHEUS: device encontrado!");
        setState(() {
          device1 = scanResult.device;
        });
      }
    });
  }

  _connectToDevice(BluetoothDevice device) {
    if (device != null) {
      deviceConnection =
          FlutterBlue.instance.connect(device, autoConnect: false).listen((s) {
        String estado;

        print("_connectToDevice: $s");

        if (s == BluetoothDeviceState.connecting) {
          estado = CONECTANDO;
        } else if (s == BluetoothDeviceState.connected) {
          estado = CONECTADO;
          print("_connectToDevice - CONECTADO");
          connectedDevice = device;
          _discoverServices();
        } else if (s == BluetoothDeviceState.disconnecting) {
          estado = DESCONECTANDO;
        } else if (s == BluetoothDeviceState.disconnected) {
          estado = DESCONECTADO;
          print("_connectToDevice - DESCONECTADO!!");
        }

        setState(() {
          bluetoothState = estado;
        });
      });
    } else {
      print("Device NULO!!!");
    }
  }

  _discoverServices() async {
    List<BluetoothService> services = await connectedDevice.discoverServices();
    services.forEach((service) {
      if (service.uuid == UUID_SERVICE) {
        print("SERVICE ENCONTRADO: _UUID_SERVICE");
        _discoverCharacteristics(service);
      } else {
        print("OUTRO SERVICE: " + service.uuid.toString());
      }
    });
  }

  _discoverCharacteristics(BluetoothService service) async {
    var characteristics = service.characteristics;
    for (BluetoothCharacteristic c in characteristics) {
      if (c.uuid == UART_NOTIFY) {
        characteristicNotify = c;
        _read();
      } else if (c.uuid == UART_WRITE) {
        characteristicWrite = c;
      }
      List<int> value = await connectedDevice.readCharacteristic(c);
      //var s = String.fromCharCodes(value);
      print(value);
      print("*******");
    }
  }

  _write(String msg) async {
    await connectedDevice.writeCharacteristic(
        characteristicWrite, msg.codeUnits);
  }

  _read() async {
    await connectedDevice.setNotifyValue(characteristicNotify, true);
    String buffer = "";
    connectedDevice.onValueChanged(characteristicNotify).listen((value) {
      var s = String.fromCharCodes(value);

      print("aaaa $value");

      buffer += s;

      if (buffer.contains("\r\n")) {
        setState(() {
          listMensagens.add(MessageItem(buffer, false));
        });
        buffer = "";
      }
    });
  }

  @override
  void setState(fn) {
    // TODO: implement setState
    if (this.mounted) {
      super.setState(fn);
    }
  }
}
