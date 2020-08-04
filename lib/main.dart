import 'package:flutter/material.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:sms/sms.dart';
import 'scanner.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  String sessie = '';
  String verbondenUrl = '';
  String verbonden = ' niet';
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
    print('verbinding maken');
    await connection.start();
    print('verbinding gemaakt');
    setState(() {
      verbonden = '';
      verbondenUrl = url;
    });
  }

  void listenForSms() {
    SmsReceiver receiver = new SmsReceiver();
    receiver.onSmsReceived.listen((SmsMessage msg) => {
          connection.invoke("SendSMS", args: [msg.body, sessie])
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
      sessie = sessieCode['sessie'];
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
              'U bent$verbonden verbonden met de server.',
            ),
            MaterialButton(
              color: sessie == '' ? Colors.red : Colors.green,
              child: Text((sessie == '' ? 'Verbind' : 'Verbonden') +
                  ' met sessie $sessie'),
              onPressed: () => verbindMetSessie(),
            ),
            Text(
              '$verbondenUrl',
              style: TextStyle(fontWeight: FontWeight.w100),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
