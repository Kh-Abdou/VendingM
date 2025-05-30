#include <Wire.h>
#include <Adafruit_VL53L0X.h>
#include <DHT.h>
#include <MFRC522.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <WiFiManager.h>
#include <LiquidCrystal_I2C.h>
#include <Keypad.h>

#define RELAY1 26  // Chariot 1
#define RELAY2 25  // Chariot 2 
#define RELAY3 33  // Chariot 3

struct ChariotRelay {
  const char* id;
  int pin;
  unsigned long activationTimeMs;
};

const ChariotRelay CHARIOT_RELAY_MAP[] = {
  {"CHARIOT1", RELAY1, 4625},
  {"CHARIOT2", RELAY2, 4625},
  {"CHARIOT3", RELAY3, 3000}
};
const int NUM_CHARIOTS = 3;

int getRelayPinForChariot(String chariotId) {
  chariotId.trim();
  chariotId.toUpperCase();
  for(int i = 0; i < NUM_CHARIOTS; i++) {
    if(chariotId == CHARIOT_RELAY_MAP[i].id) {
      return CHARIOT_RELAY_MAP[i].pin;
    }
  }
  Serial.println("ERROR: No relay pin found for chariot ID: " + chariotId);
  return -1;
}

unsigned long getActivationTimeForChariot(String chariotId) {
  chariotId.trim();
  chariotId.toUpperCase();
  for(int i = 0; i < NUM_CHARIOTS; i++) {
    if(chariotId == CHARIOT_RELAY_MAP[i].id) {
      return CHARIOT_RELAY_MAP[i].activationTimeMs;
    }
  }
  Serial.println("ERROR: No activation time found for chariot ID: " + chariotId);
  return 0;
}

Adafruit_VL53L0X lox = Adafruit_VL53L0X();

// LCD Display (16x2) - I2C address 0x3F
LiquidCrystal_I2C lcd(0x3F, 16, 2);

#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

#define RST_PIN 0
#define SS_PIN 5
MFRC522 rfid(SS_PIN, RST_PIN);

const byte ROWS = 4;
const byte COLS = 4;
byte rowPins[ROWS] = {12, 13, 14, 27};
byte colPins[COLS] = {15, 2, 16, 17};
char keys[ROWS][COLS] = {
  {'1', '2', '3', 'A'},
  {'4', '5', '6', 'B'},
  {'7', '8', '9', 'C'},
  {'*', '0', '#', 'D'}
};

// Initialize keypad
Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

const char* serverUrl = "http://192.168.1.8:5000";
const char* vendingMachineId = "VM001";

WiFiManager wm;

const int COULOIR1_MIN = 50;
const int COULOIR1_MAX = 150;
const int COULOIR2_MIN = 150;
const int COULOIR2_MAX = 250;
const int COULOIR3_MIN = 250;
const int COULOIR3_MAX = 350;
const int COULOIR4_MIN = 350;
const int COULOIR4_MAX = 450;

unsigned long orderCooldownUntil = 0;
const unsigned long ORDER_COOLDOWN_MS = 2000;
unsigned long orderStartTime = 0;
unsigned long ORDER_TIMEOUT_MS = 30000;

struct OrderItem {
  int couloir;
  int quantity;
  int detectedCount;
};

unsigned long lastSensorReset = 0;
const unsigned long SENSOR_RESET_INTERVAL = 600000;
int unexpectedDetectionCount = 0;
const int MAX_UNEXPECTED_DETECTIONS = 5;

OrderItem currentOrder[3];
int totalItemsInOrder = 0;
bool orderInProgress = false;
String currentOrderId = "";
String currentUserId = "";
bool orderFailed = false;

// Enhanced LCD states for RFID ordering
enum LcdState {
  WELCOME,
  MAIN_MENU,
  SELECT_PRODUCT,
  ENTER_QUANTITY,
  ADD_MORE_OR_PROCEED,
  SCAN_RFID,
  ENTER_PIN,
  ORDER_SUMMARY,
  PROCESSING,
  DISPENSING,
  COMPLETE,
  ERROR_STATE,
  TIMEOUT,
  CANCELLED,
  ENTER_COULOIR // Legacy state for old keypad ordering
};

LcdState lcdState = LcdState::MAIN_MENU;

// RFID ordering variables
struct ProductInfo {
  String id;
  String name;
  int quantity;
  int chariot;
  float price;
};

struct OrderProduct {
  ProductInfo product;
  int requestedQuantity;
};

ProductInfo availableProducts[10]; // Max 10 products
int numAvailableProducts = 0;
OrderProduct orderCart[10]; // Max 10 different products in cart
int cartSize = 0;
int selectedProductIndex = 0;
int selectedCouloir = 0;
int selectedQuantity = 0;
String keypadBuffer = "";
String pinBuffer = "";
String scannedRfidUID = "";
bool isAuthenticated = false;
unsigned long lastInputTime = 0;
const unsigned long INPUT_TIMEOUT = 40000; // 40 seconds timeout
int pinAttempts = 0;
const int MAX_PIN_ATTEMPTS = 3;
float totalOrderCost = 0.0;

bool rfidRegistrationMode = false;
unsigned long rfidRegistrationStartTime = 0;
unsigned long RFID_REGISTRATION_TIMEOUT = 120000;

void setupWiFi() {
  Serial.println("Setting up WiFi with WiFiManager...");
  const char* portalPassword = "VendingM";
  wm.setConfigPortalTimeout(180);
  wm.setAPCallback([](WiFiManager *myWiFiManager) {
    Serial.println("Entered configuration mode");
    Serial.print("Config Portal SSID: ");
    Serial.println(myWiFiManager->getConfigPortalSSID());
    Serial.print("Config Portal IP: ");
    Serial.println(WiFi.softAPIP());
  });

  if (!wm.autoConnect("VendingMachine-AP", portalPassword)) {
    Serial.println("Failed to connect to WiFi and hit timeout");
  } else {
    Serial.println("Connected to WiFi!");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
  }
}

void setup() {
  Serial.begin(115200);
  while (!Serial) {
    delay(1);
  }

  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  digitalWrite(RELAY1, HIGH);
  digitalWrite(RELAY2, HIGH);
  digitalWrite(RELAY3, HIGH);

  if (!lox.begin()) {
    Serial.println("Failed to initialize VL53L0X!");
    while (1);
  }

  dht.begin();
  SPI.begin();
  rfid.PCD_Init();

  // Initialize LCD
  initializeLCD();

  for (byte i = 0; i < ROWS; i++) {
    pinMode(rowPins[i], OUTPUT);
    digitalWrite(rowPins[i], HIGH);
  }
  for (byte i = 0; i < COLS; i++) {
    pinMode(colPins[i], INPUT_PULLUP);
  }

  setupWiFi();

  if (WiFi.status() == WL_CONNECTED) {
    registerMachine();
    sendEnvironmentData();
  }

  showWelcomeScreen();
}

void showWelcomeScreen() {
  lcdState = LcdState::WELCOME;
}

void registerMachine() {
  HTTPClient http;
  String url = String(serverUrl) + "/hardware/register";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  String jsonPayload = "{\"vendingMachineId\":\"" + String(vendingMachineId) +
                      "\",\"name\":\"Main Vending Machine\"}";
  int httpResponseCode = http.POST(jsonPayload);

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println("Machine registration successful!");
    Serial.println("HTTP Response code: " + String(httpResponseCode));
    Serial.println("Register response: " + response);
  } else {
    Serial.print("Registration failed. Error code: ");
    Serial.println(httpResponseCode);
  }
  http.end();
}

void sendEnvironmentData() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  if (isnan(h) || isnan(t)) {
    Serial.println("Failed to read from DHT sensor!");
    return;
  }

  if (WiFi.status() != WL_CONNECTED) {
    setupWiFi();
    if (WiFi.status() != WL_CONNECTED) return;
  }

  HTTPClient http;
  String url = String(serverUrl) + "/hardware/environment";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  String jsonPayload = "{\"temperature\":" + String(t) + ",\"humidity\":" + String(h) + "}";
  Serial.print("Sending environment data to: ");
  Serial.println(url);
  Serial.print("JSON payload: ");
  Serial.println(jsonPayload);

  int httpResponseCode = http.POST(jsonPayload);

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println("Environment data sent successfully!");
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);
    Serial.print("Response: ");
    Serial.println(response);
  } else {
    Serial.print("Error sending environment data. Code: ");
    Serial.println(httpResponseCode);
  }
  http.end();
}

bool authenticateCard(String cardUID) {
  HTTPClient http;
  String url = String(serverUrl) + "/hardware/auth/rfid";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  String jsonPayload = "{\"rfidUID\":\"" + cardUID + "\"}";
  int httpResponseCode = http.POST(jsonPayload);

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println("HTTP Response code: " + String(httpResponseCode));
    Serial.println(response);

    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, response);
    if (!error && doc["isAuthenticated"]) {
      currentUserId = doc["userId"].as<String>();
      return true;
    }
  } else {
    Serial.print("Error code: ");
    Serial.println(httpResponseCode);
  }
  http.end();
  return false;
}

void checkForApiOrders() {
    if (orderInProgress || millis() < orderCooldownUntil) return;

    HTTPClient http;
    String url = String(serverUrl) + "/hardware/dispense/new-orders";
    http.begin(url);
    http.addHeader("Content-Type", "application/json");

    String jsonPayload = "{\"vendingMachineId\":\"" + String(vendingMachineId) + "\"}";
    Serial.print("Sending request to: ");
    Serial.println(url);
    Serial.print("With payload: ");
    Serial.println(jsonPayload);

    int httpResponseCode = http.POST(jsonPayload);
    if (httpResponseCode == 200) {
        String response = http.getString();
        Serial.println("Response code 200 OK. Received: " + response);

        DynamicJsonDocument doc(1024);
        DeserializationError error = deserializeJson(doc, response);
        if (!error) {
            currentOrderId = doc["orderId"].as<String>();
            for (int i = 0; i < NUM_CHARIOTS; i++) {
                currentOrder[i] = {0, 0, 0};
            }

            JsonArray products = doc["products"].as<JsonArray>();
            int orderIndex = 0;
            for (JsonVariant product : products) {
                if (orderIndex < NUM_CHARIOTS) {
                    currentOrder[orderIndex].couloir = product["couloir"].as<int>();
                    currentOrder[orderIndex].quantity = product["quantity"].as<int>();
                    orderIndex++;
                }
            }
            totalItemsInOrder = orderIndex;
            if (totalItemsInOrder > 0) {
                ORDER_TIMEOUT_MS = min(30000UL + (totalItemsInOrder * 10000UL), 120000UL);
                orderInProgress = true;
                orderFailed = false;
                orderStartTime = millis();
                processActiveOrder();
            }
        }
    } else if (httpResponseCode != 404) {
        String errorResponse = http.getString();
        Serial.print("HTTP error: ");
        Serial.println(httpResponseCode);
        Serial.print("Error response: ");
        Serial.println(errorResponse);
    }
    http.end();
}

void processActiveOrder() {
  if (!orderInProgress || totalItemsInOrder == 0) {
    resetOrderState();
    return;
  }

  Serial.println("Processing order " + currentOrderId);
  for (int i = 0; i < totalItemsInOrder; i++) {
    int couloir = currentOrder[i].couloir;
    int quantity = currentOrder[i].quantity;
    Serial.println("Dispensing " + String(quantity) + " from couloir " + String(couloir));
    for (int j = 0; j < quantity; j++) {
      dispenseSingleItem(couloir);
    }
  }

  int totalExpected = 0, totalDispensed = 0;
  for (int i = 0; i < totalItemsInOrder; i++) {
    totalExpected += currentOrder[i].quantity;
    totalDispensed += currentOrder[i].detectedCount;
  }

  Serial.println("Order result: " + String(totalDispensed) + "/" + String(totalExpected) + " dispensed");
  if (totalDispensed == 0) {
    failOrder("No products dispensed");
  } else {
    completeOrder();
  }
}

void failOrder(String reason) {
  if (!orderInProgress) return;

  Serial.println("Order " + currentOrderId + " failed: " + reason);
  String tempOrderId = currentOrderId;
  orderInProgress = false;
  orderFailed = true;
  currentUserId = "";
  totalItemsInOrder = 0;
  orderCooldownUntil = millis() + ORDER_COOLDOWN_MS;

  HTTPClient http;
  String url = String(serverUrl) + "/orders/fail";
  int totalExpected = 0, totalDispensed = 0;
  for (int i = 0; i < totalItemsInOrder; i++) {
    totalExpected += currentOrder[i].quantity;
    totalDispensed += currentOrder[i].detectedCount;
  }
  String jsonPayload = "{\"orderId\":\"" + tempOrderId +
                      "\",\"vendingMachineId\":\"" + String(vendingMachineId) +
                      "\",\"reason\":\"" + reason + "\"," +
                      "\"details\":{\"totalExpected\":" + String(totalExpected) +
                      ",\"totalDispensed\":" + String(totalDispensed) + "}}";
  Serial.print("Sending failure request to: ");
  Serial.println(url);
  Serial.print("With payload: ");
  Serial.println(jsonPayload);

  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  int httpResponseCode = http.POST(jsonPayload);
  String response = http.getString();
  Serial.println("HTTP Response code: " + String(httpResponseCode));
  Serial.println("Response: " + response);
  http.end();
  currentOrderId = "";
}

bool dispenseSingleItem(int couloir) {
  String chariotId = "CHARIOT" + String(couloir);
  int relayPin = getRelayPinForChariot(chariotId);
  unsigned long activationTimeMs = getActivationTimeForChariot(chariotId);
  if (relayPin == -1 || activationTimeMs == 0) return false;

  if (!lox.begin()) return false;

  digitalWrite(relayPin, LOW);
  delay(activationTimeMs);
  digitalWrite(relayPin, HIGH);
  delay(800);

  const unsigned long DETECTION_TIMEOUT = 1500;
  unsigned long startTime = millis();
  while (millis() - startTime < DETECTION_TIMEOUT) {
    int detectedCouloir = detectItemCouloir(couloir);
    if (detectedCouloir == couloir) {
      updateItemDetection(detectedCouloir);
      Serial.println("Item detected in couloir " + String(couloir));
      return true;
    }
    delay(10);
  }
  Serial.println("Item not detected in couloir " + String(couloir));
  return false;
}

int detectItemCouloir(int requestedCouloir) {
  VL53L0X_RangingMeasurementData_t measure;
  lox.rangingTest(&measure, false);
  if (measure.RangeStatus != 4) {
    int distance = measure.RangeMilliMeter;
    if (distance > 50 && distance < 800) return requestedCouloir;
  }
  return 0;
}

void updateItemDetection(int detectedCouloir) {
  if (orderFailed || !orderInProgress) return;

  for (int i = 0; i < totalItemsInOrder; i++) {
    if (currentOrder[i].couloir == detectedCouloir && currentOrder[i].detectedCount < currentOrder[i].quantity) {
      currentOrder[i].detectedCount++;
      break;
    }
  }
}

void completeOrder() {
  if (!orderInProgress || orderFailed) return;

  int totalExpected = 0, totalDispensed = 0;
  for (int i = 0; i < totalItemsInOrder; i++) {
    totalExpected += currentOrder[i].quantity;
    totalDispensed += currentOrder[i].detectedCount;
  }

  HTTPClient http;
  String url = String(serverUrl) + "/hardware/dispense/complete";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  String jsonPayload = "{\"orderId\":\"" + currentOrderId +
                      "\",\"vendingMachineId\":\"" + String(vendingMachineId) +
                      "\",\"details\":{\"totalDispensed\":" + String(totalDispensed) +
                      ",\"totalExpected\":" + String(totalExpected) + "}}";
  Serial.print("Sending request to: ");
  Serial.println(url);
  Serial.print("With payload: ");
  Serial.println(jsonPayload);

  int httpResponseCode = http.POST(jsonPayload);
  String response = http.getString();
  if (httpResponseCode == 200) {
    Serial.println("Order completed successfully!");
    Serial.println("Response: " + response);
    resetOrderState();
  } else {
    Serial.println("Error completing order: " + String(httpResponseCode));
    failOrder("HTTP error");
  }
  http.end();
}

void processKeypadOrder() {
  if (!isAuthenticated || selectedCouloir < 1 || selectedCouloir > NUM_CHARIOTS || selectedQuantity < 1) return;

  HTTPClient http;
  String url = String(serverUrl) + "/order/keypad";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  String jsonPayload = "{\"userId\":\"" + currentUserId +
                      "\",\"vendingMachineId\":\"" + String(vendingMachineId) +
                      "\",\"couloir\":" + String(selectedCouloir) +
                      ",\"quantity\":" + String(selectedQuantity) + "}";
  Serial.print("Sending keypad order request to: ");
  Serial.println(url);
  Serial.print("With payload: ");
  Serial.println(jsonPayload);

  int httpResponseCode = http.POST(jsonPayload);
  if (httpResponseCode == 201) {
    String response = http.getString();
    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, response);
    if (!error) {
      currentOrderId = doc["orderId"].as<String>();
      totalItemsInOrder = 1;
      currentOrder[0] = {selectedCouloir, selectedQuantity, 0};
      orderInProgress = true;
      orderFailed = false;
      orderStartTime = millis();
      processActiveOrder();
    }
  }
  http.end();
}

void showCouloirPrompt() {
  lcdState = LcdState::ENTER_COULOIR;
  keypadBuffer = "";
}

void showQuantityPrompt() {
  lcdState = LcdState::ENTER_QUANTITY;
  keypadBuffer = "";
}

void handleKeypadInput(char key) {
  switch (lcdState) {
    case LcdState::WELCOME:
      if (key == 'A' && isAuthenticated) showCouloirPrompt();
      else if (key == '*') resetOrderState(), showWelcomeScreen();
      break;
    case LcdState::ENTER_COULOIR:
      if (key >= '1' && key <= '3') selectedCouloir = key - '0', showQuantityPrompt();
      else if (key == '#') showWelcomeScreen();
      break;
    case LcdState::ENTER_QUANTITY:
      if (key >= '0' && key <= '9') keypadBuffer += key;
      else if (key == 'A' && keypadBuffer.length() > 0) {
        selectedQuantity = keypadBuffer.toInt();
        if (selectedQuantity > 0) processKeypadOrder();
        else showQuantityPrompt();
      } else if (key == '#') showCouloirPrompt();
      else if (key == '*' && keypadBuffer.length() > 0) keypadBuffer = keypadBuffer.substring(0, keypadBuffer.length() - 1);
      break;
  }
}

char getKey() {
  for (byte r = 0; r < ROWS; r++) {
    digitalWrite(rowPins[r], LOW);
    for (byte c = 0; c < COLS; c++) {
      if (digitalRead(colPins[c]) == LOW) {
        while (digitalRead(colPins[c]) == LOW);
        digitalWrite(rowPins[r], HIGH);
        return keys[r][c];
      }
    }
    digitalWrite(rowPins[r], HIGH);
  }
  return '\0';
}

void checkProductUpdates() {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  DynamicJsonDocument doc(2048);
  String productUrl = String(serverUrl) + "/product/with-stock";
  http.begin(productUrl);
  int productResponseCode = http.GET();
  if (productResponseCode == 200) {
    String productResponse = http.getString();
    DeserializationError error = deserializeJson(doc, productResponse);
    if (!error) {
      JsonArray products = doc.as<JsonArray>();
      for (JsonVariant product : products) {}
    }
  }
  http.end();

  String chariotUrl = String(serverUrl) + "/chariot";
  http.begin(chariotUrl);
  int chariotResponseCode = http.GET();
  if (chariotResponseCode == 200) {
    String chariotResponse = http.getString();
    doc.clear();
    DeserializationError error = deserializeJson(doc, chariotResponse);
    if (!error) {
      JsonArray chariots = doc.as<JsonArray>();
      for (JsonVariant chariot : chariots) {}
    }
  }
  http.end();
}

void resetOrderState() {
  orderInProgress = false;
  orderFailed = false;
  currentOrderId = "";
  currentUserId = "";
  totalItemsInOrder = 0;
  orderStartTime = 0;
  for (int i = 0; i < NUM_CHARIOTS; i++) currentOrder[i] = {0, 0, 0};
}

void checkForRfidRegistration() {
  if (rfidRegistrationMode && millis() - rfidRegistrationStartTime > RFID_REGISTRATION_TIMEOUT) {
    rfidRegistrationMode = false;
    return;
  }
  if (WiFi.status() != WL_CONNECTED) return;

  static unsigned long lastRegistrationCheck = 0;
  if (millis() - lastRegistrationCheck < 5000) return;
  lastRegistrationCheck = millis();

  HTTPClient http;
  String url = String(serverUrl) + "/user/rfid/check-pending";
  http.begin(url);
  int httpCode = http.GET();
  if (httpCode == 200) {
    String response = http.getString();
    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, response);
    if (!error && doc.containsKey("pendingRegistrations") && doc["pendingRegistrations"].size() > 0) {
      currentUserId = doc["pendingRegistrations"][0]["userId"].as<String>();
      rfidRegistrationMode = true;
      rfidRegistrationStartTime = millis();
    }
  }
  http.end();
}

void processRfidRegistration(String cardUID) {
  if (!rfidRegistrationMode || currentUserId.isEmpty() || WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String url = String(serverUrl) + "/user/rfid/complete";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  String jsonPayload = "{\"userId\":\"" + currentUserId + "\",\"rfidUID\":\"" + cardUID + "\"}";
  Serial.println("Sending RFID registration request: " + jsonPayload);

  int httpCode = http.POST(jsonPayload);
  String response = http.getString();
  Serial.println("RFID registration response code: " + String(httpCode));
  Serial.println("Response: " + response);

  rfidRegistrationMode = false;
  currentUserId = "";
  http.end();
}

void loop() {
  static unsigned long lastOrderCheck = 0, lastProductCheck = 0, lastEnvironmentUpdate = 0;

  checkForRfidRegistration();

  if (orderInProgress && millis() - orderStartTime > ORDER_TIMEOUT_MS) {
    failOrder("Order timed out");
  }

  if (WiFi.status() == WL_CONNECTED) {
    if (millis() - lastOrderCheck > 2000 && !orderInProgress && millis() >= orderCooldownUntil) {
      checkForApiOrders();
      lastOrderCheck = millis();
    }
    if (millis() - lastProductCheck > 5000) {
      checkProductUpdates();
      lastProductCheck = millis();
    }
    if (millis() - lastEnvironmentUpdate > 60000) {
      sendEnvironmentData();
      lastEnvironmentUpdate = millis();
    }
  }
  // Handle keypad input for both legacy keypad ordering and new RFID ordering
  char key = keypad.getKey(); // Use new Keypad library
  if (key != '\0') {
    Serial.print("Key pressed: ");
    Serial.println(key);
    
    // Check session timeout for RFID ordering
    checkSessionTimeout();
    
    // Route input to appropriate handler based on current LCD state
    if (lcdState == LcdState::WELCOME || lcdState == LcdState::ENTER_COULOIR || lcdState == LcdState::ENTER_QUANTITY) {
      handleKeypadInput(key); // Legacy keypad ordering
    } else {
      handleRfidOrderInput(key); // New RFID ordering system
    }
  }

  // Handle RFID card detection
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    String cardUID = "";
    for (byte i = 0; i < rfid.uid.size; i++) {
      cardUID += (rfid.uid.uidByte[i] < 0x10 ? "0" : "");
      cardUID += String(rfid.uid.uidByte[i], HEX);
    }
    Serial.print("Card UID: ");
    Serial.println(cardUID);

    if (WiFi.status() == WL_CONNECTED) {
      if (rfidRegistrationMode) {
        // Handle RFID registration
        processRfidRegistration(cardUID);
      } else if (lcdState == LcdState::SCAN_RFID) {
        // RFID ordering system - store UID and move to PIN entry
        scannedRfidUID = cardUID;
        lcdState = LcdState::ENTER_PIN;
        pinBuffer = "";
        pinAttempts = 0;
        updateLCDDisplay();
        Serial.println("RFID card scanned for ordering, waiting for PIN");
      } else {
        // Legacy authentication flow
        if (authenticateCard(cardUID)) {
          isAuthenticated = true;
        }
      }
    }
    rfid.PICC_HaltA();
  }

  // Update LCD display regularly and check for session timeout
  static unsigned long lastLcdUpdate = 0;
  if (millis() - lastLcdUpdate > 1000) { // Update LCD every second
    if (lcdState != LcdState::MAIN_MENU) {
      checkSessionTimeout();
    }
    lastLcdUpdate = millis();
  }

  if (millis() - lastSensorReset > SENSOR_RESET_INTERVAL || unexpectedDetectionCount >= MAX_UNEXPECTED_DETECTIONS) {
    if (!lox.begin()) Serial.println("Failed to reinitialize VL53L0X!");
    else lastSensorReset = millis(), unexpectedDetectionCount = 0;
  }

  if (!orderInProgress) {
    VL53L0X_RangingMeasurementData_t measure;
    lox.rangingTest(&measure, false);
    if (measure.RangeStatus != 4 && measure.RangeMilliMeter > 50 && measure.RangeMilliMeter < 800) {
      unexpectedDetectionCount++;
    }
  }

  delay(1000);
}