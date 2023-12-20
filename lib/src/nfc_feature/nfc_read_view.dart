import 'dart:async';
import 'dart:io' show Platform, sleep;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

class NfcReadView extends StatefulWidget {
  static const routeName = '/nfc_read';

  static const lowRate = '00';
  static const highRate = '02';

  static const mbCtrlDynCode = 'AD020D';
  static const mbLenDynCode = 'AB02';
  static const readMsg = 'AC02';

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
  String? _result;
  String lengthMsg = '';

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

  void readNDEF() async {
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
      if (_tag!.ndefAvailable ?? false) {
        var ndefRecords = await FlutterNfcKit.readNDEFRecords();
        var ndefString = '';
        for (int i = 0; i < ndefRecords.length; i++) {
          ndefString += '${i + 1}: ${ndefRecords[i]}\n';
        }
        setState(() {
          _result = ndefString;
        });
      } else {
        setState(() {
          _result =
              (_tag!.ndefAvailable ?? false ? 'Ndef Unavailable' : 'None');
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        _result = 'error: $e';
        _pooling = false;
      });
    }
  }

  void readMailBox() async {
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
      if (_tag!.type == NFCTagType.iso15693) {
        String isMailboxActive = await FlutterNfcKit.transceive(
            NfcReadView.highRate + NfcReadView.mbCtrlDynCode);
        if (isMailboxActive == '0000') {
          setState(() {
            _result = '$isMailboxActive : Mailbox is inactive';
          });
        } else if (isMailboxActive == '0001') {
          setState(() {
            _result = '$isMailboxActive : Mailbox active but empty';
          });
        } else if (isMailboxActive == '0081') {
          setState(() {
            _result = '$isMailboxActive: Mailbox is ready for a new sequence';
          });
        } else if (isMailboxActive == '0085') {
          String mailboxMsgLength = await FlutterNfcKit.transceive(
              NfcReadView.highRate + NfcReadView.mbLenDynCode);
          if (mailboxMsgLength == '0000') {
            setState(() {
              _result = '$isMailboxActive : Mailbox Msg length null';
            });
          }
          String msg = await FlutterNfcKit.transceive(
              NfcReadView.highRate + NfcReadView.readMsg + mailboxMsgLength);

          setState(() {
            _result =
                '$isMailboxActive: RF_PUT_MSG\nLength: $mailboxMsgLength\nMsg: $msg';
          });
        } else if (isMailboxActive == '0043') {
          String mailboxMsgLength = await FlutterNfcKit.transceive(
              NfcReadView.highRate + NfcReadView.mbLenDynCode);
          if (mailboxMsgLength == '0000') {
            setState(() {
              _result = '$isMailboxActive : Mailbox Msg length null';
            });
          }
          String msg = await FlutterNfcKit.transceive(
              NfcReadView.readMsg + mailboxMsgLength);

          setState(() {
            _result =
                '$isMailboxActive: HOST_PUT_MSG\nLength: $mailboxMsgLength\nMsg: $msg';
          });
        } else {
          setState(() {
            _result = '$isMailboxActive: Mailbox Code Unknown';
          });
        }
      } else {
        setState(() {
          _result = 'Type not supported';
        });
      }
    } catch (e) {
      print(e);
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
    return _availability != NFCAvailability.available
        ? Column(children: [
            const SizedBox(height: 10),
            Center(child: Text('Running on: $_platformVersion')),
            Center(child: const Text('NFC: inactif'))
          ])
        : Column(children: [
            const SizedBox(height: 10),
            Center(
                child: Row(children: [
              Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: !_pooling
                        ? () async {
                            readNDEF();
                          }
                        : null,
                    child: Text(_pooling ? 'Polling ...' : 'Read NDEF'),
                  )),
              Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: !_pooling
                        ? () async {
                            readMailBox();
                          }
                        : null,
                    child: Text(_pooling ? 'Reading ...' : 'Read MailBox'),
                  ))
            ])),
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
                                _tile(
                                    title: 'Transceive Result: ',
                                    content: _result),
                                const Divider(),
                                _tile(title: 'ID: ', content: _tag!.id),
                                const Divider(),
                                _tile(
                                    title: 'Standard: ',
                                    content: _tag!.standard),
                                const Divider(),
                                _tile(title: 'Type: ', content: _tag!.type),
                              ]
                            : <Widget>[
                                Center(
                                    child: Text(_pooling
                                        ? 'Please scan your tag.'
                                        : ''))
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
