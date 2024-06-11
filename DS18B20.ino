#include <WiFiNINA.h>
#include <ezTime.h>
#include <PubSubClient.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// DS18B20 Sensor
#define ONE_WIRE_BUS 2 // Data wire is connected to pin 2
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

float Temperature;

// WiFi and MQTT credentials
#include "arduino_secrets.h" 
const char* ssid     = SECRET_SSID;
const char* password = SECRET_PASS;
const char* mqttuser = SECRET_MQTTUSER;
const char* mqttpass = SECRET_MQTTPASS;

const char* mqtt_server = "mqtt.cetools.org";

// MQTT client
WiFiClient espClient;
PubSubClient client(espClient);

// Date and time
Timezone GB;

// Global variables
long lastMsg = 0;
char msg[50];
unsigned long lastPublish = 0; // Variable to store the last publish time
const long publishInterval = 5000; // Publish interval in milliseconds (5 seconds)

// Function declarations
void startWifi();
void syncDate();
void sendMQTT();
void readTemperature();
void callback(char* topic, byte* payload, unsigned int length);
void reconnect();

void setup() {
  Serial.begin(115200);

  // Initialize DS18B20 sensor
  sensors.begin();

  // Initialize WiFi
  startWifi();

  // Sync date and time
  syncDate();

  // Start MQTT server
  client.setServer(mqtt_server, 1884);
  client.setCallback(callback);
}

void loop() {
  // Read and send temperature data periodically
  readTemperature();
  sendMQTT();
  
  // Print current time
  Serial.println(GB.dateTime("H:i:s"));
  
  // Handle MQTT client loop
  client.loop();
  delay(5000);
}

void startWifi() {
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);

  // Check to see if connected and wait until connected
  while (WiFi.status() != WL_CONNECTED) {
    delay(2000);
    Serial.print(".");
  }
  
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void syncDate() {
  // Get real date and time
  waitForSync();
  Serial.println("UTC: " + UTC.dateTime());
  GB.setLocation("Europe/London");
  Serial.println("London time: " + GB.dateTime());
}

void readTemperature() {
  sensors.requestTemperatures(); // Send the command to get temperatures
  Temperature = sensors.getTempCByIndex(0); // Get the value of the temperature in Celsius
  if (Temperature == DEVICE_DISCONNECTED_C) {
    Serial.println("Error: Could not read temperature data");
    Temperature = NAN; // Set the temperature to NaN (Not a Number) if reading fails
  } else {
    Serial.print("Current Temperature: ");
    Serial.println(Temperature);
  }
}

void sendMQTT() {
  if (!client.connected()) {
    reconnect();
  }
  
  client.loop();
  
  // Always publish the temperature, even if it's NaN
  snprintf(msg, 50, "%.1f", Temperature);
  Serial.print("Publish message for t: ");
  Serial.println(msg);
  client.publish("student/CASA0022/ucfnxxu/freezer temperature 3", msg);
}

void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  
  Serial.println();
}

void reconnect() {
  // Loop until reconnected
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    
    // Create a random client ID
    String clientId = "mkr1010Client-";
    clientId += String(random(0xffff), HEX);
    
    // Attempt to connect with clientID, username, and password
    if (client.connect(clientId.c_str(), mqttuser, mqttpass)) {
      Serial.println("connected");
      // Resubscribe
      client.subscribe("student/CASA0022/ucfnxxu/inTopic");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      // Wait 5 seconds before retrying
      delay(5000);
    }
  }
}
