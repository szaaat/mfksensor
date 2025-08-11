# mfksensor
Open-source air quality monitoring system using Sensirion SEN55/SEN66 sensors, ESP32-C3, 3D-printed enclosure, iOS app, and web visualization[](https://szaaat.github.io/mfksensor/).

## Folders
- `doc`: Web interface files (HTML, CSS, JavaScript) for https://szaaat.github.io/mfksensor/.
- `arduino`: Arduino firmware (`sen66esp32c3supermini.ino`) for SEN55/SEN66 sensor data collection.
- `ios`: iOS app source code (Swift files) for data collection and Supabase integration.

## Installation
- **Arduino**: Open `arduino/sen66esp32c3supermini.ino` in Arduino IDE, upload to ESP32-C3.
- **iOS**: Open `ios/` files in Xcode, build for iPhone 12 Pro or later.
- **Web**: Visit https://szaaat.github.io/mfksensor/ for real-time air quality visualization.

## License
Licensed under CC BY 4.0.
