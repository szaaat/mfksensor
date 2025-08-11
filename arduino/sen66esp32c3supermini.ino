#include <Arduino.h>
#include <SensirionI2cSen66.h>
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// SEN66 szenzor UUID-k (az iPhone app kódjából)
#define SERVICE_UUID "12345678-1234-1234-1234-123456789abc"
#define CHARACTERISTIC_UUID "87654321-4321-4321-4321-cba987654321"

// Macro definitions
#ifdef NO_ERROR
#undef NO_ERROR
#endif
#define NO_ERROR 0

// BLE változók
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

// SEN66 szenzor objektum
SensirionI2cSen66 sensor;

// Hibakezeléshez szükséges változók
static char errorMessage[64];
static int16_t error;

// Mérési adatok
float massConcentrationPm1p0 = 0.0;
float massConcentrationPm2p5 = 0.0;
float massConcentrationPm4p0 = 0.0;
float massConcentrationPm10p0 = 0.0;
float humidity = 0.0;
float temperature = 0.0;
float vocIndex = 0.0;
float noxIndex = 0.0;
uint16_t co2 = 0;

// BLE szerver callback-ek
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        deviceConnected = true;
        Serial.println("Eszköz csatlakoztatva");
    };

    void onDisconnect(BLEServer* pServer) {
        deviceConnected = false;
        Serial.println("Eszköz lecsatlakoztatva");
        BLEDevice::startAdvertising(); // Újraindítjuk a hirdetést
    }
};

void setup() {
    // Soros kommunikáció inicializálása
    Serial.begin(115200);
    while (!Serial) {
        delay(100);
    }

    // I2C inicializálása (GPIO 8: SDA, GPIO 9: SCL)
    Wire.begin(8, 9); // ESP32-C3 SuperMini I2C lábak
    sensor.begin(Wire, SEN66_I2C_ADDR_6B);

    // SEN66 szenzor inicializálása
    error = sensor.deviceReset();
    if (error != NO_ERROR) {
        Serial.print("Error trying to execute deviceReset(): ");
        errorToString(error, errorMessage, sizeof errorMessage);
        Serial.println(errorMessage);
        while (1); // Végtelen ciklus, ha hiba van
    }
    delay(1200);

    // Soros szám kiolvasása (opcionális, hibakereséshez)
    int8_t serialNumber[32] = {0};
    error = sensor.getSerialNumber(serialNumber, 32);
    if (error != NO_ERROR) {
        Serial.print("Error trying to execute getSerialNumber(): ");
        errorToString(error, errorMessage, sizeof errorMessage);
        Serial.println(errorMessage);
        while (1);
    }
    Serial.print("serialNumber: ");
    Serial.print((const char*)serialNumber);
    Serial.println();

    // Mérések indítása
    error = sensor.startContinuousMeasurement();
    if (error != NO_ERROR) {
        Serial.print("Error trying to execute startContinuousMeasurement(): ");
        errorToString(error, errorMessage, sizeof errorMessage);
        Serial.println(errorMessage);
        while (1);
    }
    Serial.println("SEN66 inicializálva és mérések elindítva");

    // BLE inicializálása
    BLEDevice::init("SEN66"); // Az eszköz neve, amit az iPhone látni fog
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    // Szolgáltatás létrehozása
    BLEService *pService = pServer->createService(SERVICE_UUID);

    // Jellemző létrehozása
    pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );

    // Descriptor hozzáadása a notify-hoz
    pCharacteristic->addDescriptor(new BLE2902());

    // Szolgáltatás indítása
    pService->start();

    // Hirdetés indítása
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);  // iPhone kompatibilitás
    pAdvertising->setMaxPreferred(0x12);
    BLEDevice::startAdvertising();
    Serial.println("BLE hirdetés elindítva");
}

void loop() {
    // Adatok kiolvasása az SEN66 szenzortól
    delay(1000); // Az SEN66-nak idő kell a mérésekhez

    error = sensor.readMeasuredValues(
        massConcentrationPm1p0, massConcentrationPm2p5, massConcentrationPm4p0,
        massConcentrationPm10p0, humidity, temperature, vocIndex, noxIndex, co2
    );

    if (error != NO_ERROR) {
        Serial.print("Error trying to execute readMeasuredValues(): ");
        errorToString(error, errorMessage, sizeof errorMessage);
        Serial.println(errorMessage);
    } else {
        // Adatok kiírása a soros monitorra (hibakereséshez)
        Serial.print("massConcentrationPm1p0: ");
        Serial.print(massConcentrationPm1p0);
        Serial.print("\t");
        Serial.print("massConcentrationPm2p5: ");
        Serial.print(massConcentrationPm2p5);
        Serial.print("\t");
        Serial.print("massConcentrationPm4p0: ");
        Serial.print(massConcentrationPm4p0);
        Serial.print("\t");
        Serial.print("massConcentrationPm10p0: ");
        Serial.print(massConcentrationPm10p0);
        Serial.print("\t");
        Serial.print("humidity: ");
        Serial.print(humidity);
        Serial.print("\t");
        Serial.print("temperature: ");
        Serial.print(temperature);
        Serial.print("\t");
        Serial.print("vocIndex: ");
        Serial.print(vocIndex);
        Serial.print("\t");
        Serial.print("noxIndex: ");
        Serial.print(noxIndex);
        Serial.print("\t");
        Serial.print("co2: ");
        Serial.print(co2);
        Serial.println();

        // Ha csatlakoztatva van egy eszköz, küldjük az adatokat BLE-n keresztül
        if (deviceConnected) {
            // Adatok formázása az iPhone app számára
            String data = " PM1=" + String(massConcentrationPm1p0) + 
                          ", PM2.5=" + String(massConcentrationPm2p5) + 
                          ", PM4=" + String(massConcentrationPm4p0) + 
                          ", PM10=" + String(massConcentrationPm10p0) + 
                          ", Humidity=" + String(humidity) + 
                          ", Temp=" + String(temperature) + 
                          ", VOC=" + String(vocIndex) + 
                          ", NOx=" + String(noxIndex) + 
                          ", CO2=" + String(co2);
            
            // Adatok küldése a jellemzőn keresztül
            pCharacteristic->setValue(data.c_str());
            pCharacteristic->notify();
            Serial.println("Adatok elküldve: " + data);
        }
    }

    delay(2000); // 2 másodpercenként olvasunk és küldünk adatokat
}
