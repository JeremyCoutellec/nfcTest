import 'dart:async';
import 'dart:io' show Platform, sleep;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcReadView extends StatefulWidget {
  static const routeName = '/nfc_read';

  const NfcReadView({
    super.key,
  });

  @override
  _NfcReadViewState createState() => _NfcReadViewState();
}

class _NfcReadViewState extends State<NfcReadView> {
  String _platformVersion = '';
  NFCAvailability _availability = NFCAvailability.not_supported;
  NFCTag? _tag;
  bool _pooling = false;
  String? _result, _mifareResult;

  @override
  void initState() {
    super.initState();
    _platformVersion =
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    NFCAvailability availability;
    try {
      availability = await FlutterNfcKit.nfcAvailability;
    } on PlatformException {
      availability = NFCAvailability.not_supported;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      // _platformVersion = platformVersion;
      _availability = availability;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void readNfc() async {
    try {
      setState(() {
        _pooling = true;
      });
      NFCTag tag = await FlutterNfcKit.poll();
      setState(() {
        _tag = tag;
        _pooling = false;
      });
      await FlutterNfcKit.setIosAlertMessage("Working on it...");
      _mifareResult = null;
      if (_tag!.standard == "ISO 14443-4 (Type B)") {
        String result1 = await FlutterNfcKit.transceive("00B0950000");
        String result2 =
            await FlutterNfcKit.transceive("00A4040009A00000000386980701");
        setState(() {
          _result = '1: $result1\n2: $result2\n';
        });
      } else if (_tag!.type == NFCTagType.iso18092) {
        String result1 = await FlutterNfcKit.transceive("060080080100");
        setState(() {
          _result = '1: $result1\n';
        });
      } else if (_tag!.ndefAvailable ?? false) {
        var ndefRecords = await FlutterNfcKit.readNDEFRecords();
        var ndefString = '';
        for (int i = 0; i < ndefRecords.length; i++) {
          ndefString += '${i + 1}: ${ndefRecords[i]}\n';
        }
        setState(() {
          _result = ndefString;
        });
      } else if (_tag!.type == NFCTagType.webusb) {
        var r = await FlutterNfcKit.transceive("00A4040006D27600012401");
        setState(() {
          _result = r.toString();
        });
      }
    } catch (e) {
      setState(() {
        _result = 'error: $e';
        _pooling = false;
      });
    }

    // Pretend that we are working
    sleep(new Duration(seconds: 1));
    await FlutterNfcKit.finish(iosAlertMessage: "Finished!");
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 10),
      Center(child: Text('Running on: $_platformVersion')),
      Center(
          child: _availability.name == 'available'
              ? const Text('NFC: actif')
              : const Text('NFC: inactif')),
      const SizedBox(height: 10),
      const SizedBox(height: 10),
      ElevatedButton(
        onPressed: !_pooling
            ? () async {
                readNfc();
              }
            : null,
        child: Text(_pooling ? 'Polling ...' : 'Start polling'),
      ),
      const SizedBox(height: 10),
      const Divider(),
      Expanded(
        flex: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
              child: ListView(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(8),
                  children: _tag != null
                      ? <Widget>[
                          _tile(title: 'ID: ', content: _tag!.id),
                          const Divider(),
                          _tile(title: 'Standard: ', content: _tag!.standard),
                          const Divider(),
                          _tile(title: 'Type: ', content: _tag!.type),
                          const Divider(),
                          _tile(title: 'ATQA: ', content: _tag!.atqa),
                          const Divider(),
                          _tile(title: 'SAK: ', content: _tag!.sak),
                          const Divider(),
                          _tile(
                              title: 'Historical Bytes: ',
                              content: _tag!.historicalBytes),
                          const Divider(),
                          _tile(
                              title: 'Protocol Info: ',
                              content: _tag!.protocolInfo),
                          const Divider(),
                          _tile(
                              title: 'Application Data: ',
                              content: _tag!.applicationData),
                          const Divider(),
                          _tile(
                              title: 'Higher Layer Response: ',
                              content: _tag!.hiLayerResponse),
                          const Divider(),
                          _tile(
                              title: 'Manufacturer: ',
                              content: _tag!.manufacturer),
                          const Divider(),
                          _tile(
                              title: 'System Code: ',
                              content: _tag!.systemCode),
                          const Divider(),
                          _tile(title: 'DSF ID: ', content: _tag!.dsfId),
                          const Divider(),
                          _tile(
                              title: 'NDEF Available: ',
                              content: _tag!.ndefAvailable),
                          const Divider(),
                          _tile(title: 'NDEF Type: ', content: _tag!.ndefType),
                          const Divider(),
                          _tile(
                              title: 'NDEF Writable: ',
                              content: _tag!.ndefWritable),
                          const Divider(),
                          _tile(
                              title: 'NDEF Can Make Read Only: ',
                              content: _tag!.ndefCanMakeReadOnly),
                          const Divider(),
                          _tile(
                              title: 'NDEF Capacity: ',
                              content: _tag!.ndefCapacity),
                          const Divider(),
                          _tile(
                              title: 'Mifare Info: ',
                              content: _tag!.mifareInfo),
                          const Divider(),
                          _tile(title: 'Transceive Result: ', content: _result),
                          const Divider(),
                          _tile(title: 'Bloc Message: ', content: _mifareResult)
                        ]
                      : <Widget>[
                          Center(
                              child:
                                  Text(_pooling ? 'Please scan your tag.' : ''))
                        ])),
        ),
      ),
      const SizedBox(height: 25),
    ]);
  }

  Card _tile({required String title, required dynamic content}) {
    return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            borderRadius: const BorderRadius.all(Radius.circular(12))),
        child: ListTile(
          title: Text(title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              )),
          subtitle: Center(child: Text(content.toString())),
        ));
  }
}
