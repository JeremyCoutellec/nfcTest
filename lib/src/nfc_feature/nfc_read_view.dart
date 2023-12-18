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
  bool startPooling = false;

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

  void readNfc() async {
    try {
      setState(() {
        startPooling = true;
      });
      NFCTag tag = await FlutterNfcKit.poll();
      setState(() {
        _tag = tag;
      });
      await FlutterNfcKit.setIosAlertMessage("Working on it...");
      _mifareResult = null;
      if (tag.standard == "ISO 14443-4 (Type B)") {
        String result1 = await FlutterNfcKit.transceive("00B0950000");
        String result2 =
            await FlutterNfcKit.transceive("00A4040009A00000000386980701");
        setState(() {
          _result = '1: $result1\n2: $result2\n';
          startPooling = false;
        });
      } else if (tag.type == NFCTagType.iso18092) {
        String result1 = await FlutterNfcKit.transceive("060080080100");
        setState(() {
          _result = '1: $result1\n';
          startPooling = false;
        });
      } else if (tag.ndefAvailable ?? false) {
        var ndefRecords = await FlutterNfcKit.readNDEFRecords();
        var ndefString = '';
        for (int i = 0; i < ndefRecords.length; i++) {
          ndefString += '${i + 1}: ${ndefRecords[i]}\n';
        }
        setState(() {
          _result = ndefString;
          startPooling = false;
        });
      } else if (tag.type == NFCTagType.webusb) {
        var r = await FlutterNfcKit.transceive("00A4040006D27600012401");
        print(r);
      }
    } catch (e) {
      setState(() {
        startPooling = false;
        _result = 'error: $e';
      });
    }

    // Pretend that we are working
    sleep(new Duration(seconds: 1));
    await FlutterNfcKit.finish(iosAlertMessage: "Finished!");
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 20),
      Center(child: Text('Running on: $_platformVersion')),
      Center(child: Text('NFC: $_availability')),
      const SizedBox(height: 10),
      ElevatedButton(
        onPressed: () async {
          if (!startPooling) {
            readNfc();
          } else {
            setState(() {
              startPooling = false;
            });
          }
        },
        child: Text(startPooling ? 'Stop polling' : 'Start polling'),
      ),
      const SizedBox(height: 10),
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
                          _tile(title: 'Standard: ', content: _tag!.standard),
                          _tile(title: 'Type: ', content: _tag!.type),
                          _tile(title: 'ATQA: ', content: _tag!.atqa),
                          _tile(title: 'SAK: ', content: _tag!.sak),
                          _tile(
                              title: 'Historical Bytes: ',
                              content: _tag!.historicalBytes),
                          _tile(
                              title: 'Protocol Info: ',
                              content: _tag!.protocolInfo),
                          _tile(
                              title: 'Application Data: ',
                              content: _tag!.applicationData),
                          _tile(
                              title: 'Higher Layer Response: ',
                              content: _tag!.hiLayerResponse),
                          _tile(
                              title: 'Manufacturer: ',
                              content: _tag!.manufacturer),
                          _tile(
                              title: 'System Code: ',
                              content: _tag!.systemCode),
                          _tile(title: 'DSF ID: ', content: _tag!.dsfId),
                          _tile(
                              title: 'NDEF Available: ',
                              content: _tag!.ndefAvailable),
                          _tile(title: 'NDEF Type: ', content: _tag!.ndefType),
                          _tile(
                              title: 'NDEF Writable: ',
                              content: _tag!.ndefWritable),
                          _tile(
                              title: 'NDEF Can Make Read Only: ',
                              content: _tag!.ndefCanMakeReadOnly),
                          _tile(
                              title: 'NDEF Capacity: ',
                              content: _tag!.ndefCapacity),
                          _tile(
                              title: 'Mifare Info: ',
                              content: _tag!.mifareInfo),
                          _tile(title: 'Transceive Result: ', content: _result),
                          _tile(title: 'Bloc Message: ', content: _mifareResult)
                        ]
                      : <Widget>[const Text('Please scan your tag.')])),
        ),
      ),
      const SizedBox(height: 10),
    ]);
  }

  ListTile _tile({required String title, required dynamic content}) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          )),
      subtitle: Center(child: Text(content.toString())),
    );
  }
}
