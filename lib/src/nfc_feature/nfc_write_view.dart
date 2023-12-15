import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

import './nfc_text_record.dart';

class NfcWriteView extends StatefulWidget {
  static const routeName = '/nfc_write';

  const NfcWriteView({
    super.key,
  });

  @override
  _NfcWriteViewState createState() => _NfcWriteViewState();
}

class _NfcWriteViewState extends State<NfcWriteView>
    with AutomaticKeepAliveClientMixin {
  bool wantKeepAlive = true;
  NFCTag? _tag;
  String? _writeResult;
  List<ndef.NDEFRecord>? _records;
  bool startWriting = false;

  @override
  void initState() {
    super.initState();
    _records = [];
  }

  void writeNfc() async {
    if (_records!.length != 0) {
      try {
        setState(() {
          startWriting = true;
        });
        NFCTag tag = await FlutterNfcKit.poll();
        setState(() {
          _tag = tag;
        });
        if (tag.type == NFCTagType.mifare_ultralight ||
            tag.type == NFCTagType.mifare_classic ||
            tag.type == NFCTagType.iso15693) {
          await FlutterNfcKit.writeNDEFRecords(_records!);
          setState(() {
            _writeResult = 'OK';
          });
        } else {
          setState(() {
            _writeResult = 'error: NDEF not supported: ${tag.type}';
          });
        }
      } catch (e, stacktrace) {
        setState(() {
          _writeResult = 'error: $e';
        });
        print(stacktrace);
      } finally {
        await FlutterNfcKit.finish();
      }
    } else {
      setState(() {
        _writeResult = 'error: No record';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 40),
      ElevatedButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return SimpleDialog(
                    title: Text("Record Type"),
                    children: <Widget>[
                      SimpleDialogOption(
                        child: Text("Text Record"),
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return NDEFTextRecordSetting();
                          }));
                          if (result != null) {
                            if (result is ndef.TextRecord) {
                              setState(() {
                                _records!.add(result);
                              });
                            }
                          }
                        },
                      ),
                    ]);
              });
        },
        child: Text("Add record"),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Expanded(
            flex: 1,
            child: ListView(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                padding: const EdgeInsets.all(8),
                children: _records!
                    .map((record) =>
                        SizedBox(height: 35, child: Text(record.toString())))
                    .toList())),
      ),
      const SizedBox(height: 10),
      ElevatedButton(
        onPressed: () async {
          if (!startWriting)
            writeNfc();
          else {
            setState(() {
              startWriting = false;
            });
          }
        },
        child: Text(startWriting ? 'Stop writing' : 'Start writing'),
      ),
      const SizedBox(height: 10),
      Expanded(
        flex: 1,
        child: Text('Result: $_writeResult'),
      )
    ]);
  }
}
