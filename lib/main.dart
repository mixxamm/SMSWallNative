import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:sms/sms.dart';
import 'package:smswall/generated/l10n.dart';
import 'scanner.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      title: 'SMSWall',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'SMSWall'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String session = '';
  String connectedUrl = '';
  String connected = S.current.not;
  var connection;

  @override
  void initState() {
    super.initState();
    listenForSms();
  }

  void startConnection(String url) async {
    print(url);
    connection = HubConnectionBuilder()
        .withUrl(
            url,
            HttpConnectionOptions(
              logging: (level, message) => print(message),
            ))
        .build();
    await connection.start();
    setState(() {
      connected = '';
      connectedUrl = url;
    });
  }

  void listenForSms() {
    SmsReceiver receiver = new SmsReceiver();
    receiver.onSmsReceived.listen((SmsMessage msg) => {
          connection.invoke("SendSMS", args: [msg.body, session])
        });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void verbindMetSessie() async {
    var sessieCode = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => Scanner()));
    sessieCode = jsonDecode(sessieCode);
    print(sessieCode);
    startConnection(sessieCode['url']);
    setState(() {
      session = sessieCode['sessie'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              S.of(context).uBentVerbondenMetDeServer(connected),
            ),
            MaterialButton(
              color: session == '' ? Colors.red : Colors.green,
              child: Text((session == ''
                      ? S.of(context).connect
                      : S.of(context).connected) +
                  S.of(context).withSession(session)),
              onPressed: () => verbindMetSessie(),
            ),
            Text(
              '$connectedUrl',
              style: TextStyle(fontWeight: FontWeight.w100),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
