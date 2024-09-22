#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <BLEServer.h>
#include <Arduino.h>

#define bleServerName "XIAOESP32S3_BLE"
const int ledPin = LED_BUILTIN;

BLECharacteristic *pCharacteristic;
BLECharacteristic *pWriteCharacteristic;
bool deviceConnected = false;
String responseData;

class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    Serial.println("Connect Device!!");
  };
  
  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("Disconnect Device!!");
  }
};

class MyCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String value = pCharacteristic->getValue().c_str();
    if (value.length() > 0) {
      Serial.print("Received Data: ");
      Serial.println(value);
      
      if (value == "1") {
        ledOn();
      }else if(value == "0"){
        ledOff();
      } else {
        responseData = "Undefined";
      }
      
      // Gelen mesaja göre cevap ver
      pCharacteristic->setValue(responseData.c_str());
      pCharacteristic->notify();
      
      Serial.print("Sent Response: ");
      Serial.println(responseData);
    }
  }

  void ledOn(){
    digitalWrite(ledPin,LOW);
    responseData = "Led On!";
  }

  void ledOff(){
    digitalWrite(ledPin, HIGH);
    responseData = "Led Off!!";
  }
};

void setup() {
  Serial.begin(115200);
  
  pinMode(ledPin,OUTPUT);
  
  BLEDevice::init(bleServerName);
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  BLEService *pService = pServer->createService(BLEUUID((uint16_t)0x181A));
  
  pWriteCharacteristic = pService->createCharacteristic(
    BLEUUID((uint16_t)0x2A59), 
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE
  );
  
  pWriteCharacteristic->setCallbacks(new MyCallbacks());
  
  pCharacteristic = pService->createCharacteristic(
    BLEUUID((uint16_t)0x2A56),
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic->addDescriptor(new BLE2902());
  
  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(pService->getUUID());
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x0);
  pAdvertising->setMinPreferred(0x1F);
  BLEDevice::startAdvertising();
}

void loop() {

}
