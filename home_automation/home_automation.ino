#include <WiFi.h>
#include <WebServer.h>

const char* ssid = "Marius";
const char* password = "wififree";

#define ledPin 14

WebServer server(80);
bool ledState = LOW; // memorăm starea ledului

void handleLedOn() {
  ledState = HIGH;
  digitalWrite(ledPin, ledState);
  server.send(200, "text/plain", "LED is ON");
}

void handleLedOff() {
  ledState = LOW;
  digitalWrite(ledPin, ledState);
  server.send(200, "text/plain", "LED is OFF");
}

void setup() {
  delay(1000); // mic delay să lăsăm placa să booteze complet
  Serial.begin(115200);

  pinMode(ledPin, OUTPUT);

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("");
  Serial.print("Connected! IP Address: ");
  Serial.println(WiFi.localIP());

  server.on("/led_on", handleLedOn);
  server.on("/led_off", handleLedOff);
  server.begin();
}

void loop() {
  server.handleClient();
  delay(1);
}
