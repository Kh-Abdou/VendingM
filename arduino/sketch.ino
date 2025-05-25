#include <Wire.h>
#include <Adafruit_VL53L0X.h>
#include <DHT.h>
#include <MFRC522.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <WiFiManager.h>

#define RELAY1 26  // Chariot 1
#define RELAY2 25  // Chariot 2 
#define RELAY3 33  // Chariot 3
#define RELAY4 32  // Chariot 4

struct ChariotRelay {
  const char* id;
  int pin;
};

const ChariotRelay CHARIOT_RELAY_MAP[] = {
  {"CHARIOT1", RELAY1},
  {"CHARIOT2", RELAY2}, 
  {"CHARIOT3", RELAY3},
  {"CHARIOT4", RELAY4}
};
const int NUM_CHARIOTS = 4;

int getRelayPinForChariot(String chariotId) {
  chariotId.trim();
  chariotId.toUpperCase();
  Serial.println("Looking for relay pin for chariot ID: " + chariotId);
  for(int i = 0; i < NUM_CHARIOTS; i++) {
    if(chariotId == CHARIOT_RELAY_MAP[i].id) {
      Serial.println("Found relay pin " + String(CHARIOT_RELAY_MAP[i].pin) + " for " + chariotId);
      return CHARIOT_RELAY_MAP[i].pin;
    }
  }
  Serial.println("ERROR: No relay pin found for chariot ID: " + chariotId);
  return -1;
}

Adafruit_VL53L0X lox = Adafruit_VL53L0X();

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

const char* serverUrl = "http://192.168.86.32:5000";
const char* vendingMachineId = "VM001";

// WiFiManager object
WiFiManager wm;

// Couloir distance ranges for VL53L0X sensor (in millimeters)
const int COULOIR1_MIN = 50;
const int COULOIR1_MAX = 150;
const int COULOIR2_MIN = 150;
const int COULOIR2_MAX = 250;
const int COULOIR3_MIN = 250;
const int COULOIR3_MAX = 350;
const int COULOIR4_MIN = 350;
const int COULOIR4_MAX = 450;

unsigned long orderCooldownUntil = 0;
const unsigned long ORDER_COOLDOWN_MS = 2000; // Reduced for testing
unsigned long orderStartTime = 0; // Track when order starts
const unsigned long ORDER_TIMEOUT_MS = 30000; // 30 seconds timeout for stuck orders

struct OrderItem {
  int couloir;
  int quantity;
  int detectedCount;
};

OrderItem currentOrder[4];
int totalItemsInOrder = 0;
bool orderInProgress = false;
String currentOrderId = "";
String currentUserId = "";
bool orderFailed = false;

enum LcdState {
  WELCOME,
  ENTER_COULOIR,
  ENTER_QUANTITY,
  PROCESSING,
  COMPLETE,
  ERROR
};

LcdState lcdState = LcdState::WELCOME;
int selectedCouloir = 0;
int selectedQuantity = 0;
String keypadBuffer = "";
bool isAuthenticated = false;

// Variables for RFID registration
bool rfidRegistrationMode = false;
unsigned long rfidRegistrationStartTime = 0;
unsigned long RFID_REGISTRATION_TIMEOUT = 120000; // 2 minutes timeout

void testRelays();
void testVL53L0X();
void testDHT11();
void testRFID();
void setupWiFi();
void showWelcomeScreen();
void registerMachine();
void sendEnvironmentData();
bool authenticateCard(String cardUID);
void checkForApiOrders();
void processActiveOrder();
void failOrder(String reason);
bool dispenseSingleItem(int couloir);
int detectItemCouloir();
void updateItemDetection(int detectedCouloir);
void completeOrder();
void processKeypadOrder();
void showCouloirPrompt();
void showQuantityPrompt();
void handleKeypadInput(char key);
char getKey();
void checkProductUpdates();
void resetOrderState();
void checkForRfidRegistration();
void processRfidRegistration(String cardUID);
void checkForRfidRegistration();
void processRfidRegistration(String cardUID);

// Modified setupWiFi function
void setupWiFi() {
  Serial.println("Setting up WiFi with WiFiManager...");

  // Optional: Reset WiFi settings for testing (uncomment if needed)
  // wm.resetSettings();

  // Set a password for the configuration portal
  const char* portalPassword = "VendingM"; // Change this to your desired password
  wm.setConfigPortalTimeout(180); // Timeout for portal in seconds (3 minutes)
  wm.setAPCallback([](WiFiManager *myWiFiManager) {
    Serial.println("Entered configuration mode");
    Serial.print("Config Portal SSID: ");
    Serial.println(myWiFiManager->getConfigPortalSSID());
    Serial.print("Config Portal IP: ");
    Serial.println(WiFi.softAPIP());
  });

  // Start WiFiManager with password-protected portal
  if (!wm.autoConnect("VendingMachine-AP", portalPassword)) {
    Serial.println("Failed to connect to WiFi and hit timeout");
    // Optionally, handle failure (e.g., retry or proceed without WiFi)
    // For now, we'll just continue to allow offline functionality
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
  Serial.println("ESP32 Vending Machine Starting...");

  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);
  digitalWrite(RELAY1, HIGH);
  digitalWrite(RELAY2, HIGH);
  digitalWrite(RELAY3, HIGH);
  digitalWrite(RELAY4, HIGH);
  Serial.println("Relays initialized.");

  if (!lox.begin()) {
    Serial.println("Failed to initialize VL53L0X!");
    while (1);
  }
  Serial.println("VL53L0X initialized.");

  dht.begin();
  Serial.println("DHT11 initialized.");

  float testHumidity = dht.readHumidity();
  float testTemp = dht.readTemperature();
  if (isnan(testHumidity) || isnan(testTemp)) {
    Serial.println("WARNING: Failed to read from DHT sensor! Check wiring.");
  } else {
    Serial.print("DHT Test - Temp: ");
    Serial.print(testTemp);
    Serial.print("°C, Humidity: ");
    Serial.print(testHumidity);
    Serial.println("%");
  }

  SPI.begin();
  rfid.PCD_Init();
  Serial.println("RFID initialized.");

  for (byte i = 0; i < ROWS; i++) {
    pinMode(rowPins[i], OUTPUT);
    digitalWrite(rowPins[i], HIGH);
  }
  for (byte i = 0; i < COLS; i++) {
    pinMode(colPins[i], INPUT_PULLUP);
  }
  Serial.println("Keypad initialized.");

  testRelays();
  testVL53L0X();
  testDHT11();
  testRFID();

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
  Serial.println("Reading DHT sensor...");
  Serial.print("Humidity: ");
  Serial.print(h);
  Serial.print("%, Temperature: ");
  Serial.print(t);
  Serial.println("°C");

  if (isnan(h) || isnan(t)) {
    Serial.println("Failed to read from DHT sensor! Check wiring and make sure sensor is plugged in.");
    return;
  }

  if (h < 0 || h > 100 || t < -40 || t > 80) {
    Serial.println("DHT sensor returned unreasonable values. Possible sensor fault.");
    return;
  }

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected. Cannot send environment data.");
    setupWiFi();
    if (WiFi.status() != WL_CONNECTED) {
      return;
    }
  }

  HTTPClient http;
  String url = String(serverUrl) + "/hardware/environment";
  Serial.print("Sending environment data to: ");
  Serial.println(url);

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  String jsonPayload = "{\"temperature\":" + String(t) +
                      ",\"humidity\":" + String(h) + "}";
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
    if (!error) {
      bool isAuthenticated = doc["isAuthenticated"];
      if (isAuthenticated) {
        currentUserId = doc["userId"].as<String>();
        return true;
      }
    }
  } else {
    Serial.print("Error code: ");
    Serial.println(httpResponseCode);
  }
  http.end();
  return false;
}

void checkForApiOrders() {
  if (orderInProgress) {
    Serial.println("Cannot check for orders: Another order is already in progress");
    return;
  }  
  if (millis() < orderCooldownUntil) {
    unsigned long remainingCooldown = (orderCooldownUntil - millis()) / 1000;
    Serial.println("Cannot check for orders: In cooldown period - " + String(remainingCooldown) + " seconds remaining");
    return;
  }

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
      String orderId = doc["orderId"].as<String>();
      currentOrderId = orderId;

      for (int i = 0; i < 4; i++) {
        currentOrder[i].couloir = 0;
        currentOrder[i].quantity = 0;
        currentOrder[i].detectedCount = 0;
      }

      JsonArray products = doc["products"].as<JsonArray>();
      int orderIndex = 0;
      Serial.println("\nReceived new order to dispense:");
      Serial.println("Order ID: " + orderId);
      Serial.println("Products to dispense:");
      Serial.println("Raw API response: " + response);

      for (JsonVariant product : products) {
        int couloir = product["couloir"].as<int>();
        int quantity = product["quantity"].as<int>();
        if (orderIndex < 4) {
          currentOrder[orderIndex].couloir = couloir;
          currentOrder[orderIndex].quantity = quantity;
          Serial.println("- Couloir " + String(couloir) + ": " + String(quantity) + " items");
          orderIndex++;
        }
      }

      totalItemsInOrder = orderIndex;
      if (totalItemsInOrder > 0) {
        orderInProgress = true;
        orderFailed = false;
        orderStartTime = millis(); // Record order start time
        processActiveOrder();
      } else {
        Serial.println("Error: Order contains no valid products to dispense");
      }
    }
  } else if (httpResponseCode == 404) {
    Serial.println("No new orders to dispense (HTTP 404)");
  } else {
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
    Serial.println("No active order to process");
    resetOrderState();
    return;
  }

  Serial.println("\n=== Processing New Order ===");
  Serial.println("Order ID: " + currentOrderId);
  Serial.println("Total items in order: " + String(totalItemsInOrder));

  Serial.println("\n--- Complete Order Details ---");
  for (int i = 0; i < totalItemsInOrder; i++) {
    Serial.println("Item " + String(i+1) + ":");
    Serial.println("  Couloir: " + String(currentOrder[i].couloir) + " (CHARIOT" + String(currentOrder[i].couloir) + ")");
    Serial.println("  Quantity: " + String(currentOrder[i].quantity));
    Serial.println("  Relay Pin: " + String(getRelayPinForChariot("CHARIOT" + String(currentOrder[i].couloir))));
  }
  Serial.println("----------------------------");

  bool orderSuccess = true;

  for (int i = 0; i < totalItemsInOrder; i++) {
    int couloir = currentOrder[i].couloir;
    int quantity = currentOrder[i].quantity;

    Serial.println("\n--- Product " + String(i + 1) + " Details ---");
    Serial.println("Assigned Chariot/Couloir: " + String(couloir));
    Serial.println("Quantity requested: " + String(quantity));

    for (int j = 0; j < quantity; j++) {
      Serial.println("Dispensing item " + String(j + 1) + " of " + String(quantity) + " from couloir " + String(couloir));
      bool itemDetected = dispenseSingleItem(couloir);
      if (itemDetected) {
        currentOrder[i].detectedCount++;
        Serial.println("Item detected in couloir " + String(couloir));
      } else {
        orderSuccess = false;
        orderFailed = true;
        Serial.println("Failed to detect item from couloir " + String(couloir));
        failOrder("Product detection failed for couloir " + String(couloir));
        return;
      }
    }
  }

  if (orderSuccess) {
    completeOrder();
  }
}

void failOrder(String reason) {
  if (!orderInProgress) {
    Serial.println("No active order to fail");
    return;
  }

  Serial.println("\n========== ORDER FAILURE AT " + String(millis()) + "ms ==========");
  Serial.println("Order ID: " + currentOrderId);
  Serial.println("Failure reason: " + reason);
  Serial.println("Dispensed items status:");

  int totalExpected = 0;
  int totalDispensed = 0;
  for (int i = 0; i < totalItemsInOrder; i++) {
    totalExpected += currentOrder[i].quantity;
    totalDispensed += currentOrder[i].detectedCount;
    Serial.println("- Couloir " + String(currentOrder[i].couloir) + ": " + 
                  String(currentOrder[i].detectedCount) + "/" + 
                  String(currentOrder[i].quantity) + " items detected" +
                  (currentOrder[i].detectedCount < currentOrder[i].quantity ? " ⚠ INCOMPLETE" : " ✓ COMPLETE"));
  }
  int completionPercentage = (totalExpected > 0) ? (totalDispensed * 100 / totalExpected) : 0;
  Serial.println("Overall completion: " + String(completionPercentage) + "% (" + 
                String(totalDispensed) + "/" + String(totalExpected) + " products)");

  // Store orderId for HTTP request
  String tempOrderId = currentOrderId;

  // Reset order state except orderId
  orderInProgress = false;
  orderFailed = true;
  currentUserId = "";
  totalItemsInOrder = 0;
  orderCooldownUntil = millis() + ORDER_COOLDOWN_MS;
  Serial.println("Order state reset (except orderId). Setting cooldown until: " + String(orderCooldownUntil) + "ms");

  // Attempt HTTP request with retry
  HTTPClient http;
  String url = String(serverUrl) + "/orders/fail";
  String jsonPayload = "{\"orderId\":\"" + tempOrderId +
                      "\",\"vendingMachineId\":\"" + String(vendingMachineId) +
                      "\",\"reason\":\"" + reason + "\"," +
                      "\"details\":{" +
                      "\"totalExpected\":" + String(totalExpected) + "," +
                      "\"totalDispensed\":" + String(totalDispensed) + "," +
                      "\"completionPercentage\":" + String(completionPercentage) + "," +
                      "\"timestamp\":" + String(millis()) +
                      "}}";
  Serial.print("Sending failure request to: ");
  Serial.println(url);
  Serial.print("With payload: ");
  Serial.println(jsonPayload);

  bool httpSuccess = false;
  for (int attempt = 1; attempt <= 2; attempt++) {
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    int httpResponseCode = http.POST(jsonPayload);
    String response = http.getString();
    
    Serial.println("Attempt " + String(attempt) + " - HTTP Response code: " + String(httpResponseCode));
    Serial.println("Response: " + response);

    if (httpResponseCode == 200) {
      Serial.println("✓ Order failure successfully logged");
      httpSuccess = true;
      break;
    } else {
      Serial.println("✗ Error logging order failure on attempt " + String(attempt));
      if (attempt < 2) {
        Serial.println("Retrying...");
        delay(1000); // Wait 1 second before retry
      }
    }
    http.end();
  }

  if (!httpSuccess) {
    Serial.println("✗ Failed to log order failure after 2 attempts. Order state already reset to prevent lock");
  }

  // Reset orderId after HTTP attempt
  currentOrderId = "";
  Serial.println("OrderId reset. Failure handling complete");
  Serial.println("===================================\n");
}

bool dispenseSingleItem(int couloir) {
  Serial.println("\n--- Dispensing Single Item ---");
  Serial.println("Chariot/Couloir: " + String(couloir));

  String chariotId = "CHARIOT" + String(couloir);
  int relayPin = getRelayPinForChariot(chariotId);
  if (relayPin == -1) {
    Serial.println("ERROR: Invalid chariot ID: " + chariotId);
    return false;
  }

  const unsigned long DETECTION_TIMEOUT = 3000;
  const int MIN_DETECTION_TIME_MS = 50;
  Serial.println("Dispensing item from chariot: " + String(couloir) + " using relay pin: " + String(relayPin));

  pinMode(relayPin, OUTPUT);

  unsigned long activationStartTime = millis();
  Serial.println("Activating relay " + String(relayPin) + " for couloir " + String(couloir) + " at " + String(activationStartTime) + "ms");

  digitalWrite(relayPin, LOW);
  Serial.print("Keeping relay active for 1500ms: ");
  for (int i = 0; i < 5; i++) {
    delay(300);
    Serial.print("●");
  }
  Serial.println(" Done!");

  unsigned long deactivationTime = millis();
  Serial.println("Deactivating relay " + String(relayPin) + " at " + String(deactivationTime) + "ms");
  digitalWrite(relayPin, HIGH);

  unsigned long productFallDelay = 1000;
  Serial.println("Waiting for product to fall for " + String(productFallDelay) + "ms");
  delay(productFallDelay);

  unsigned long startTime = millis();
  Serial.println("Starting detection window at " + String(startTime) + "ms for " + String(DETECTION_TIMEOUT) + "ms");

  bool productDetected = false;
  int detectedCouloir = 0;

  while (millis() - startTime < DETECTION_TIMEOUT) {
    detectedCouloir = detectItemCouloir();
    if (detectedCouloir > 0 && detectedCouloir == couloir) { // Ensure correct couloir
      Serial.println("\n▶ Potential detection at " + String(millis()) + "ms in couloir " + String(detectedCouloir));
      Serial.println("Verifying with multiple readings...");

      delay(MIN_DETECTION_TIME_MS);

      int confirmationReadings = 0;
      const int REQUIRED_CONFIRMATIONS = 3;
      const int TOTAL_READINGS = REQUIRED_CONFIRMATIONS + 3;

      for (int i = 0; i < TOTAL_READINGS; i++) {
        if (detectItemCouloir() == detectedCouloir) {
          confirmationReadings++;
          Serial.print("✓");
        } else {
          Serial.print("✗");
        }
        delay(15);
      }
      Serial.println();

      if (confirmationReadings >= REQUIRED_CONFIRMATIONS - 1) {
        productDetected = true;
        Serial.println("\n---------- PRODUCT DETECTED ----------");
        Serial.println("Product confirmed in couloir " + String(detectedCouloir) + " after " + String(millis() - startTime) + "ms");
        updateItemDetection(detectedCouloir);
        Serial.println("---------------------------------------");
        break;
      } else {
        Serial.println("False detection - only " + String(confirmationReadings) + "/" + String(TOTAL_READINGS) + " confirmations");
      }
    }
    delay(10);
  }

  if (!productDetected) {
    Serial.println("\n❌ FAILED: No product detected within " + String(DETECTION_TIMEOUT) + "ms for couloir " + String(couloir));
    return false;
  }

  return true;
}

int detectItemCouloir() {
  VL53L0X_RangingMeasurementData_t measure;
  lox.rangingTest(&measure, false);

  if (measure.RangeStatus != 4) {
    int distance = measure.RangeMilliMeter;
    Serial.println("VL53L0X reading: " + String(distance) + "mm");

    // Validate distance to prevent false positives
    if (distance < COULOIR1_MIN || distance > COULOIR4_MAX) {
      Serial.println("Distance out of valid range (" + String(distance) + "mm)");
      return 0;
    }

    if (distance >= COULOIR1_MIN && distance <= COULOIR1_MAX) {
      Serial.println("Distance " + String(distance) + "mm corresponds to COULOIR1");
      return 1;
    } else if (distance >= COULOIR2_MIN && distance <= COULOIR2_MAX) {
      Serial.println("Distance " + String(distance) + "mm corresponds to COULOIR2");
      return 2;
    } else if (distance >= COULOIR3_MIN && distance <= COULOIR3_MAX) {
      Serial.println("Distance " + String(distance) + "mm corresponds to COULOIR3");
      return 3;
    } else if (distance >= COULOIR4_MIN && distance <= COULOIR4_MAX) {
      Serial.println("Distance " + String(distance) + "mm corresponds to COULOIR4");
      return 4;
    }
  } else {
    Serial.println("VL53L0X: Out of range or invalid reading");
  }
  return 0;
}

void updateItemDetection(int detectedCouloir) {
  if (orderFailed) {
    Serial.println("\n--- Item Detection Ignored ---");
    Serial.println("Order has failed, ignoring detection in couloir " + String(detectedCouloir));
    return;
  }

  delay(1000);
  Serial.println("\n--- Item Detection Update ---");
  if (!orderInProgress || totalItemsInOrder == 0) {
    Serial.println("No active order to update");
    return;
  }

  bool productMatched = false;
  for (int i = 0; i < totalItemsInOrder; i++) {
    int couloir = currentOrder[i].couloir;
    int targetQuantity = currentOrder[i].quantity;
    int currentCount = currentOrder[i].detectedCount;

    Serial.println("\nProduct " + String(i + 1) + " Status:");
    Serial.println("Chariot/Couloir: " + String(couloir));
    Serial.println("Target quantity: " + String(targetQuantity));
    Serial.println("Current count: " + String(currentCount));

    if (currentOrder[i].couloir == detectedCouloir &&
        currentOrder[i].detectedCount < currentOrder[i].quantity) {
      currentOrder[i].detectedCount++;
      Serial.println("✓ Detected product from CORRECT couloir " + String(couloir));
      productMatched = true;

      bool allItemsDetected = true;
      for (int j = 0; j < totalItemsInOrder; j++) {
        if (currentOrder[j].detectedCount < currentOrder[j].quantity) {
          allItemsDetected = false;
          break;
        }
      }
      if (allItemsDetected && !orderFailed) {
        completeOrder();
      }
      break;
    }
  }

  if (!productMatched) {
    Serial.println("⚠ No exact couloir match found for detected product from couloir " + String(detectedCouloir));
    failOrder("Product detected in wrong couloir " + String(detectedCouloir));
  }
}

void completeOrder() {
  if (!orderInProgress || orderFailed) {
    Serial.println("Cannot complete order: No active order or order has failed");
    return;
  }

  unsigned long completionTime = millis();
  Serial.println("\n========== ORDER COMPLETION AT " + String(completionTime) + "ms ==========");
  Serial.println("Order ID: " + currentOrderId);
  Serial.println("Dispensed items summary:");

  int totalExpected = 0;
  int totalDispensed = 0;
  for (int i = 0; i < totalItemsInOrder; i++) {
    totalExpected += currentOrder[i].quantity;
    totalDispensed += currentOrder[i].detectedCount;
    Serial.println("- Couloir " + String(currentOrder[i].couloir) + ": " + 
                   String(currentOrder[i].detectedCount) + "/" + 
                   String(currentOrder[i].quantity) + " items detected ✓");
  }
  Serial.println("Total dispensed: " + String(totalDispensed) + "/" + String(totalExpected) + " items (100%)");
  Serial.println("Completion timestamp: " + String(completionTime) + "ms");

  HTTPClient http;
  String url = String(serverUrl) + "/hardware/dispense/complete";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  String jsonPayload = "{\"orderId\":\"" + currentOrderId +
                      "\",\"vendingMachineId\":\"" + String(vendingMachineId) + "\"," +
                      "\"details\":{" +
                      "\"totalDispensed\":" + String(totalDispensed) + "," +
                      "\"completionTimestamp\":" + String(completionTime) +
                      "}}";
  Serial.print("Sending request to: ");
  Serial.println(url);
  Serial.print("With payload: ");
  Serial.println(jsonPayload);

  int httpResponseCode = http.POST(jsonPayload);
  String response = http.getString();

  if (httpResponseCode == 200) {
    Serial.println("✓ Order completed successfully!");
    Serial.println("Response: " + response);

    String productDetectionUrl = String(serverUrl) + "/hardware/dispense/product-detected";
    http.begin(productDetectionUrl);
    http.addHeader("Content-Type", "application/json");

    String detectionPayload = "{\"orderId\":\"" + currentOrderId +
                             "\",\"couloir\":\"" + String(currentOrder[0].couloir) + "\"," +
                             "\"quantity\":" + String(totalDispensed) + "}";
    Serial.print("Sending product detection notification to: ");
    Serial.println(productDetectionUrl);
    Serial.print("With payload: ");
    Serial.println(detectionPayload);

    int detectionResponseCode = http.POST(detectionPayload);
    String detectionResponse = http.getString();
    if (detectionResponseCode == 200) {
      Serial.println("✓ Product detection notification sent successfully!");
      Serial.println("Response: " + detectionResponse);
    } else {
      Serial.println("⚠ Failed to send product detection notification: " + String(detectionResponseCode));
      Serial.println("Response: " + detectionResponse);
    }

    resetOrderState();
    Serial.println("Order state reset after completion");
  } else {
    Serial.println("✗ Error completing order. HTTP code: " + String(httpResponseCode));
    Serial.println("Error response: " + response);
    failOrder("Failed to complete order due to HTTP error");
  }
  http.end();
}

void processKeypadOrder() {
  if (!isAuthenticated) {
    Serial.println("Cannot process keypad order: User not authenticated");
    return;
  }
  if (selectedCouloir < 1 || selectedCouloir > 4) {
    Serial.println("Invalid couloir selected: " + String(selectedCouloir));
    return;
  }
  if (selectedQuantity < 1) {
    Serial.println("Invalid quantity selected: " + String(selectedQuantity));
    return;
  }

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
      String orderId = doc["orderId"].as<String>();
      currentOrderId = orderId;
      totalItemsInOrder = 1;
      currentOrder[0].couloir = selectedCouloir;
      currentOrder[0].quantity = selectedQuantity;
      currentOrder[0].detectedCount = 0;
      orderInProgress = true;
      orderFailed = false;
      orderStartTime = millis();
      Serial.println("Keypad order accepted. Starting processing for order ID: " + orderId);
      processActiveOrder();
    } else {
      Serial.println("Failed to parse keypad order response: " + response);
    }
  } else {
    String response = http.getString();
    Serial.println("Failed to create keypad order. HTTP code: " + String(httpResponseCode));
    Serial.println("Response: " + response);
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
      if (key == 'A') {
        if (isAuthenticated) {
          showCouloirPrompt();
        }
      } else if (key == '*') { // Manual reset via keypad for testing
        Serial.println("Manual order state reset triggered via keypad");
        resetOrderState();
        showWelcomeScreen();
      }
      break;
    case LcdState::ENTER_COULOIR:
      if (key >= '1' && key <= '4') {
        selectedCouloir = key - '0';
        showQuantityPrompt();
      } else if (key == '#') {
        showWelcomeScreen();
      }
      break;
    case LcdState::ENTER_QUANTITY:
      if (key >= '0' && key <= '9') {
        keypadBuffer += key;
      } else if (key == 'A') {
        if (keypadBuffer.length() > 0) {
          selectedQuantity = keypadBuffer.toInt();
          if (selectedQuantity > 0) {
            processKeypadOrder();
          } else {
            showQuantityPrompt();
          }
        }
      } else if (key == '#') {
        showCouloirPrompt();
      } else if (key == '*') {
        if (keypadBuffer.length() > 0) {
          keypadBuffer = keypadBuffer.substring(0, keypadBuffer.length() - 1);
        }
      }
      break;
    default:
      break;
  }
}

void testRelays() {
  Serial.println("\nTesting Relays...");
  for (int i = 1; i <= 4; i++) {
    int relayPin;
    switch (i) {
      case 1: relayPin = RELAY1; break;
      case 2: relayPin = RELAY2; break;
      case 3: relayPin = RELAY3; break;
      case 4: relayPin = RELAY4; break;
    }
    Serial.print("Turning ON Relay ");
    Serial.println(i);
    digitalWrite(relayPin, LOW);
    delay(1000);
    Serial.print("Turning OFF Relay ");
    Serial.println(i);
    digitalWrite(relayPin, HIGH);
    delay(1000);
  }
}

void testVL53L0X() {
  Serial.println("\nTesting VL53L0X...");
  VL53L0X_RangingMeasurementData_t measure;
  lox.rangingTest(&measure, false);
  if (measure.RangeStatus != 4) {
    Serial.print("Distance: ");
    Serial.print(measure.RangeMilliMeter);
    Serial.println(" mm");
  } else {
    Serial.println("Out of range");
  }
}

void testDHT11() {
  Serial.println("\nTesting DHT11...");
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  if (isnan(h) || isnan(t)) {
    Serial.println("Failed to read from DHT11!");
    return;
  }
  Serial.print("Humidity: ");
  Serial.print(h);
  Serial.print(" %\t");
  Serial.print("Temperature: ");
  Serial.print(t);
  Serial.println(" °C");
}

void testRFID() {
  Serial.println("\nTesting RFID...");
  if (!rfid.PICC_IsNewCardPresent()) {
    Serial.println("No card detected.");
    return;
  }
  if (!rfid.PICC_ReadCardSerial()) {
    Serial.println("Failed to read card.");
    return;
  }
  Serial.print("Card UID: ");
  for (byte i = 0; i < rfid.uid.size; i++) {
    Serial.print(rfid.uid.uidByte[i] < 0x10 ? " 0" : " ");
    Serial.print(rfid.uid.uidByte[i], HEX);
  }
  Serial.println();
  rfid.PICC_HaltA();
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
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Cannot check updates - WiFi not connected");
    return;
  }

  HTTPClient http;
  DynamicJsonDocument doc(2048);

  String productUrl = String(serverUrl) + "/product/with-stock";
  Serial.println("\n=== Checking Products with Stock ===");
  Serial.print("GET request to: ");
  Serial.println(productUrl);

  http.begin(productUrl);
  int productResponseCode = http.GET();
  Serial.print("Product response code: ");
  Serial.println(productResponseCode);

  if (productResponseCode == 200) {
    String productResponse = http.getString();
    Serial.print("Raw product response: ");
    Serial.println(productResponse);

    DeserializationError error = deserializeJson(doc, productResponse);
    if (!error) {
      JsonArray products = doc.as<JsonArray>();
      for (JsonVariant product : products) {
        Serial.println("\n--- Product Info ---");
        Serial.println("Name: " + product["name"].as<String>());
        Serial.println("Price: " + String(product["price"].as<float>()));
        Serial.println("Stock: " + String(product["stock"].as<int>()));
        if (product.containsKey("chariotId")) {
          Serial.println("Assigned to Chariot: " + product["chariotId"].as<String>());
        } else {
          Serial.println("Not assigned to any chariot");
        }
      }
    }
  }
  http.end();

  String chariotUrl = String(serverUrl) + "/chariot";
  Serial.println("\n=== Checking Chariots ===");
  Serial.print("GET request to: ");
  Serial.println(chariotUrl);

  http.begin(chariotUrl);
  int chariotResponseCode = http.GET();
  Serial.print("Chariot response code: ");
  Serial.println(chariotResponseCode);

  if (chariotResponseCode == 200) {
    String chariotResponse = http.getString();
    Serial.print("Raw chariot response: ");
    Serial.println(chariotResponse);

    doc.clear();
    DeserializationError error = deserializeJson(doc, chariotResponse);
    if (!error) {
      JsonArray chariots = doc.as<JsonArray>();
      for (JsonVariant chariot : chariots) {
        Serial.println("\n--- Chariot Info ---");
        Serial.println("ID: " + chariot["idd"].as<String>());
        Serial.println("Name: " + chariot["name"].as<String>());
        Serial.println("Status: " + chariot["status"].as<String>());
        if (chariot.containsKey("productType")) {
          Serial.println("Product Type: " + chariot["productType"].as<String>());
        }
      }
    }
  }
  http.end();
  Serial.println("\n=== Update Check Complete ===\n");
}

void resetOrderState() {
  Serial.println("\n=== Resetting Order State ===");
  orderInProgress = false;
  orderFailed = false;
  currentOrderId = "";
  currentUserId = "";
  totalItemsInOrder = 0;
  orderStartTime = 0;
  for (int i = 0; i < 4; i++) {
    currentOrder[i].couloir = 0;
    currentOrder[i].quantity = 0;
    currentOrder[i].detectedCount = 0;
  }
  Serial.println("Order state fully reset");
}

// Check for pending RFID registrations
void checkForRfidRegistration() {
  if (rfidRegistrationMode) {
    // Check if we've timed out waiting for an RFID card
    if (millis() - rfidRegistrationStartTime > RFID_REGISTRATION_TIMEOUT) {
      Serial.println("RFID registration timed out");
      rfidRegistrationMode = false;
      return;
    }
    
    // Continue in registration mode - the RFID card reading will be handled in loop()
    return;
  }
  
  // Not in registration mode, check if there are any pending registrations
  if (WiFi.status() != WL_CONNECTED) {
    return; // Can't check without WiFi
  }
  
  static unsigned long lastRegistrationCheck = 0;
  if (millis() - lastRegistrationCheck < 5000) {
    return; // Don't check too frequently
  }
  
  lastRegistrationCheck = millis();
  
  HTTPClient http;
  String url = String(serverUrl) + "/user/rfid/check-pending";
  http.begin(url);
  
  int httpCode = http.GET();
  if (httpCode == 200) {
    String response = http.getString();
    Serial.println("Pending RFID registration response: " + response);
    
    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, response);
    if (!error) {
      if (doc.containsKey("pendingRegistrations") && doc["pendingRegistrations"].size() > 0) {
        // Get the first pending registration
        String userId = doc["pendingRegistrations"][0]["userId"];
        Serial.println("Found pending RFID registration for user: " + userId);
        
        // Enter registration mode
        rfidRegistrationMode = true;
        rfidRegistrationStartTime = millis();
        
        // Store the user ID we're registering for
        currentUserId = userId;
        
        Serial.println("Entered RFID registration mode. Please scan card within 2 minutes.");
      }
    }
  }
  http.end();
}

// Process an RFID card for registration
void processRfidRegistration(String cardUID) {
  Serial.println("Processing RFID registration for card: " + cardUID);
  
  if (!rfidRegistrationMode || currentUserId.isEmpty()) {
    Serial.println("Not in registration mode or missing user ID");
    return;
  }
  
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Cannot register RFID - WiFi not connected");
    return;
  }
  
  HTTPClient http;
  String url = String(serverUrl) + "/user/rfid/complete";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  String jsonPayload = "{\"userId\":\"" + currentUserId + 
                     "\",\"rfidUID\":\"" + cardUID + "\"}";
  
  Serial.println("Sending RFID registration request: " + jsonPayload);
  
  int httpCode = http.POST(jsonPayload);
  String response = http.getString();
  
  Serial.println("RFID registration response code: " + String(httpCode));
  Serial.println("Response: " + response);
  
  if (httpCode == 200) {
    Serial.println("RFID registration successful!");
    // Flash LEDs or display success message on LCD if available
  } else {
    Serial.println("RFID registration failed!");
    // Flash error pattern on LEDs or display error on LCD if available
  }
  
  // Exit registration mode
  rfidRegistrationMode = false;
  currentUserId = "";
  
  http.end();
}

void loop() {
  static unsigned long lastOrderCheck = 0;
  static unsigned long lastProductCheck = 0;

  // Check for RFID registration requests
  checkForRfidRegistration();
  
  // Check for stuck order
  if (orderInProgress && millis() - orderStartTime > ORDER_TIMEOUT_MS) {
    Serial.println("\n=== ERROR: Order stuck for over " + String(ORDER_TIMEOUT_MS / 1000) + " seconds ===");
    Serial.println("Order ID: " + currentOrderId);
    failOrder("Order timed out after " + String(ORDER_TIMEOUT_MS / 1000) + " seconds");
  }

  if (WiFi.status() == WL_CONNECTED) {
    if (millis() - lastOrderCheck > 2000) {
      if (!orderInProgress && millis() >= orderCooldownUntil) {
        Serial.println("\n=== Checking for new orders to dispense ===");
        checkForApiOrders();
      } else if (orderInProgress) {
        Serial.println("Order in progress - skipping order check");
      } else if (millis() < orderCooldownUntil) {
        unsigned long remainingCooldown = (orderCooldownUntil - millis()) / 1000;
        Serial.println("In cooldown period - " + String(remainingCooldown) + " seconds remaining");
      }
      lastOrderCheck = millis();
    }
    if (millis() - lastProductCheck > 5000) {
      checkProductUpdates();
      lastProductCheck = millis();
    }
  }

  static unsigned long lastEnvironmentUpdate = 0;
  if (WiFi.status() == WL_CONNECTED && millis() - lastEnvironmentUpdate > 60000) {
    sendEnvironmentData();
    lastEnvironmentUpdate = millis();
  }

  char key = getKey();
  if (key != '\0') {
    Serial.print("Key pressed: ");
    Serial.println(key);
    handleKeypadInput(key);
  }
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
      } else {
        // Normal authentication flow
        if (authenticateCard(cardUID)) {
          isAuthenticated = true;
        }
      }
    }
    rfid.PICC_HaltA();
  }

  static unsigned long lastProductUpdateCheck = 0;
  if (WiFi.status() == WL_CONNECTED && millis() - lastProductUpdateCheck > 30000) {
    checkProductUpdates();
    lastProductUpdateCheck = millis();
  }

  // Check for RFID registration
  checkForRfidRegistration();

  // Handle RFID registration processing
  if (rfidRegistrationMode && rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    String cardUID = "";
    for (byte i = 0; i < rfid.uid.size; i++) {
      cardUID += (rfid.uid.uidByte[i] < 0x10 ? "0" : "");
      cardUID += String(rfid.uid.uidByte[i], HEX);
    }
    Serial.print("RFID Card UID for registration: ");
    Serial.println(cardUID);

    processRfidRegistration(cardUID);

    rfid.PICC_HaltA();
  }

  delay(100);
}