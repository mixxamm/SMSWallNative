import 'package:flutter/material.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:sms/sms.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
  String verbonden = ' niet';
  final connection = HubConnectionBuilder()
      .withUrl(
          'http://10.0.2.2:49368/smshub',
          HttpConnectionOptions(
            logging: (level, message) => print(message),
          ))
      .build();

  @override
  void initState() {
    super.initState();
    startConnection();
    listenForSms();
  }

  void startConnection() async {
    print('verbinding maken');
    await connection.start();
    print('verbinding gemaakt');
    setState(() {
      verbonden = '';
    });
  }

  void listenForSms() {
    SmsReceiver receiver = new SmsReceiver();
    receiver.onSmsReceived.listen((SmsMessage msg) => {
          connection.invoke("SendSMS", args: [msg.body])
        });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
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
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
