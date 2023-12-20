import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcWriteView extends StatefulWidget {
  static const routeName = '/nfc_write';

  static const lowRate = '00';
  static const highRate = '02';

  static const mbCtrlDynCode = 'AD020D';
  static const mbLenDynCode = 'AB02';
  static const writeMsg = 'AA02';

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
  late TextEditingController _lengthController;
  late TextEditingController _msgController;

  @override
  void initState() {
    super.initState();
    _textController = [
      TextEditingController.fromValue(const TextEditingValue(text: ''))
    ];

    _lengthController = TextEditingController();
    _msgController = TextEditingController();
  }

  void writeNDEF() async {
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

  void writeMailBox() async {
    try {
      setState(() {
        _pooling = true;
      });
      NFCTag tag = await FlutterNfcKit.poll();
      setState(() {
        _pooling = false;
      });
      if (tag.type == NFCTagType.iso15693) {
        String isMailboxActive = await FlutterNfcKit.transceive(
            NfcWriteView.highRate + NfcWriteView.mbCtrlDynCode);
        if (isMailboxActive == '0001' ||
            isMailboxActive == '0043' ||
            isMailboxActive == '0081') {
          String length = _lengthController.text;
          String msg = _msgController.text;
          if ((msg.length / 2) != (int.parse(length) + 1)) {
            setState(() {
              _writeResult = 'Message length has to be equal to length given';
            });
          } else {
            length = length.padLeft(2, '0');
            String response = await FlutterNfcKit.transceive(
                NfcWriteView.highRate + NfcWriteView.writeMsg + length + msg);

            setState(() {
              _writeResult = '$isMailboxActive: Written on Mailbox\n$response';
            });
          }
        } else {
          setState(() {
            _writeResult = '$isMailboxActive: Mailbox Code Unknown';
          });
        }
      } else {
        setState(() {
          _writeResult = 'Type not supported';
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
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints viewportConstraints) {
      return SingleChildScrollView(
          child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: IntrinsicHeight(
                  child: Column(children: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            for (int i = 0; i < _textController.length; i++)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                          labelText: 'text'),
                                      controller: _textController[i],
                                    ),
                                  ),
                                  if (i == _textController.length - 1)
                                    ElevatedButton(
                                      child: const Text('+'),
                                      onPressed: () {
                                        setState(() {
                                          _textController
                                              .add(TextEditingController());
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
                    ])),
                Row(children: [
                  Expanded(
                      flex: 1,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: ElevatedButton(
                            onPressed: !_pooling
                                ? () async {
                                    writeNDEF();
                                  }
                                : null,
                            child: Text(_pooling
                                ? 'Please scan your tag ...'
                                : 'Write NDEF'),
                          ))),
                ]),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                        flex: 1,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: TextFormField(
                                controller: _lengthController,
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                decoration: const InputDecoration(
                                  labelText: "Length",
                                )))),
                    Expanded(
                        flex: 2,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'Msg'),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              controller: _msgController,
                            ))),
                  ],
                ),
                Row(children: [
                  Expanded(
                      flex: 1,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: ElevatedButton(
                            onPressed: !_pooling
                                ? () async {
                                    writeMailBox();
                                  }
                                : null,
                            child: Text(_pooling
                                ? 'Please scan your tag ...'
                                : 'Write MailBox'),
                          )))
                ]),
                Expanded(
                  flex: 1,
                  child:
                      Text(_writeResult != null ? 'Result: $_writeResult' : ''),
                )
              ]))));
    });
  }
}
