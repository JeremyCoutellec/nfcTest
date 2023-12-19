import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

class NfcWriteView extends StatefulWidget {
  static const routeName = '/nfc_write';

  static const mbCtrlDynCode = '02AD020D';
  static const mbLenDynCode = '02AB02';
  static const writeMsg = '02AA02';

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
  late TextEditingController _identifierController;
  late TextEditingController _payloadController;
  late TextEditingController _typeController;
  late int _dropButtonValue;

  @override
  void initState() {
    super.initState();
    _textController = [
      TextEditingController.fromValue(const TextEditingValue(text: ''))
    ];

    _identifierController =
        TextEditingController.fromValue(const TextEditingValue(text: ""));
    _payloadController =
        TextEditingController.fromValue(const TextEditingValue(text: ""));
    _typeController =
        TextEditingController.fromValue(const TextEditingValue(text: ""));
    _dropButtonValue =
        ndef.TypeNameFormat.values.indexOf(ndef.TypeNameFormat.empty);
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
        String isMailboxActive =
            await FlutterNfcKit.transceive(NfcWriteView.mbCtrlDynCode);
        if (isMailboxActive == '0001' || isMailboxActive == '0081') {
          String response = await FlutterNfcKit.transceive(
              NfcWriteView.writeMsg + '01' + '1122');

          setState(() {
            _writeResult = '$isMailboxActive: Written on Mailbox\n$response';
          });
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
                const Divider(),
                Row(children: [
                  Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: !_pooling
                            ? () async {
                                writeNDEF();
                              }
                            : null,
                        child: Text(_pooling
                            ? 'Please scan your tag ...'
                            : 'Write NDEF'),
                      )),
                ]),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: DropdownButton(
                          value: _dropButtonValue,
                          items: const [
                            DropdownMenuItem(
                              value: 0,
                              child: Text('empty'),
                            ),
                            DropdownMenuItem(
                              value: 1,
                              child: Text('nfcWellKnown'),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('media'),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text('absoluteURI'),
                            ),
                            DropdownMenuItem(
                                value: 4, child: Text('nfcExternal')),
                            DropdownMenuItem(
                                value: 5, child: Text('unchanged')),
                            DropdownMenuItem(
                              value: 6,
                              child: Text('unknown'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _dropButtonValue = value as int;
                            });
                          },
                        ),
                      ),
                      Expanded(
                          flex: 1,
                          child: TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'identifier'),
                            validator: (v) {
                              return v!.trim().length % 2 == 0
                                  ? null
                                  : 'length must be even';
                            },
                            controller: _identifierController,
                          )),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'type'),
                          validator: (v) {
                            return v!.trim().length % 2 == 0
                                ? null
                                : 'length must be even';
                          },
                          controller: _typeController,
                        ),
                      ),
                      Expanded(
                          flex: 1,
                          child: TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'payload'),
                            validator: (v) {
                              return v!.trim().length % 2 == 0
                                  ? null
                                  : 'length must be even';
                            },
                            controller: _payloadController,
                          ))
                    ],
                  ),
                ),
                // Center(
                //   child: ElevatedButton(
                //     child: const Text('OK'),
                //     onPressed: () {
                //       if ((_formKey.currentState as FormState).validate()) {
                //         Navigator.pop(
                //             context,
                //             ndef.NDEFRecord(
                //                 tnf: ndef.TypeNameFormat.values[_dropButtonValue],
                //                 type: (_typeController.text).toBytes(),
                //                 id: (_identifierController.text).toBytes(),
                //                 payload: (_payloadController.text).toBytes()));
                //       }
                //     },
                //   ),
                // ),
                Row(children: [
                  Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: !_pooling
                            ? () async {
                                writeMailBox();
                              }
                            : null,
                        child: Text(_pooling
                            ? 'Please scan your tag ...'
                            : 'Write MailBox'),
                      ))
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
