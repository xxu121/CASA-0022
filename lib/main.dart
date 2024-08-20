import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mailer/mailer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Lab Freezer', // Update the app title here
      theme: ThemeData(useMaterial3: false),
      home: AuthenticationScreen(),
    );
  }
}

Map<String, String> registeredUsers = {'admin': 'admin'};

class AuthenticationScreen extends StatefulWidget {
  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool isLogin = true; // To toggle between Login and SignUp screen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Login' : 'Sign Up')),
      body: isLogin ? LoginPage(onToggle: toggle) : SignUpPage(onToggle: toggle),
    );
  }

  void toggle() {
    setState(() {
      isLogin = !isLogin;
    });
  }
}

class LoginPage extends StatelessWidget {
  final VoidCallback onToggle;

  LoginPage({required this.onToggle});

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login(BuildContext context) {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Username and password cannot be empty.')));
      return;
    }

    if (registeredUsers.containsKey(username) && registeredUsers[username] == password) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Incorrect username or password.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password', suffixIcon: Icon(Icons.visibility_off)),
            obscureText: true,
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: () => _login(context), child: Text('Login')),
          TextButton(onPressed: onToggle, child: Text('Don’t have an account? Sign up')),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    FreezerScreen(),
    ChartScreen(),
    ContactInfoScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(
        //title: const Text('My lab freezer'), // Update AppBar title for HomeScreen
      //),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.ac_unit),
            label: 'Freezer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Chart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contact',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class FreezerScreen extends StatefulWidget {
  @override
  _FreezerScreenState createState() => _FreezerScreenState();
}

class _FreezerScreenState extends State<FreezerScreen> {
  final client = MqttServerClient('mqtt.cetools.org', 'student');
  List<String> temperatures = ['N/A', 'N/A', 'N/A'];  // Initialize temperatures for three freezers

  @override
  void initState() {
    super.initState();
    setupMQTTClient();
  }

  Future<void> setupMQTTClient() async {
    client.port = 1884;
    client.setProtocolV311();
    client.keepAlivePeriod = 30;
    const username = 'student';
    const password = 'ce2021-mqtt-forget-whale';

    try {
      await client.connect(username, password);
    } catch (e) {
      print('Client exception - $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Mosquitto client connected');
      client.subscribe('student/CASA0022/ucfnxxu/freezer temperature 3', MqttQos.atMostOnce);
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        if (c != null && c.isNotEmpty) {
          final MqttReceivedMessage<MqttMessage?> message = c.first;
          final MqttPublishMessage recMess = message.payload as MqttPublishMessage;
          if (message.topic == 'student/CASA0022/ucfnxxu/freezer temperature 3') {
            final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
            setState(() {
              temperatures[2] = pt;  // Update only Freezer 3's temperature
            });
          }
        }
      });
    } else {
      print('ERROR: Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
      client.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Freezer Information'), // Adding AppBar with a title
        centerTitle: true, // Centers the title, adjust according to your design preference
        backgroundColor: Colors.blue, // Sets the background color of the AppBar
      ),
      body: Center(
        child: ListView.builder(
          itemCount: temperatures.length,
          itemBuilder: (context, index) {
            double temp = double.tryParse(temperatures[index]) ?? double.nan;
            Color textColor = temp.isNaN ? Colors.grey : (temp > -15 ? Colors.red : Colors.blue);
            return ListTile(
              title: Text('Freezer ${index + 1}'),
              trailing: Text(
                temperatures[index] + ' °C',
                style: TextStyle(color: textColor),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }
}




class ChartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Data Visualization Chart'),
    );
  }
}

//void main() => runApp(MaterialApp(home: ContactInfoScreen()));

class ContactInfoScreen extends StatefulWidget {
  @override
  _ContactInfoScreenState createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Information'),  // Ensure this is the only AppBar title set
        backgroundColor: Colors.blue,  // Optional: Set the AppBar color to match your theme
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'This field cannot be empty' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'This field cannot be empty' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                validator: (value) => value!.isEmpty ? 'This field cannot be empty' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Save or use contact information
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Contact Information Saved')),
                    );
                  }
                },
                child: Text('Save Contact Info'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

 

class SignUpPage extends StatelessWidget {
  final VoidCallback onToggle;

  SignUpPage({required this.onToggle});

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _register(BuildContext context) {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('All fields are required.')));
      return;
    }

    if (_usernameController.text == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This username is reserved. Please choose another.')));
      return;
    }

    if (registeredUsers.containsKey(_usernameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Username already exists.')));
      return;
    }

    registeredUsers[_usernameController.text] = _passwordController.text;
    Navigator.pop(context); // Return to login screen after successful registration
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password', suffixIcon: Icon(Icons.visibility_off)),
            obscureText: true,
          ),
          SizedBox(height: 20),
          ElevatedButton(onPressed: () => _register(context), child: Text('Register')),
          TextButton(onPressed: onToggle, child: Text('Already have an account? Log in')),
        ],
      ),
    );
  }

  Future<void> startMQTT() async{
    final client = MqttServerClient('mqtt.cetools.org', 'student');
    client.port=1884;

    // Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    
    client.keepAlivePeriod = 30;

    final String username = 'student';
    final String password = 'ce2021-mqtt-forget-whale';

    // Connect the client, any errors here are communicated by raising of the appropriate exception.
    try {
    await client.connect(username, password);
  } catch (e) {
    print('Client exception - $e');
    client.disconnect();
    return;
  }

  if (client.connectionStatus!.state == MqttConnectionState.connected) {
    print('Mosquitto client connected');
    client.subscribe('student/CASA0022/ucfnxxu/freezer temperature 3', MqttQos.atMostOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      if (c != null) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final String messageString = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        //updateList(messageString);
      }
    });
  } else {
    print('ERROR: Mosquitto client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
    client.disconnect();
  }
  }
}

