# CASA-0022

A dissertation project of monitor freezer environment in Bio-lab.

## Connecting the physical device

DS18B20.ino outlines the setup and code for integrating a temperature monitoring system using the MKR 1010 board and DS18B20 temperature sensor, complemented by a lipo battery and a 4.7k ohm resistor for stability. The code leverages several libraries such as WiFiNINA, ezTime, PubSubClient, OneWire, and DallasTemperature to facilitate WiFi connectivity, time synchronization, and MQTT communication.

### Key Components:

Board: MKR 1010


Sensor: DS18B20


Additional Hardware: Lipo battery, 4.7k ohm resistor

<img width="787" alt="image" src="https://github.com/xxu121/CASA-0022/assets/146341729/2a896eab-2ef1-481f-ad77-ebefad3879ed">


### Libraries Used:

WiFiNINA for handling WiFi connections.


ezTime for managing date and time synchronization.


PubSubClient for MQTT communication.


OneWire and DallasTemperature for interfacing with the DS18B20 sensor.


### Main Functions


Temperature reading: DS18B20 sensor reads the temperature and sends the data via MQTT.


WiFi Connection: Automatically connect to a predefined network using credentials stored in arduino_secrets.h.


MQTT Communication: Sends temperature data to MQTT server and uses callback functions to process incoming information.


Time Synchronization: Synchronize the time over the internet to ensure accurate timestamping of temperature readings.


