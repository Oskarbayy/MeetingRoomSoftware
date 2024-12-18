# Meeting Room HDMI Switcher Controller
A user-friendly solution for managing HDMI switchers via RS232 communication, designed for Vestergaard Company meeting rooms. The system features seamless input switching and output control through a Flutter front-end and a Go back-end.

## Features
- Switch HDMI Inputs: Control inputs for laptops, AV devices, and webcams.
- Turn Off Output Displays: Manage the TV or display output.
- Reliable RS232 Connection: Sends and reads commands over a serial connection.
- Client-Friendly UI: Simple buttons for non-technical users.

## Technologies Used
### Frontend
- Flutter - Front-end interface using Dart.
- HTTP - Communication with the backend.
### Backend
- Go (Golang) - Handles RS232 communication and HTTP server.
- Gorilla Mux - REST API routing.
- go.bug.st/serial - Serial port management.

## Setup
### 1. Backend
- Install Go: Go Installation
- Clone the project:
```
git clone https://github.com/username/meeting_room_switcher.git](https://github.com/Oskarbayy/MeetingRoomSoftware.git
cd backend
```
- Run the server:
```
go run main.go
```
### 2. Frontend
- Install Flutter: Flutter Installation
- Navigate to the Flutter app:
```
cd frontend
flutter pub get
flutter run
```
## API Reference
### Switch Input
-URL: POST /api/button/{id}
-IDs:
  - 1: Laptop PC Wireless
  - 2: Meeting Room PC
  - 3: Other AV Devices
  - 4: Laptop PC Cable
  - 0: Turn Off Output

## About
This project is tailored for Vestergaard Company meeting rooms to simplify HDMI management and enhance the presentation experience.
