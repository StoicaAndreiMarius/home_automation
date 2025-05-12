#include <BluetoothSerial.h>
#include <esp_now.h>
#include <WiFi.h>

BluetoothSerial SerialBT;

const int ledPin = 12;
bool isConnected = false;

// Structură pentru trimiterea datelor prin ESP-NOW
typedef struct struct_message {
  char message[16];
} struct_message;

struct_message myData;

// Adresele MAC ale ESP-urilor cu care vrem să comunicăm
uint8_t peer1[] = {0x24, 0x6F, 0x28, 0xAB, 0xCD, 0xEF}; // exemplu de MAC
// uint8_t peer2[] = {0x24, 0x6F, 0x28, 0x12, 0x34, 0x56}; // exemplu de MAC

void onDataSent(const uint8_t *mac_addr, esp_now_send_status_t status) {
  Serial.println(F(status == ESP_NOW_SEND_SUCCESS ? "success" : "fail"));
}

void setup() {
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, LOW);
  Serial.begin(115200);

  if (!SerialBT.begin("Home Automation")) {
    Serial.println(F("bt error"));
  } else {
    Serial.println(F("bt started"));
  }

  WiFi.mode(WIFI_STA);

  if (esp_now_init() != ESP_OK) {
    Serial.println(F("esp-now error"));
    return;
  }
  esp_now_register_send_cb(onDataSent);

  esp_now_peer_info_t peerInfo;
  memcpy(peerInfo.peer_addr, peer1, 6);
  peerInfo.channel = 0;
  peerInfo.encrypt = false;
  esp_now_add_peer(&peerInfo);

  memcpy(peerInfo.peer_addr, peer2, 6);
  esp_now_add_peer(&peerInfo);
}

void loop() {
  if (SerialBT.hasClient()) {
    if (!isConnected) {
      Serial.println(F("device connected"));
      isConnected = true;
    }

    if (SerialBT.available()) {
      String message = SerialBT.readStringUntil('\n');
      message.trim();

      if (message == "LED_ON") {
        digitalWrite(ledPin, HIGH);
        SerialBT.println(F("LED ON"));
      } else if (message == "LED_OFF") {
        digitalWrite(ledPin, LOW);
        SerialBT.println(F("LED OFF"));
      }

      message.toCharArray(myData.message, 16);
      esp_now_send(peer1, (uint8_t *)&myData, sizeof(myData));
      // esp_now_send(peer2, (uint8_t *)&myData, sizeof(myData));
    }
  } else if (isConnected) {
    Serial.println(F("device disconnected"));
    digitalWrite(ledPin, LOW);
    isConnected = false;
  }
  delay(100);
}