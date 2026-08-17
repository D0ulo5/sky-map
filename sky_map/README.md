# Sky Map

A clean and scalable Flutter mobile application for exploring the night sky.

Sky Map uses the device's location and orientation sensors to determine what part of the sky the user is viewing. The application will progressively support stars, planets, constellations, and interactive sky navigation.

## Features

* Device location detection
* Device orientation tracking
* Interactive night-sky map
* Stars and celestial objects
* Planets
* Constellations
* Object information and identification
* Search and navigation
* User settings

## Project Structure

```text
lib/
├── app/
│   ├── app.dart
│   └── theme/
│       └── app_theme.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   └── utils/
│
├── features/
│   ├── location/
│   ├── orientation/
│   ├── sky/
│   ├── objects/
│   └── settings/
│
└── main.dart
```

The project follows a feature-oriented structure so that individual parts of the application can evolve independently.

## Getting Started

Make sure Flutter is installed and available:

```bash
flutter doctor
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## Development

The project is being developed incrementally. Each feature is implemented as a complete task before moving to the next one.

The main development areas are:

1. Project foundation
2. Location services
3. Device orientation
4. Astronomical calculations
5. Sky model
6. Sky rendering
7. Interaction
8. Object information
9. Persistence and settings
10. Polish and performance
11. Testing and cleanup

## Design Goals

Sky Map aims to remain:

* **Clean** — simple interfaces and clear responsibilities.
* **Scalable** — features should be easy to extend or replace.
* **Maintainable** — domain logic should remain independent from UI code.
* **Performant** — rendering and sensor updates should be handled efficiently.
* **Testable** — important calculations and services should be independently testable.

## Requirements

* Flutter
* Dart
* Android or iOS device/emulator

Some features require physical device sensors such as GPS, accelerometer, gyroscope, and magnetometer.

## License

This project is currently intended for educational and development purposes.
