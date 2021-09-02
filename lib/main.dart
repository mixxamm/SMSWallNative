import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:telephony/telephony.dart';
import 'package:smswall/generated/l10n.dart';
import 'scanner.dart';
import 'dart:convert';

var connection;

backgroundMessageHandler(SmsMessage message) async {
  print('received in background');
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (prefs.getString("session") != "") {
    var sessieCode = jsonDecode(prefs.getString("session"));
    print(sessieCode);
    await startConnection(sessieCode['url']);
    connection.invoke('SendSMS', args: [message.body, sessieCode['sessie']]);
  }
}

Future<String> startConnection(String url) async {
  print(url);
  connection = HubConnectionBuilder()
      .withUrl(
          url,
          HttpConnectionOptions(
            logging: (level, message) => print(message),
          ))
      .build();
  await connection.start();
  return url;
}

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
  final Telephony telephony = Telephony.instance;
  int _counter = 0;
  String session = '';
  String connectedUrl = '';
  String connected = S.current.not;

  @override
  void initState() {
    super.initState();
    startSmsService();
  }

  void startSmsService() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted)
      listenForSms();
    else {
      // nog handlen
    }
    if (prefs.getString("session") != "") {
      connectWithSessionCode(prefs.getString("session"));
    }
  }

  void listenForSms() {
    telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          connection.invoke("SendSMS", args: [message.body, session]);
        },
        onBackgroundMessage: backgroundMessageHandler);
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void verbindMetSessie() async {
    var sessieCode = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => Scanner()));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("session", sessieCode);
    connectWithSessionCode(sessieCode);
  }

  void connectWithSessionCode(sessieCode) async {
    sessieCode = jsonDecode(sessieCode);
    print(sessieCode);
    String url = await startConnection(sessieCode['url']);
    setState(() {
      connected = '';
      connectedUrl = url;
    });
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
