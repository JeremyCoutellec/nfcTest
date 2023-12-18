import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcWriteView extends StatefulWidget {
  static const routeName = '/nfc_write';

  const NfcWriteView({
    super.key,
  });

  @override
  _NfcWriteViewState createState() => _NfcWriteViewState();
}

class _NfcWriteViewState extends State<NfcWriteView> {
  String? _writeResult;
  bool _pooling = false;
  late List<TextEditingController> _textController;

  @override
  void initState() {
    super.initState();
    _textController = [
      TextEditingController.fromValue(const TextEditingValue(text: ''))
    ];
  }

  void writeNfc() async {
    try {
      setState(() {
        _pooling = true;
      });
      NFCTag tag = await FlutterNfcKit.poll();
      setState(() {
        _pooling = false;
      });
      if (tag.type == NFCTagType.mifare_ultralight ||
          tag.type == NFCTagType.mifare_classic ||
          tag.type == NFCTagType.iso15693) {
        List<ndef.NDEFRecord> records = [];
        _textController.forEach((element) {
          records.add(ndef.TextRecord(
              text: element.text,
              encoding: ndef.TextEncoding.values[0],
              language: ('en')));
        });

        await FlutterNfcKit.writeNDEFRecords(records);
        setState(() {
          _writeResult = 'Records sended';
          _textController = [
            TextEditingController.fromValue(const TextEditingValue(text: ''))
          ];
        });
      } else {
        setState(() {
          _writeResult = 'error: NDEF not supported: ${tag.type}';
        });
      }
    } catch (e, stacktrace) {
      setState(() {
        _writeResult = 'error: $e';
        _pooling = false;
      });
      print(stacktrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 40),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  for (int i = 0; i < _textController.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'text'),
                            controller: _textController[i],
                          ),
                        ),
                        if (i == _textController.length - 1)
                          ElevatedButton(
                            child: const Text('+'),
                            onPressed: () {
                              setState(() {
                                _textController.add(TextEditingController());
                              });
                            },
                          )
                        else
                          ElevatedButton(
                            child: const Text('-'),
                            onPressed: () {
                              setState(() {
                                _textController.removeAt(i);
                              });
                            },
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const Divider(),
      const SizedBox(height: 10),
      ElevatedButton(
        onPressed: !_pooling
            ? () async {
                writeNfc();
              }
            : null,
        child: Text(_pooling ? 'Please scan your tag ...' : 'Send'),
      ),
      Expanded(
        flex: 1,
        child: Text(_writeResult != null ? 'Result: $_writeResult' : ''),
      )
    ]);
  }
}
