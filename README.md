mfksensor
Overview
The mfksensor repository contains the open-source implementation of a low-cost (~75 EUR) air quality monitoring system developed at the Faculty of Earth Science and Engineering, Institute of Geography and Geoinformatics, University of Miskolc, Hungary. This project, part of the Climate Change Multidisciplinary National Laboratory (RRF-2.3.1-21-2022-00014), integrates Sensirion SEN55/SEN66 sensors, an ESP32-C3 SuperMini microcontroller, a 3D-printed enclosure, an iOS application, and a web-based visualization platform (https://szaaat.github.io/mfksensor/) to measure PM1.0, PM2.5, PM4.0, PM10.0, temperature, humidity, VOC, NOx, and CO2 (SEN66). The system supports configurable sampling intervals (2s for vehicles, 10s for bicycles, 60s for pedestrians) and was validated in Miskolc, Hungary, with high correlation (R² > 0.99) against reference instruments.
Project Description
The system uses factory-calibrated Sensirion SEN55/SEN66 sensors connected via I2C to an ESP32-C3 microcontroller, housed in a 3D-printed enclosure (IP54-rated, 110x100x40 mm). Data is transmitted via Bluetooth Low Energy (BLE) to an iOS app, which stores measurements locally (CSV format) in offline scenarios (e.g., Bükk region with no signal) and syncs them to a Supabase database when internet is available. A web interface, hosted at https://szaaat.github.io/mfksensor/, visualizes PM2.5 concentrations on a Leaflet-based map with a color-coded scale (0–75+ µg/m³), date filters, and CSV export. Field tests in Miskolc (2023–2024) collected over 10,000 measurements, achieving 98.7% BLE stability and <1% data loss offline. The system supports high-resolution spatial data (50–100m at 50 km/h) for detecting pollution hotspots (e.g., industrial zones, traffic junctions).
Repository Structure

doc/: Web interface files (HTML, CSS, JavaScript) for the real-time air quality visualization platform (https://szaaat.github.io/mfksensor/).
index.html: Sensor selection and real-time data display.
map.html: Leaflet-based map with PM2.5 markers, date filters, and CSV export.
about.html: Project background, team, and funding details.


arduino/: Arduino firmware for data collection.
sen66esp32c3supermini.ino: Firmware for SEN55/SEN66 sensors, transmitting data via BLE (UUID: 12345678-1234-1234-1234-123456789abc).


ios/: iOS application source code for data collection and Supabase integration.
BleManager.swift: Handles BLE communication with sensors.
LocationManager.swift: Manages GPS data (10m accuracy, background mode).
ViewController.swift, AppDelegate.swift, StringExtensions.swift, SceneDelegate.swift: Core app logic, local storage, and Supabase sync.
Info.plist: Configuration for BLE, GPS, and notifications.


LICENSE.md: Creative Commons Attribution 4.0 International (CC BY 4.0) license.

Installation

Arduino:
Install the Arduino IDE (https://www.arduino.cc/en/software).
Open arduino/sen66esp32c3supermini.ino.
Connect the ESP32-C3 SuperMini board via USB.
Upload the firmware to the board (115200 baud rate).


iOS:
Install Xcode (https://developer.apple.com/xcode/).
Open the ios/ folder in Xcode.
Configure the Supabase client in AppDelegate.swift with your credentials (remove sensitive keys before sharing).
Build and deploy the app to an iPhone 12 Pro or later.


Web Interface:
Visit https://szaaat.github.io/mfksensor/ for real-time visualization.
Ensure Supabase REST API (https://yuamroqhxrflusxeyylp.supabase.co/rest/v1/air_quality) is accessible for data retrieval.



Usage

Hardware Setup: Assemble the SEN55/SEN66 sensor, ESP32-C3, and components (e.g., 3.7V LiPo battery, Type-C charger) in the 3D-printed enclosure (STL files in [GitHub link helyőrző]).
Mobile Deployment: Mount the sensor on vehicles, bicycles, or pedestrians. Use the iOS app to collect and store data locally (CSV) and sync to Supabase when connected.
Stationary Deployment: Deploy the sensor (e.g., Eger courtyard) with WiFi connectivity via ESP32-C3 to a local server (e.g., Raspberry Pi) for direct Supabase uploads.
Data Visualization: Access https://szaaat.github.io/mfksensor/ to view PM2.5 levels, filter by date, and export data as CSV.

Funding
This project was supported by the Climate Change Multidisciplinary National Laboratory (RRF-2.3.1-21-2022-00014) and the HungAIRy project (LIFE17 IPE/HU/000017). We acknowledge the infrastructure support from the Faculty of Earth Science and Engineering, University of Miskolc.
License
This project is licensed under the Creative Commons Attribution 4.0 International (CC BY 4.0). You are free to share, adapt, and use the material for any purpose, provided you give appropriate credit to the authors (Attila Szamosi and contributors) and indicate any changes made. See LICENSE.md for details.
Citation

Data Availability

Raw measurements and code: https://github.com/szaaat/mfksensor
Data snapshot: [Supabase tábla snapshot helyőrző]
3D enclosure files, firmware, iOS app, and web visualization code: https://github.com/szaaat/mfksensor
