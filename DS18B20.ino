#include <WiFiNINA.h>
#include <ezTime.h>
#include <PubSubClient.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// DS18B20 Sensor
#define ONE_WIRE_BUS 2
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

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
float Temperature;
char msg[50];

void setup() {
  Serial.begin(115200);
  sensors.begin();
  checkWiFiModule();
  startWifi();
  syncDate();
  client.setServer(mqtt_server, 1884);
  client.setCallback(callback);
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    startWifi();
  }

  readTemperature();
  sendMQTT();
  client.loop();
  Serial.println(GB.dateTime("H:i:s"));
  delay(5000);
}

void checkWiFiModule() {
  if (WiFi.status() == WL_NO_MODULE) {
    Serial.println("Communication with WiFi module failed!");
    while (true);
  }
  String fv = WiFi.firmwareVersion();
  if (fv < WIFI_FIRMWARE_LATEST_VERSION) {
    Serial.println("Please upgrade the firmware");
  }
}

void startWifi() {
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);

  int counter = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(600);
    Serial.print(".");
    counter++;
    if (counter > 50) {
      Serial.println("Resetting due to failed WiFi connection...");
      NVIC_SystemReset();
    }
  }
  Serial.println("\nWiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void syncDate() {
  waitForSync();
  GB.setLocation("Europe/London");
  Serial.println("Time synchronized: " + GB.dateTime());
}

void readTemperature() {
  sensors.requestTemperatures();
  Temperature = sensors.getTempCByIndex(0);
  if (Temperature == DEVICE_DISCONNECTED_C) {
    Serial.println("Error: Could not read temperature data");
  } else {
    Serial.print("Current Temperature: ");
    Serial.println(Temperature);
  }
}

void sendMQTT() {
  if (!client.connected()) {
    reconnect();
  }
  snprintf(msg, 50, "%.1f", Temperature);
  client.publish("student/CASA0022/ucfnxxu/freezer temperature 3", msg);
  Serial.print("Publish message for t: ");
  Serial.println(msg);
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
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    String clientId = "mkr1010Client-" + String(random(0xffff), HEX);
    if (client.connect(clientId.c_str(), mqttuser, mqttpass)) {
      Serial.println("connected");
      client.subscribe("student/CASA0022/ucfnxxu/inTopic");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      delay(5000);
    }
  }
}
