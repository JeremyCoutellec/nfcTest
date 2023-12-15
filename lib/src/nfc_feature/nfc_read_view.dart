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

class _NfcReadViewState extends State<NfcReadView>
    with AutomaticKeepAliveClientMixin {
  bool wantKeepAlive = true;
  String _platformVersion = '';
  NFCAvailability _availability = NFCAvailability.not_supported;
  NFCTag? _tag;
  String? _result, _mifareResult;

  @override
  void initState() {
    super.initState();
    _platformVersion =
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    initPlatformState();
    startPolling();
  }

  void startPolling() async {
    while (true) {
      await readNfc();
      // Delay between polls (adjust as needed)
      await Future.delayed(Duration(seconds: 1));
    }
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

  Future<void> readNfc() async {
    Completer<void> completer = Completer<void>();
    try {
      NFCTag tag = await FlutterNfcKit.poll();
      setState(() {
        _tag = tag;
      });
      _mifareResult = null;
      if (tag.standard == "ISO 14443-4 (Type B)") {
        String result1 = await FlutterNfcKit.transceive("00B0950000");
        String result2 =
            await FlutterNfcKit.transceive("00A4040009A00000000386980701");
        setState(() {
          _result = '1: $result1\n2: $result2\n';
        });
      } else if (tag.type == NFCTagType.iso18092) {
        String result1 = await FlutterNfcKit.transceive("060080080100");
        setState(() {
          _result = '1: $result1\n';
        });
      } else if (tag.ndefAvailable ?? false) {
        var ndefRecords = await FlutterNfcKit.readNDEFRecords();
        var ndefString = '';
        for (int i = 0; i < ndefRecords.length; i++) {
          ndefString += '${i + 1}: ${ndefRecords[i]}\n';
        }
        setState(() {
          _result = ndefString;
        });
      } else if (tag.type == NFCTagType.webusb) {
        var r = await FlutterNfcKit.transceive("00A4040006D27600012401");
        print(r);
      }
      completer.complete();
    } catch (e) {
      setState(() {
        _result = 'error: $e';
      });
      completer.completeError(e);
    }

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 20),
      Text('Running on: $_platformVersion\nNFC: $_availability'),
      const SizedBox(height: 10),
      Expanded(
        flex: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              children: _tag != null
                  ? <Widget>[
                      SizedBox(height: 35, child: Text('ID: ${_tag!.id}')),
                      SizedBox(
                          height: 35,
                          child: Text('Standard: ${_tag!.standard}')),
                      SizedBox(height: 35, child: Text('Type: ${_tag!.type}')),
                      SizedBox(height: 35, child: Text('ATQA: ${_tag!.atqa}')),
                      SizedBox(height: 35, child: Text('SAK: ${_tag!.sak}')),
                      SizedBox(
                          height: 35,
                          child: Text(
                              'Historical Bytes: ${_tag!.historicalBytes}')),
                      SizedBox(
                          height: 35,
                          child: Text('Protocol Info: ${_tag!.protocolInfo}')),
                      SizedBox(
                          height: 35,
                          child: Text(
                              'Application Data: ${_tag!.applicationData}')),
                      SizedBox(
                          height: 35,
                          child: Text(
                              'Higher Layer Response: ${_tag!.hiLayerResponse}')),
                      SizedBox(
                          height: 35,
                          child: Text('Manufacturer: ${_tag!.manufacturer}')),
                      SizedBox(
                          height: 35,
                          child: Text('System Code: ${_tag!.systemCode}')),
                      SizedBox(
                          height: 35, child: Text('DSF ID: ${_tag!.dsfId}')),
                      SizedBox(
                          height: 35,
                          child:
                              Text('NDEF Available: ${_tag!.ndefAvailable}')),
                      SizedBox(
                          height: 35,
                          child: Text('NDEF Type: ${_tag!.ndefType}')),
                      SizedBox(
                          height: 35,
                          child: Text('NDEF Writable: ${_tag!.ndefWritable}')),
                      SizedBox(
                          height: 35,
                          child: Text(
                              'NDEF Can Make Read Only: ${_tag!.ndefCanMakeReadOnly}')),
                      SizedBox(
                          height: 35,
                          child: Text('NDEF Capacity: ${_tag!.ndefCapacity}')),
                      SizedBox(
                          height: 35,
                          child: Text('Mifare Info: ${_tag!.mifareInfo}')),
                      Expanded(
                          flex: 1,
                          child: Text('Transceive Result: ${_result}')),
                      SizedBox(
                          height: 35,
                          child: Text('Block Message: ${_mifareResult}'))
                    ]
                  : <Widget>[const Text('Please scan your tag.')]),
        ),
      ),
      const SizedBox(height: 10),
    ]);
  }
}
