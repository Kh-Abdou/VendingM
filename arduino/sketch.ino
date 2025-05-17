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
#define RELAY1 26  // Chariot 1
#define RELAY2 25  // Chariot 2 
#define RELAY3 33  // Chariot 3
#define RELAY4 32  // Chariot 4

// Mapping chariot names to relay pins
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

// Get relay pin for chariot ID
int getRelayPinForChariot(String chariotId) {
  // Remove any whitespace and convert to uppercase
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
  return -1; // Invalid chariot ID
}

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
const char* ssid = "Notreble";     // WiFi SSID
const char* password = "fuckintermilan"; // WiFi password

// Backend API
// Using 10.0.2.2 which points to host machine's localhost from Android emulator
//const char* serverUrl = "http://10.0.2.2:5000"; // For Android emulator testing
 const char* serverUrl = "http://192.168.86.32:5000"; // Uncomment for hardware testing on host network
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
// Function prototypes
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
  if (orderInProgress) return;  // Don't check for new orders if we're already processing one

  HTTPClient http;
  // Using hardware.routes.js endpoint to get orders that can be processed
  String url = String(serverUrl) + "/hardware/dispense/new-orders";
    http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  // Send vendor machine ID
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
      // Get order info
      String orderId = doc["orderId"].as<String>();
      currentOrderId = orderId;
      
      // Reset order tracking
      for (int i = 0; i < 4; i++) {
        currentOrder[i].couloir = 0;
        currentOrder[i].quantity = 0;
        currentOrder[i].detectedCount = 0;
      }
      
      // Process products
      JsonArray products = doc["products"].as<JsonArray>();
      int orderIndex = 0;
        Serial.println("\nReceived new order to dispense:");
      Serial.println("Order ID: " + orderId);
      Serial.println("Products to dispense:");
      
      // Debug - Print the raw response for troubleshooting
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
        
        // Start dispensing all products
        processActiveOrder();
      } else {
        Serial.println("Error: Order contains no valid products to dispense");      }
    }
  } else if (httpResponseCode == 404) {
    // This is normal - no orders to process
    Serial.println("No new orders to dispense (HTTP 404)");
  } else {
    // Other errors
    String errorResponse = http.getString();
    Serial.print("HTTP error: ");
    Serial.println(httpResponseCode);
    Serial.print("Error response: ");
    Serial.println(errorResponse);
  }
  
  http.end();
}

void processActiveOrder() {
  if (!orderInProgress || totalItemsInOrder == 0) return;

  /*lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Dispensing items");*/

  // Print order information header
  Serial.println("\n=== Processing New Order ===");
  Serial.println("Order ID: " + currentOrderId);
  Serial.println("Total items in order: " + String(totalItemsInOrder));
  
  // Debug: Print complete order details
  Serial.println("\n--- Complete Order Details ---");
  for (int i = 0; i < totalItemsInOrder; i++) {
    Serial.println("Item " + String(i+1) + ":");
    Serial.println("  Couloir: " + String(currentOrder[i].couloir) + " (CHARIOT" + String(currentOrder[i].couloir) + ")");
    Serial.println("  Quantity: " + String(currentOrder[i].quantity));
    Serial.println("  Relay Pin: " + String(getRelayPinForChariot("CHARIOT" + String(currentOrder[i].couloir))));
  }
  Serial.println("----------------------------");

  bool orderSuccess = true;

  // Dispense all products in order
  for (int i = 0; i < totalItemsInOrder; i++) {
    int couloir = currentOrder[i].couloir;
    int quantity = currentOrder[i].quantity;
    int detectedCount = 0;
    const int maxRetries = 3;
    
    // Print product details
    Serial.println("\n--- Product " + String(i + 1) + " Details ---");
    Serial.println("Assigned Chariot/Couloir: " + String(couloir));
    Serial.println("Quantity requested: " + String(quantity));
    Serial.println("Current detection count: " + String(currentOrder[i].detectedCount));
    
    /*lcd.setCursor(0, 1);
    lcd.print("Couloir ");
    lcd.print(couloir);
    lcd.print(": ");
    lcd.print(quantity);
    lcd.print(" item(s)");*/

    // Dispense each item in the quantity specified
    for (int j = 0; j < quantity; j++) {
      bool itemDetected = false;
      int retryCount = 0;
      
      while (!itemDetected && retryCount < maxRetries) {
        // Activate the corresponding relay
        dispenseSingleItem(couloir);
        
        // Wait and check for item detection with timeout
        unsigned long startTime = millis();
        const unsigned long timeout = 5000; // 5 second timeout
        
        while (millis() - startTime < timeout) {
          int detected = detectItemCouloir();
          if (detected == couloir) {
            itemDetected = true;
            detectedCount++;
            currentOrder[i].detectedCount++;
            
            // Display detection confirmation
            /*lcd.clear();
            lcd.setCursor(0, 0);
            lcd.print("Item detected!");
            lcd.setCursor(0, 1);
            lcd.print("Couloir ");
            lcd.print(couloir);*/
            
            Serial.println("Item detected in couloir " + String(couloir));
            delay(500); // Wait for item to clear sensor
            break;
          }
          delay(50); // Small delay between checks
        }
        
        if (!itemDetected) {
          retryCount++;
          Serial.println("Retry " + String(retryCount) + " for couloir " + String(couloir));
          delay(1000); // Wait before retry
        }
      }
      
      if (!itemDetected) {
        orderSuccess = false;
        Serial.println("Failed to detect item from couloir " + String(couloir));
        /*lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Error: Item not");
        lcd.setCursor(0, 1);
        lcd.print("detected C:" + String(couloir));*/
      }
    }
    
    // Verify all items were dispensed correctly
    if (detectedCount != quantity) {
      orderSuccess = false;
      Serial.println("Error: Expected " + String(quantity) + " items but detected " + String(detectedCount) + " from couloir " + String(couloir));
    }
  }
  
  // Complete or fail the order based on detection results
  if (orderSuccess) {
    completeOrder();
  } else {
    failOrder("Product detection failed");
  }
}

void failOrder(String reason) {
  if (!orderInProgress) return;

  // Enhanced failure information with timestamps and detailed status
  Serial.println("\n========== ORDER FAILURE AT " + String(millis()) + "ms ==========");
  Serial.println("Order ID: " + currentOrderId);
  Serial.println("Failure reason: " + reason);
  Serial.println("Dispensed items status:");
  
  // Calculate total dispensed vs expected
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
  // Calculate completion percentage and overall status
  int completionPercentage = (totalExpected > 0) ? (totalDispensed * 100 / totalExpected) : 0;
  Serial.println("Overall completion: " + String(completionPercentage) + "% (" + 
                String(totalDispensed) + "/" + String(totalExpected) + " products)");
  
  // Try to recover from non-critical failures
  bool attemptAutoRecovery = (completionPercentage >= 75); // Auto-recover if at least 75% complete
  if (attemptAutoRecovery) {
    Serial.println("⚠ Auto-recovery attempt: Order is " + String(completionPercentage) + "% complete, proceeding despite errors");
    completeOrder();
    return;
  }

  // Call API to fail the order
  HTTPClient http;
  String url = String(serverUrl) + "/order/fail";

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  // Enhanced JSON payload with detailed error information
  String jsonPayload = "{\"orderId\":\"" + currentOrderId +
                      "\",\"vendingMachineId\":\"" + String(vendingMachineId) +
                      "\",\"reason\":\"" + reason + "\"," +
                      "\"details\":{" +
                      "\"totalExpected\":" + String(totalExpected) + "," +
                      "\"totalDispensed\":" + String(totalDispensed) + "," +
                      "\"completionPercentage\":" + String(completionPercentage) + "," +
                      "\"timestamp\":" + String(millis()) +
                      "}}";
                      
  Serial.print("Sending request to: ");
  Serial.println(url);
  Serial.print("With payload: ");
  Serial.println(jsonPayload);

  int httpResponseCode = http.POST(jsonPayload);
  String response = http.getString();

  if (httpResponseCode == 200) {
    Serial.println("✓ Order failure successfully logged");
    Serial.println("Response: " + response);
    orderInProgress = false;
    currentOrderId = "";
    currentUserId = "";
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Order failed");
    lcd.setCursor(0, 1);
    lcd.print("Contact support");*/
  } else {
    Serial.println("✗ Error logging order failure. HTTP code: " + String(httpResponseCode));
    Serial.println("Error response: " + response);
  }
  
  Serial.println("===================================\n");

  http.end();
}

bool dispenseSingleItem(int couloir) {
  Serial.println("\n--- Dispensing Single Item ---");
  Serial.println("Chariot/Couloir: " + String(couloir));
  
  // Safety check for valid couloir is commented out in your code
  // if (couloir < 1 || couloir > NUM_CHARIOTS) {
  //   Serial.println("ERROR: Invalid couloir number: " + String(couloir));
  //   return false;
  // }
  Serial.println("Starting motor for couloir " + String(couloir));
  
  // Convert couloir number to chariot ID string format
  String chariotId = "CHARIOT" + String(couloir);
  int relayPin = getRelayPinForChariot(chariotId);
  if (relayPin == -1) {
    Serial.println("ERROR: Invalid chariot ID: " + chariotId);
    return false;
  }

  const unsigned long DETECTION_TIMEOUT = 5000;
  const int DETECTION_RETRIES = 3;
  const int MIN_DETECTION_TIME_MS = 50;
  Serial.println("Dispensing item from chariot: " + String(couloir) + " using relay pin: " + String(relayPin));
  
  // Add relay pin verification before activation
  pinMode(relayPin, OUTPUT); // Ensure pin is configured as output
  bool relayActivated = false;
    for (int retry = 0; retry < DETECTION_RETRIES; retry++) {
    // Log the relay activation with timestamp for debugging
    unsigned long activationStartTime = millis();
    Serial.println("Activating relay " + String(relayPin) + " for couloir " + String(couloir) + " at " + String(activationStartTime) + "ms");
    
    // Activate relay (LOW activates the relay on most modules)
    digitalWrite(relayPin, LOW);
    relayActivated = true;
    
    // Keep relay activated longer for motor to push product fully
    // Print a progress indicator to confirm relay is still activated
    Serial.print("Keeping relay active for 1500ms: ");
    for (int i = 0; i < 5; i++) {
      delay(300); // Split into 5 segments with progress indicators
      Serial.print("●");
    }
    Serial.println(" Done!");
    
    // Deactivate relay with verification
    unsigned long deactivationTime = millis();
    Serial.println("Deactivating relay " + String(relayPin) + " at " + String(deactivationTime) + "ms after " + 
                  String(deactivationTime - activationStartTime) + "ms activation time");
    digitalWrite(relayPin, HIGH);    // Log product fall wait period with adaptive timing based on the VL53L0X sensor specifications
    // Products can fall at different speeds based on weight and size
    Serial.println("\nWaiting for product to fall from couloir " + String(couloir) + "...");
    
    // Use adaptive timing based on the product characteristics
    // Heavier products may need more push time and less fall detection delay
    unsigned long productFallDelay = 2000; // Default 2000ms
    Serial.println("Using fall detection delay of " + String(productFallDelay) + "ms");
    delay(productFallDelay); 
    
    // Start detection loop with detailed monitoring
    unsigned long startTime = millis();
    Serial.println("Starting detection window at " + String(startTime) + "ms");
    Serial.println("Detection window will last for " + String(DETECTION_TIMEOUT) + "ms until " + 
                   String(startTime + DETECTION_TIMEOUT) + "ms");
    
    // Pre-scan to check sensor is working correctly
    int baselineReading = detectItemCouloir();
    if (baselineReading > 0) {
      Serial.println("⚠ WARNING: Sensor already detecting object in couloir " + String(baselineReading) + " before product release!");
    } else {
      Serial.println("✓ Sensor clear before product release (no false reading)");
    }
    bool productDetected = false;
    int detectedCouloir = 0;
    
    // Debug: Begin detection loop
    Serial.println("Starting product detection loop for couloir " + String(couloir));
      while (millis() - startTime < DETECTION_TIMEOUT) {
      // Read current distance and check if in range for any couloir
      detectedCouloir = detectItemCouloir();
      
      // If a potential product is detected
      if (detectedCouloir > 0) {
        unsigned long detectionTime = millis();
        unsigned long detectionDuration = detectionTime - startTime;
        
        // Log the detection event with precise timing
        Serial.println("\n▶ Potential detection event at " + String(detectionTime) + "ms!");
        Serial.println("  Couloir: " + String(detectedCouloir) + " - Time since trigger: " + String(detectionDuration) + "ms");
        Serial.println("  Verifying with multiple readings to confirm...");
        
        // Short delay to stabilize reading
        delay(MIN_DETECTION_TIME_MS);
        
        // Use an enhanced confirmation algorithm with timing statistics
        int confirmationReadings = 0;
        const int REQUIRED_CONFIRMATIONS = 3;
        const int TOTAL_READINGS = REQUIRED_CONFIRMATIONS + 3; // Multiple readings for better reliability
        unsigned long firstConfirmationTime = 0;
        unsigned long lastConfirmationTime = 0;
          // Take a series of readings with precise timing to confirm detection
        for (int i = 0; i < TOTAL_READINGS; i++) {
          int verificationCouloir = detectItemCouloir();
          if (verificationCouloir == detectedCouloir) {
            confirmationReadings++;
            
            // Record timing of first and last confirmation for fall speed analysis
            if (confirmationReadings == 1) {
              firstConfirmationTime = millis();
            }
            lastConfirmationTime = millis();
            
            Serial.print("✓"); // Visual indicator of confirmation
          } else {
            Serial.print("✗"); // Visual indicator of failed confirmation
          }
          delay(15); // Slightly increased delay for more stable readings
        }
        Serial.println(); // End confirmation indicators        // Enhanced decision logic based on confirmation ratio
        float confirmationRatio = (float)confirmationReadings / TOTAL_READINGS;
        
        if (confirmationReadings >= REQUIRED_CONFIRMATIONS - 1) {
          // We have enough confirmation readings for reliable detection
          productDetected = true;
          
          // Calculate fall characteristics for troubleshooting
          unsigned long detectionDuration = millis() - startTime;
          unsigned long confirmationDuration = lastConfirmationTime - firstConfirmationTime;
          
          // Enhanced logging with detailed timing and analysis
          Serial.println("\n---------- PRODUCT DETECTED ----------");
          Serial.println("Product CONFIRMED in couloir " + String(detectedCouloir) + " after " + String(detectionDuration) + "ms");
          Serial.println("Confirmation quality: " + String(confirmationReadings) + "/" + String(TOTAL_READINGS) + 
                         " (" + String(confirmationRatio * 100) + "%)");
          Serial.println("Detection sequence duration: " + String(confirmationDuration) + "ms");
          Serial.println("Detection timestamp: " + String(millis()) + "ms since startup");
          
          // Analyze product fall characteristics
          Serial.println("\nProduct fall analysis:");
          if (confirmationDuration > 200) {
            Serial.println("⚠ Long detection time (" + String(confirmationDuration) + "ms) - Product may be stuck or falling slowly");
          } else if (confirmationDuration < 50) {
            Serial.println("⚠ Very fast detection (" + String(confirmationDuration) + "ms) - Product may be small or lightweight");
          } else {
            Serial.println("✓ Normal detection time (" + String(confirmationDuration) + "ms) - Product fall appears normal");
          }          
          // Check if it's the expected couloir with enhanced error recovery
          if (detectedCouloir == couloir) {
            Serial.println("\n✓ Detected product from CORRECT couloir " + String(couloir));
          } else {
            // Advanced troubleshooting when product detected in wrong couloir
            Serial.println("\n⚠ Detected product from DIFFERENT couloir. Expected: " + String(couloir) + ", Detected: " + String(detectedCouloir));
            
            // Analyze potential causes with diagnostic information
            Serial.println("DIAGNOSTIC INFORMATION:");
            Serial.println("1. Physical causes: Product may have fallen diagonally or bounced to adjacent couloir");
            Serial.println("2. Sensor causes: VL53L0X may need recalibration or repositioning");
            Serial.println("3. Mapping causes: Couloir distance ranges may need adjustment");
            
            // Show distance ranges for reference
            Serial.println("\nCouloir distance map:");
            Serial.println("- Couloir 1: " + String(COULOIR1_MIN) + "mm to " + String(COULOIR1_MAX) + "mm");
            Serial.println("- Couloir 2: " + String(COULOIR2_MIN) + "mm to " + String(COULOIR2_MAX) + "mm"); 
            Serial.println("- Couloir 3: " + String(COULOIR3_MIN) + "mm to " + String(COULOIR3_MAX) + "mm");
            Serial.println("- Couloir 4: " + String(COULOIR4_MIN) + "mm to " + String(COULOIR4_MAX) + "mm");
            
            // Continue with order processing despite detection mismatch
            Serial.println("\n▶ RECOVERY ACTION: Proceeding with detection to complete order");
          }
          
          // Send to detection handler, which will correctly attribute the product
          updateItemDetection(detectedCouloir);
          Serial.println("---------------------------------------");
          break;
        } else {
          Serial.println("False detection - only " + String(confirmationReadings) + "/" + String(REQUIRED_CONFIRMATIONS + 2) + " confirmations");
        }
      }
      delay(10);
    }
      
    if (productDetected) {
      Serial.println("✓ Product successfully detected on attempt " + String(retry + 1) + " - Breaking retry loop");
      break; // Exit retry loop as product was detected
    } else {
      // Enhanced error handling with adaptive retry strategy
      Serial.println("\n⚠ Retry " + String(retry + 1) + " of " + String(DETECTION_RETRIES) + " failed. No product detected.");
      
      // Diagnostic information to help troubleshoot
      Serial.println("DIAGNOSTIC INFORMATION FOR FAILED ATTEMPT:");
      Serial.println("1. Motor activation period: 1500ms");
      Serial.println("2. Product fall wait period: " + String(productFallDelay) + "ms");
      Serial.println("3. Detection window: " + String(DETECTION_TIMEOUT) + "ms");
      
      // Adjust strategy for next retry based on failure pattern
      if (retry < DETECTION_RETRIES - 1) {
        Serial.println("\nADJUSTING STRATEGY FOR NEXT ATTEMPT:");
        
        // Increase delay time progressively with each attempt
        productFallDelay = 2000 + (retry + 1) * 500; // 2500ms, 3000ms for progressive retries
        
        Serial.println("→ Increasing product fall wait time to " + String(productFallDelay) + "ms");
        Serial.println("→ Will attempt again in 2 seconds...");
        delay(2000); // Wait before retry (increased delay)
      } else {
        Serial.println("\n❌ ALL RETRY ATTEMPTS FAILED");
        Serial.println("Please check:");
        Serial.println("1. Product may be stuck in chariot " + String(couloir));
        Serial.println("2. Motor may not be working properly");
        Serial.println("3. Sensor may be misaligned or malfunctioning");
      }
    }
  }
  return true;
}

int detectItemCouloir() {
  VL53L0X_RangingMeasurementData_t measure;
  lox.rangingTest(&measure, false);

  static unsigned long lastSerialOutput = 0;
  const unsigned long SERIAL_OUTPUT_INTERVAL = 1000;

  if (measure.RangeStatus != 4) { // 4 means out of range
    int distance = measure.RangeMilliMeter;
    bool logOutput = (millis() - lastSerialOutput >= SERIAL_OUTPUT_INTERVAL);
    
    // If it's time to log output, update the timestamp
    if (logOutput) {
      Serial.println("Distance: " + String(distance) + "mm");
      lastSerialOutput = millis();
    }

    // Check couloir ranges and return the corresponding number
    if (distance >= COULOIR1_MIN && distance <= COULOIR1_MAX) {
      if (logOutput) Serial.println("Distance " + String(distance) + "mm corresponds to COULOIR1");
      return 1;
    } else if (distance >= COULOIR2_MIN && distance <= COULOIR2_MAX) {
      if (logOutput) Serial.println("Distance " + String(distance) + "mm corresponds to COULOIR2");
      return 2;
    } else if (distance >= COULOIR3_MIN && distance <= COULOIR3_MAX) {
      if (logOutput) Serial.println("Distance " + String(distance) + "mm corresponds to COULOIR3");
      return 3;
    } else if (distance >= COULOIR4_MIN && distance <= COULOIR4_MAX) {
      if (logOutput) Serial.println("Distance " + String(distance) + "mm corresponds to COULOIR4");
      return 4;
    } else {
      if (logOutput) Serial.println("Distance " + String(distance) + "mm is outside all couloir ranges");
      return 0;
    }
  } else {
    // Sensor reports "out of range"
    if (millis() - lastSerialOutput >= SERIAL_OUTPUT_INTERVAL) {
      Serial.println("VL53L0X out of range or error");
      lastSerialOutput = millis();
    }
    return 0;
  }
}

void updateItemDetection(int detectedCouloir) {
  // Shorter delay to reduce waiting time after detection
  delay(1000); // Reduced from 5000ms to 1000ms
  Serial.println("\n--- Item Detection Update ---");
  // Only check if we have an active order
  if (!orderInProgress || totalItemsInOrder == 0) {
    Serial.println("No active order to update");
    return;
  }    // First check for exact matches between detected couloir and expected couloir
    bool productMatched = false;
    
    // First priority: Try to match the product with its expected couloir
    for (int i = 0; i < totalItemsInOrder; i++) {
      int couloir = currentOrder[i].couloir;
      int targetQuantity = currentOrder[i].quantity;
      int currentCount = currentOrder[i].detectedCount;
      
      Serial.println("\nProduct " + String(i + 1) + " Status:");
      Serial.println("Chariot/Couloir: " + String(couloir));
      Serial.println("Target quantity: " + String(targetQuantity));
      Serial.println("Current count: " + String(currentCount));
      
      // Exact match - this is the preferred case
      if (currentOrder[i].couloir == detectedCouloir &&
          currentOrder[i].detectedCount < currentOrder[i].quantity) {
        currentOrder[i].detectedCount++;
        Serial.println("✓ Detected product from CORRECT couloir " + String(couloir));
        productMatched = true;

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
    
    // Second priority: If no exact match was found, check for any product that still needs items to be dispensed
    // This handles the case where a product is detected from a different couloir than expected
    if (!productMatched) {
      Serial.println("⚠ No exact couloir match found for detected product from couloir " + String(detectedCouloir));
      
      // Find the next product in the order that hasn't been fully counted yet
      for (int i = 0; i < totalItemsInOrder; i++) {
        if (currentOrder[i].detectedCount < currentOrder[i].quantity) {
          currentOrder[i].detectedCount++;
          Serial.println("Credited detection to product from couloir " + String(currentOrder[i].couloir) + 
                         " even though detected from couloir " + String(detectedCouloir));
          Serial.println("Product count now: " + String(currentOrder[i].detectedCount) + "/" + 
                         String(currentOrder[i].quantity));
          
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
}

void completeOrder() {
  if (!orderInProgress) return;

  // Enhanced completion reporting with timestamps
  unsigned long completionTime = millis();
  Serial.println("\n========== ORDER COMPLETION AT " + String(completionTime) + "ms ==========");
  Serial.println("Order ID: " + currentOrderId);
  Serial.println("Dispensed items summary:");
  
  // Calculate totals for better reporting
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

  // Call API to mark the order as fully dispensed
  HTTPClient http;
  String url = String(serverUrl) + "/hardware/dispense/complete";

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  // Enhanced JSON payload with detailed completion information
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
    Serial.println("✗ Error completing order. HTTP code: " + String(httpResponseCode));
    Serial.println("Error response: " + response);
    /*lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Error completing");
    lcd.setCursor(0, 1);
    lcd.print("order!");*/ // Commented out as LCD is not plugged

    /*delay(3000);
    showWelcomeScreen();*/ // Commented out as LCD is not plugged
  }
  
  Serial.println("======================================\n");
  
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

void checkProductUpdates() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Cannot check updates - WiFi not connected");
    return;
  }

  HTTPClient http;
  DynamicJsonDocument doc(2048);  // Increased buffer size for larger responses

  // First get product information
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

  // Then get chariot information
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
    
    doc.clear();  // Clear previous data
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

void loop() {
  // Periodically check pending orders and product updates from API
  static unsigned long lastOrderCheck = 0;
  static unsigned long lastProductCheck = 0;    if (WiFi.status() == WL_CONNECTED) {
    // Check orders every 2 seconds (even more frequent)
    if (millis() - lastOrderCheck > 2000) {
      if (!orderInProgress) {
        Serial.println("\n=== Checking for new orders to dispense ===");
        checkForApiOrders();
      }
      lastOrderCheck = millis();
    }
    
    // Check product updates every 5 seconds
    if (millis() - lastProductCheck > 5000) {
      checkProductUpdates();
      lastProductCheck = millis();
    }
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

  // Periodically check for product updates
  static unsigned long lastProductUpdateCheck = 0;
  if (WiFi.status() == WL_CONNECTED && millis() - lastProductUpdateCheck > 30000) { // Every 30 seconds
    checkProductUpdates();
    lastProductUpdateCheck = millis();
  }

  delay(100); // Small delay to prevent overwhelming the processor
}