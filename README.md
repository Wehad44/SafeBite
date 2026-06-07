# SafeBite – Food Allergen Detection and Recommendation

## Project Overview
SafeBite is a mobile application that helps users detect allergens in food products. The user can scan or upload an image of a food product label, and the system checks if the product is safe based on their allergy profile. If not, it suggests safer alternatives.

## Features
- Scan or upload food label images
- Detect allergens based on user allergy profile
- Show result (Safe / Unsafe)
- Provide up to 5 alternative recommendations if unsafe
- Save user allergies so they don’t need to enter them again

## Technology Stack
- Flutter
- Flask
- Firebase Firestore
- Tesseract OCR
- Support Vector Machine

## Setup and Installation

### Prerequisites
* Flutter SDK (Latest stable version)
* Python 3.10+
* Tesseract OCR Engine installed locally
* Firebase Project credentials

### 1. Backend Server Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows use `venv\Scripts\activate`
pip install -r requirements.txt
python api.py
```
### 2. Frontend Mobile Setup
cd frontend
flutter pub get
- Ensure google-services.json is added to android/app/
- Ensure GoogleService-Info.plist is added to ios/Runner/

flutter run

## Team Members
- Wehad Alhenaki
- Yara Alsfaian
- Jory Aldossari
