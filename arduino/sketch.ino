#include <Wire.h>
#include <Adafruit_VL53L0X.h>
#include <DHT.h>
#include <MFRC522.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
//#include <LiquidCrystal_I2C.h> // Commented out as LCD is not plugged

// Pin definitions
// Relay Module
#define RELAY1 26
#define RELAY2 25
#define RELAY3 33
#define RELAY4 32

// VL53L0X (I2C, pins defined by Wire library)
Adafruit_VL53L0X lox = Adafruit_VL53L0X();

// DHT11
#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// RFID (MFRC522)
#define RST_PIN 0
#define SS_PIN 5
MFRC522 rfid(SS_PIN, RST_PIN);

// LCD I2C Display
//LiquidCrystal_I2C lcd(0x27, 16, 2); // Commented out as LCD is not plugged

// Keypad
const byte ROWS = 4;
const byte COLS = 4;
byte rowPins[ROWS] = {12, 13, 14, 27}; // Rows
byte colPins[COLS] = {15, 2, 16, 17};  // Columns
char keys[ROWS][COLS] = {
  {'1', '2', '3', 'A'},
  {'4', '5', '6', 'B'},
  {'7', '8', '9', 'C'},
  {'*', '0', '#', 'D'}
};

// WiFi credentials
const char* ssid = "STARLINK";     // WiFi SSID
const char* password = "12875ody"; // WiFi password

// Backend API
// Using 10.0.2.2 which points to host machine's localhost from Android emulator
const char* serverUrl = "http://10.0.2.2:5000"; // For Android emulator testing
// const char* serverUrl = "http://192.168.12.32:5000"; // Uncomment for hardware testing on host network
const char* vendingMachineId = "VM001";         // We only have one machine, keeping simple ID

// Range definitions for columns (couloirs)
const int COULOIR1_MIN = 50;
const int COULOIR1_MAX = 150;
const int COULOIR2_MIN = 150;
const int COULOIR2_MAX = 250;
const int COULOIR3_MIN = 250;
const int COULOIR3_MAX = 350;
const int COULOIR4_MIN = 350;
const int COULOIR4_MAX = 450;

// Order tracking
struct OrderItem {
  int couloir;
  int quantity;
  int detectedCount;
};

// Max 4 different products in an order
OrderItem currentOrder[4];
int totalItemsInOrder = 0;
bool orderInProgress = false;
String currentOrderId = "";
String currentUserId = "";

// LCD state management
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

// Keypad input buffer
String keypadBuffer = "";

// Authentication state
bool isAuthenticated = false;

void setup() {
  // Initialize Serial Monitor
  Serial.begin(115200);
  while (!Serial) {
    delay(1); // Wait for serial port to connect
  }
  Serial.println("ESP32 Vending Machine Starting...");

  // Initialize Relays
  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);
  pinMode(RELAY3, OUTPUT);
  pinMode(RELAY4, OUTPUT);
  digitalWrite(RELAY1, HIGH); // Relays off (assuming active-low)
  digitalWrite(RELAY2, HIGH);
  digitalWrite(RELAY3, HIGH);
  digitalWrite(RELAY4, HIGH);
  Serial.println("Relays initialized.");

  // Initialize VL53L0X
  if (!lox.begin()) {
    Serial.println("Failed to initialize VL53L0X!");
    while (1);
  }
  Serial.println("VL53L0X initialized.");

  // Initialize DHT11
  dht.begin();
  Serial.println("DHT11 initialized.");
  
  // Test DHT sensor to make sure it's working
  float testHumidity = dht.readHumidity();
  float testTemp = dht.readTemperature();
  
  if (isnan(testHumidity) || isnan(testTemp)) {
    Serial.println("WARNING: Failed to read from DHT sensor! Check wiring.");
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("DHT Sensor Error");
    lcd.setCursor(0, 1);
    lcd.print("Check wiring!");
    delay(2000);*/ // Commented out as LCD is not plugged
  } else {
    Serial.print("DHT Test - Temp: ");
    Serial.print(testTemp);
    Serial.print("°C, Humidity: ");
    Serial.print(testHumidity);
    Serial.println("%");
  }

  // Initialize LCD
  /*lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Vending Machine");
  lcd.setCursor(0, 1);
  lcd.print("Initializing...");
  Serial.println("LCD initialized.");*/ // Commented out as LCD is not plugged

  // Initialize RFID
  SPI.begin(); // Initialize SPI bus
  rfid.PCD_Init(); // Initialize MFRC522
  Serial.println("RFID initialized.");

  // Initialize Keypad
  for (byte i = 0; i < ROWS; i++) {
    pinMode(rowPins[i], OUTPUT);
    digitalWrite(rowPins[i], HIGH); // Default high
  }
  for (byte i = 0; i < COLS; i++) {
    pinMode(colPins[i], INPUT_PULLUP); // Enable internal pull-ups
  }
  Serial.println("Keypad initialized.");

  // Run tests once at startup
  testRelays();
  testVL53L0X();
  testDHT11();
  testRFID();

  // Connect to WiFi using our improved setup function
  setupWiFi();

  // Register this machine with the backend
  if (WiFi.status() == WL_CONNECTED) {
    registerMachine();
    // Send initial environment data
    sendEnvironmentData();
  }

  // Show welcome screen
  showWelcomeScreen();
}

void showWelcomeScreen() {
  lcdState = LcdState::WELCOME;
  /*lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Scan RFID Card");
  lcd.setCursor(0, 1);
  lcd.print("To Start");*/ // Commented out as LCD is not plugged
}

void registerMachine() {
  HTTPClient http;
  String url = String(serverUrl) + "/hardware/register";

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  // Prepare JSON payload - simplified since we only have one machine
  String jsonPayload = "{\"vendingMachineId\":\"" + String(vendingMachineId) +
                      "\",\"name\":\"Main Vending Machine\"}";

  int httpResponseCode = http.POST(jsonPayload);

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println("Machine registration successful!");
    Serial.println("HTTP Response code: " + String(httpResponseCode));
    Serial.println("Register response: " + response);
    
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Machine");
    lcd.setCursor(0, 1);
    lcd.print("Registered: VM001");
    delay(2000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
  } else {
    Serial.print("Registration failed. Error code: ");
    Serial.println(httpResponseCode);
    
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Registration");
    lcd.setCursor(0, 1);
    lcd.print("Failed: " + String(httpResponseCode));
    delay(2000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
  }

  http.end();
}

void sendEnvironmentData() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  // Debug output
  Serial.println("Reading DHT sensor...");
  Serial.print("Humidity: ");
  Serial.print(h);
  Serial.print("%, Temperature: ");
  Serial.print(t);
  Serial.println("°C");

  if (isnan(h) || isnan(t)) {
    Serial.println("Failed to read from DHT sensor! Check wiring and make sure sensor is plugged in.");
    // Display error on LCD
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("DHT Sensor Error");
    lcd.setCursor(0, 1);
    lcd.print("Check wiring");
    delay(2000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
    return;
  }

  // Check if values are within reasonable range
  if (h < 0 || h > 100 || t < -40 || t > 80) {
    Serial.println("DHT sensor returned unreasonable values. Possible sensor fault.");
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Sensor Error");
    lcd.setCursor(0, 1);
    lcd.print("Bad values");
    delay(2000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
    return;
  }

  // Check if WiFi is connected
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected. Cannot send environment data.");
    // Try to reconnect
    setupWiFi();
    if (WiFi.status() != WL_CONNECTED) {
      return;
    }
  }

  HTTPClient http;
  String url = String(serverUrl) + "/hardware/environment";
  
  Serial.print("Sending environment data to: ");
  Serial.println(url);

  http.begin(url);  http.addHeader("Content-Type", "application/json");

  // Prepare JSON payload without vendingMachineId (backend now handles this automatically)
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
    
    // Check for temperature and humidity alerts
    bool tempAlert = (t > 30 || t < 10);
    bool humidityAlert = (h > 70 || h < 20);
    
    // Show environment data on LCD with alert indicators
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("T:");
    lcd.print(t, 1);
    lcd.print("C ");
    lcd.print(tempAlert ? "!" : " ");
    lcd.print(" H:");
    lcd.print(h, 1);
    lcd.print("%");
    lcd.print(humidityAlert ? "!" : " ");
    lcd.setCursor(0, 1);
    lcd.print("Data sent OK");
    delay(3000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
  } else {
    Serial.print("Error sending environment data. Code: ");
    Serial.println(httpResponseCode);
    
    // Show error on LCD briefly
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Send Data Error");
    lcd.setCursor(0, 1);
    lcd.print("Code: " + String(httpResponseCode));
    delay(2000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
  }

  http.end();
}

bool authenticateCard(String cardUID) {
  // Call backend API to validate the card
  HTTPClient http;
  String url = String(serverUrl) + "/hardware/auth/rfid";

  http.begin(url);  http.addHeader("Content-Type", "application/json");

  // Prepare JSON payload without vendingMachineId
  String jsonPayload = "{\"rfidUID\":\"" + cardUID + "\"}";

  int httpResponseCode = http.POST(jsonPayload);

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.println("HTTP Response code: " + String(httpResponseCode));
    Serial.println(response);

    // Parse JSON response
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
  if (WiFi.status() != WL_CONNECTED) return;

  // Call backend API to check for pending orders
  HTTPClient http;
  String url = String(serverUrl) + "/order/pending?vendingMachineId=" + String(vendingMachineId);

  http.begin(url);

  int httpResponseCode = http.GET();

  if (httpResponseCode == 200) {
    String response = http.getString();
    Serial.println("Pending order found: " + response);

    // Parse JSON response
    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, response);

    if (!error && doc.containsKey("orderId")) {
      // We have a pending order
      currentOrderId = doc["orderId"].as<String>();
      currentUserId = doc["userId"].as<String>();
      
      // Reset order tracking
      totalItemsInOrder = 0;
      for (int i = 0; i < 4; i++) {
        currentOrder[i].couloir = 0;
        currentOrder[i].quantity = 0;
        currentOrder[i].detectedCount = 0;
      }
      
      // Process products
      JsonArray products = doc["products"].as<JsonArray>();
      int orderIndex = 0;
      
      for (JsonVariant product : products) {
        int couloir = product["couloir"].as<int>();
        int quantity = product["quantity"].as<int>();
        
        if (orderIndex < 4) {
          currentOrder[orderIndex].couloir = couloir;
          currentOrder[orderIndex].quantity = quantity;
          orderIndex++;
        }
      }
      
      totalItemsInOrder = orderIndex;
      orderInProgress = true;
      
      // Show processing order on LCD
      /*lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Order received");
      lcd.setCursor(0, 1);
      lcd.print("Processing...");*/ // Commented out as LCD is not plugged
      
      // Start dispensing all products
      processActiveOrder();
    }
  }

  http.end();
}

void processActiveOrder() {
  if (!orderInProgress || totalItemsInOrder == 0) return;

  /*lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Dispensing items");*/ // Commented out as LCD is not plugged

  // Dispense all products in order
  for (int i = 0; i < totalItemsInOrder; i++) {
    int couloir = currentOrder[i].couloir;
    int quantity = currentOrder[i].quantity;

    /*lcd.setCursor(0, 1);
    lcd.print("Couloir ");
    lcd.print(couloir);
    lcd.print(": ");
    lcd.print(quantity);
    lcd.print(" item(s)");*/ // Commented out as LCD is not plugged

    // Dispense each item in the quantity specified
    for (int j = 0; j < quantity; j++) {
      // Activate the corresponding relay
      dispenseSingleItem(couloir);
      
      // Wait for item to be detected by VL53L0X
      delay(500); // Give time for item to fall
    }
  }
}

void dispenseSingleItem(int couloir) {
  int relayPin;

  switch (couloir) {
    case 1: relayPin = RELAY1; break;
    case 2: relayPin = RELAY2; break;
    case 3: relayPin = RELAY3; break;
    case 4: relayPin = RELAY4; break;
    default: return; // Invalid couloir
  }

  // Activate relay for 1 second to dispense item
  digitalWrite(relayPin, LOW); // Assuming active-low relay
  delay(1000);
  digitalWrite(relayPin, HIGH);
}

int detectItemCouloir() {
  VL53L0X_RangingMeasurementData_t measure;
  lox.rangingTest(&measure, false); // Pass false for non-blocking

  if (measure.RangeStatus != 4) { // 4 means out of range
    int distance = measure.RangeMilliMeter;

    // Determine which couloir the item is from based on distance
    if (distance >= COULOIR1_MIN && distance <= COULOIR1_MAX) {
      return 1;
    } else if (distance >= COULOIR2_MIN && distance <= COULOIR2_MAX) {
      return 2;
    } else if (distance >= COULOIR3_MIN && distance <= COULOIR3_MAX) {
      return 3;
    } else if (distance >= COULOIR4_MIN && distance <= COULOIR4_MAX) {
      return 4;
    }
  }

  return 0; // No item detected or outside range
}

void updateItemDetection(int detectedCouloir) {
  if (!orderInProgress || detectedCouloir == 0) return;

  // Find the corresponding order item and update its detection count
  for (int i = 0; i < totalItemsInOrder; i++) {
    if (currentOrder[i].couloir == detectedCouloir &&
        currentOrder[i].detectedCount < currentOrder[i].quantity) {
      currentOrder[i].detectedCount++;

      // Display on LCD
      /*lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Item detected!");
      lcd.setCursor(0, 1);
      lcd.print("Couloir ");
      lcd.print(detectedCouloir);*/ // Commented out as LCD is not plugged
      
      // Check if all items in the order have been detected
      bool allItemsDetected = true;
      for (int j = 0; j < totalItemsInOrder; j++) {
        if (currentOrder[j].detectedCount < currentOrder[j].quantity) {
          allItemsDetected = false;
          break;
        }
      }
      
      if (allItemsDetected) {
        completeOrder();
      }
      
      break;
    }
  }
}

void completeOrder() {
  if (!orderInProgress) return;

  // Call API to complete the order
  HTTPClient http;
  String url = String(serverUrl) + "/order/complete";

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  // Prepare JSON payload
  String jsonPayload = "{\"orderId\":\"" + currentOrderId +
                      "\",\"vendingMachineId\":\"" + String(vendingMachineId) + "\"}";

  int httpResponseCode = http.POST(jsonPayload);

  if (httpResponseCode == 200) {
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Order complete!");
    lcd.setCursor(0, 1);
    lcd.print("Thank you!");*/ // Commented out as LCD is not plugged

    // Reset order state
    orderInProgress = false;
    currentOrderId = "";
    totalItemsInOrder = 0;

    /*delay(3000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
  } else {
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Error completing");
    lcd.setCursor(0, 1);
    lcd.print("order!");*/ // Commented out as LCD is not plugged

    /*delay(3000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
  }

  http.end();
}

void processKeypadOrder() {
  if (!isAuthenticated) {
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Please scan RFID");
    lcd.setCursor(0, 1);
    lcd.print("card first!");
    delay(2000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
    return;
  }

  if (selectedCouloir < 1 || selectedCouloir > 4) {
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Invalid couloir!");
    delay(2000);
    showCouloirPrompt();*/ // Commented out as LCD is not plugged
    return;
  }

  if (selectedQuantity < 1) {
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Invalid quantity!");
    delay(2000);
    showQuantityPrompt();*/ // Commented out as LCD is not plugged
    return;
  }

  // Show processing screen
  /*lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Processing order");
  lcd.setCursor(0, 1);
  lcd.print("Please wait...");*/ // Commented out as LCD is not plugged

  // Call API to process keypad order
  HTTPClient http;
  String url = String(serverUrl) + "/order/keypad";

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  // Prepare JSON payload
  String jsonPayload = "{\"userId\":\"" + currentUserId +
                      "\",\"vendingMachineId\":\"" + String(vendingMachineId) +
                      "\",\"couloir\":" + String(selectedCouloir) +
                      ",\"quantity\":" + String(selectedQuantity) + "}";

  int httpResponseCode = http.POST(jsonPayload);

  if (httpResponseCode == 201) {
    String response = http.getString();
    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, response);

    if (!error) {
      String orderId = doc["orderId"].as<String>();
      currentOrderId = orderId;
      
      // Reset order tracking
      totalItemsInOrder = 1;
      currentOrder[0].couloir = selectedCouloir;
      currentOrder[0].quantity = selectedQuantity;
      currentOrder[0].detectedCount = 0;
      orderInProgress = true;
      
      // Start dispensing
      processActiveOrder();
    } else {
      /*lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Error processing");
      lcd.setCursor(0, 1);
      lcd.print("order!");
      delay(3000);
      showWelcomeScreen();*/ // Commented out as LCD is not plugged
    }
  } else {
    String response = http.getString();
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Order failed!");
    lcd.setCursor(0, 1);*/ // Commented out as LCD is not plugged

    // Try to extract error message
    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, response);
    if (!error && doc.containsKey("message")) {
      String errorMsg = doc["message"].as<String>();
      // Truncate if needed to fit LCD
      if (errorMsg.length() > 16) {
        errorMsg = errorMsg.substring(0, 15) + ".";
      }
      /*lcd.print(errorMsg);*/ // Commented out as LCD is not plugged
    } else {
      /*lcd.print("Error code: ");
      lcd.print(httpResponseCode);*/ // Commented out as LCD is not plugged
    }

    /*delay(3000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
  }

  http.end();
}

void showCouloirPrompt() {
  lcdState = LcdState::ENTER_COULOIR;
  keypadBuffer = "";

  /*lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Enter couloir:");
  lcd.setCursor(0, 1);
  lcd.print("(1-4)> ");*/ // Commented out as LCD is not plugged
}

void showQuantityPrompt() {
  lcdState = LcdState::ENTER_QUANTITY;
  keypadBuffer = "";

  /*lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Enter quantity:");
  lcd.setCursor(0, 1);
  lcd.print("> ");*/ // Commented out as LCD is not plugged
}

void handleKeypadInput(char key) {
  switch (lcdState) {
    case LcdState::WELCOME:
      if (key == 'A') {
        if (isAuthenticated) {
          showCouloirPrompt();
        } else {
          /*lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Please scan RFID");
          lcd.setCursor(0, 1);
          lcd.print("card first!");
          delay(2000);
          showWelcomeScreen();*/ // Commented out as LCD is not plugged
        }
      }
      break;

    case LcdState::ENTER_COULOIR:
      if (key >= '1' && key <= '4') {
        selectedCouloir = key - '0';
        /*lcd.setCursor(7, 1);
        lcd.print(selectedCouloir);
        delay(1000);*/ // Commented out as LCD is not plugged
        showQuantityPrompt();
      } else if (key == '#') {
        showWelcomeScreen();
      }
      break;
      
    case LcdState::ENTER_QUANTITY:
      if (key >= '0' && key <= '9') {
        keypadBuffer += key;
        /*lcd.setCursor(2, 1);
        lcd.print(keypadBuffer);*/ // Commented out as LCD is not plugged
      } else if (key == 'A') {
        if (keypadBuffer.length() > 0) {
          selectedQuantity = keypadBuffer.toInt();
          if (selectedQuantity > 0) {
            processKeypadOrder();
          } else {
            /*lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Invalid quantity!");
            delay(2000);
            showQuantityPrompt();*/ // Commented out as LCD is not plugged
          }
        }
      } else if (key == '#') {
        showCouloirPrompt();
      } else if (key == '*') {
        // Backspace
        if (keypadBuffer.length() > 0) {
          keypadBuffer = keypadBuffer.substring(0, keypadBuffer.length() - 1);
          /*lcd.setCursor(2, 1);
          lcd.print(keypadBuffer + "    "); // Clear extra characters*/ // Commented out as LCD is not plugged
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
    digitalWrite(relayPin, LOW); // Assuming active-low
    delay(1000); // On for 1 second
    Serial.print("Turning OFF Relay ");
    Serial.println(i);
    digitalWrite(relayPin, HIGH);
    delay(1000); // Off for 1 second
  }
}

void testVL53L0X() {
  Serial.println("\nTesting VL53L0X...");
  VL53L0X_RangingMeasurementData_t measure;
  lox.rangingTest(&measure, false); // Pass false for non-blocking
  if (measure.RangeStatus != 4) {  // 4 means out of range
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
  float t = dht.readTemperature(); // Celsius
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
  // Look for new cards
  if (!rfid.PICC_IsNewCardPresent()) {
    Serial.println("No card detected.");
    return;
  }
  // Select one of the cards
  if (!rfid.PICC_ReadCardSerial()) {
    Serial.println("Failed to read card.");
    return;
  }
  // Print card UID
  Serial.print("Card UID: ");
  for (byte i = 0; i < rfid.uid.size; i++) {
    Serial.print(rfid.uid.uidByte[i] < 0x10 ? " 0" : " ");
    Serial.print(rfid.uid.uidByte[i], HEX);
  }
  Serial.println();
  // Halt PICC
  rfid.PICC_HaltA();
}

char getKey() {
  for (byte r = 0; r < ROWS; r++) {
    digitalWrite(rowPins[r], LOW); // Activate row
    for (byte c = 0; c < COLS; c++) {
      if (digitalRead(colPins[c]) == LOW) {
        // Wait for key release
        while (digitalRead(colPins[c]) == LOW);
        digitalWrite(rowPins[r], HIGH); // Deactivate row
        return keys[r][c];
      }
    }
    digitalWrite(rowPins[r], HIGH); // Deactivate row
  }
  return '\0'; // No key pressed
}

// Setup and connect to WiFi with retry logic
void setupWiFi() {
  // Check if already connected
  if (WiFi.status() == WL_CONNECTED) {
    return;
  }
  
  /*lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Connecting WiFi");
  lcd.setCursor(0, 1);
  lcd.print("SSID: ");
  lcd.print(ssid);*/ // Commented out as LCD is not plugged
  
  Serial.println();
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  
  // Disconnect if previously connected
  WiFi.disconnect();
  delay(1000);
  
  // Start connection attempt
  WiFi.begin(ssid, password);
  
  // Wait for connection with timeout
  int attempts = 0;
  int maxAttempts = 20; // 20 * 500ms = 10 seconds timeout
  
  while (WiFi.status() != WL_CONNECTED && attempts < maxAttempts) {
    delay(500);
    Serial.print(".");
    /*lcd.setCursor(attempts % 16, 1);
    lcd.print(".");*/ // Commented out as LCD is not plugged
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.print("Connected to WiFi. IP address: ");
    Serial.println(WiFi.localIP());
    
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi Connected");
    lcd.setCursor(0, 1);
    lcd.print(WiFi.localIP().toString());
    delay(2000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
  } else {
    Serial.println();
    Serial.println("Failed to connect to WiFi");
    
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("WiFi Failed");
    lcd.setCursor(0, 1);
    lcd.print("Check settings");
    delay(2000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
  }
}

void loop() {
  // Periodically check pending orders from API
  static unsigned long lastOrderCheck = 0;
  if (WiFi.status() == WL_CONNECTED && millis() - lastOrderCheck > 10000) { // Every 10 seconds
    if (!orderInProgress) {
      checkForApiOrders();
    }
    lastOrderCheck = millis();
  }

  // Periodically send environment data
  static unsigned long lastEnvironmentUpdate = 0;
  if (WiFi.status() == WL_CONNECTED && millis() - lastEnvironmentUpdate > 60000) { // Every minute
    sendEnvironmentData();
    lastEnvironmentUpdate = millis();
  }

  // Handle keypad input
  char key = getKey();
  if (key != '\0') {
    Serial.print("Key pressed: ");
    Serial.println(key);
    handleKeypadInput(key);
  }

  // Handle RFID card scan
  if (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial()) {
    String cardUID = "";
    for (byte i = 0; i < rfid.uid.size; i++) {
      cardUID += (rfid.uid.uidByte[i] < 0x10 ? "0" : "");
      cardUID += String(rfid.uid.uidByte[i], HEX);
    }

    Serial.print("Card UID: ");
    Serial.println(cardUID);

    // Authenticate card
    if (WiFi.status() == WL_CONNECTED) {
      /*lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Authenticating...");*/ // Commented out as LCD is not plugged
      
      if (authenticateCard(cardUID)) {
        isAuthenticated = true;
        /*lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Welcome!");
        lcd.setCursor(0, 1);
        lcd.print("Press A to start");*/ // Commented out as LCD is not plugged
      } else {
        /*lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Invalid card!");
        delay(2000);
        showWelcomeScreen();*/ // Commented out as LCD is not plugged
      }
    } else {
      // Offline mode - can't authenticate
      /*lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Offline mode");
      lcd.setCursor(0, 1);
      lcd.print("Can't auth card");
      delay(2000);
      showWelcomeScreen();*/ // Commented out as LCD is not plugged
    }

    rfid.PICC_HaltA();
  }

  // If an order is in progress, check for dropped items
  if (orderInProgress) {
    int detectedCouloir = detectItemCouloir();
    if (detectedCouloir > 0) {
      updateItemDetection(detectedCouloir);
    }
  }

  delay(100); // Small delay to prevent overwhelming the processor
}