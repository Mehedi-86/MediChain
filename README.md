# 🏥 MediChain — AI-Powered Healthcare Management Platform

> **A full-stack iOS application built with SwiftUI, Firebase, Google Gemini AI, Apple Vision, and OpenFDA — designed to digitize, streamline, and secure the medical experience for patients, doctors, and administrators.**

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Team & Roles](#team--roles)
3. [Tech Stack](#tech-stack)
4. [System Architecture](#system-architecture)
5. [Features & Modules](#features--modules)
6. [Data Models](#data-models)
7. [Firebase Database Structure](#firebase-database-structure)
8. [Authentication & Authorization](#authentication--authorization)
9. [AI & External API Integrations](#ai--external-api-integrations)
10. [UI/UX Design Decisions](#uiux-design-decisions)
11. [Core Algorithms & Business Logic](#core-algorithms--business-logic)
12. [File Structure](#file-structure)
13. [Setup & Installation](#setup--installation)
14. [Build Configuration](#build-configuration)
15. [App UI Gallery](#-app-ui-gallery)
16. [Testing Notes](#testing-notes)
17. [Known Limitations & Future Work](#known-limitations--future-work)
---

## 📌 Project Overview

**MediChain** is a comprehensive iOS healthcare application developed using Swift and SwiftUI. The platform digitizes the traditional healthcare workflow — from appointment booking to prescription scanning — by integrating multiple AI services and real-time databases into a single, unified mobile experience.

The application serves three distinct types of users:

- **Patients** — Book appointments, scan prescriptions, view medical info, get AI-powered drug information, and manage a digital health identity.
- **Doctors** — Manage their duty schedule, view their patient queue (organized by date and serial number), and access patient profiles.
- **Administrators** — Monitor all registered doctors and patients, publish public health alerts, and manage the user base.

The project was collaboratively built by a team, with different members responsible for different feature modules. The codebase is organized to maintain clear separation of concerns, using SwiftUI's environment object pattern for shared state management across the entire application.

---



## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI (iOS 16+) |
| **Backend / Database** | Firebase Firestore (NoSQL real-time database) |
| **Authentication** | Firebase Auth (email/password) |
| **Cloud Storage** | Firebase Storage (profile pictures) |
| **AI — Text Cleaning** | Google Gemini AI (`gemini-flash-latest` via `GoogleGenerativeAI` SDK) |
| **AI — OCR** | Apple Vision Framework (`VNRecognizeTextRequest`) |
| **Document Scanning** | VisionKit (`VNDocumentCameraViewController`) |
| **Drug Information** | OpenFDA Public API (`api.fda.gov/drug/label.json`) |
| **Symptom Diagnosis** | ApiMedic Symptom Checker API (Sandbox) |
| **Health Tips** | MyHealthFinder API (`odphp.health.gov`) |
| **PDF Generation** | SwiftUI `ImageRenderer` + `CGContext` |
| **QR Code Generation** | CoreImage `CIFilter.qrCodeGenerator()` |
| **Photo Picker** | PhotosUI `PhotosPicker` |
| **Crypto / Auth Hashing** | CryptoKit `HMAC<Insecure.MD5>` |
| **Reactive State** | Combine framework, `@Published`, `@EnvironmentObject` |

---

## 🏗 System Architecture

MediChain follows a **MVVM (Model-View-ViewModel)** architecture pattern.

```
┌─────────────────────────────────────────────────────────┐
│                     MediChainApp.swift                   │
│              (App Entry Point + Role Router)            │
└──────────────────────────┬──────────────────────────────┘
                           │ @EnvironmentObject
                           ▼
                  ┌─────────────────┐
                  │  AuthViewModel  │  ← Single source of truth
                  │  (ObservableObj)│    for all state
                  └────────┬────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
│  LoginView   │  │  PatientDash │  │  DoctorDashboard │
└──────────────┘  └──────────────┘  └──────────────────┘
                        │                    │
              ┌─────────┼─────────┐          │
              ▼         ▼         ▼          ▼
         BookingView  MyInfo  Scanner   PatientDetail
                              View      View
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
               GeminiService OpenFDA   Healthfinder
                              Service    Service
```

**Data Flow:**
1. User authenticates via `AuthViewModel.signIn()` or `signUp()`
2. Firebase Auth validates credentials and returns a UID
3. Firestore stores and retrieves user data in real-time via `addSnapshotListener`
4. Role-based routing in `MediChainApp.swift` directs the user to the correct dashboard
5. All views share state via `@EnvironmentObject var authViewModel: AuthViewModel`

---

## 🎯 Features & Modules

### 1. 🔐 Authentication System (`LoginView.swift`, `AuthViewModel.swift`)

The authentication system supports two modes: **Login** and **Create Account**.

**Sign Up Logic:**
- Collects: Full Name, Email, Password, Role (Patient/Doctor), and Region (Doctors only)
- The `region` field is conditionally shown with a smooth SwiftUI animation when the `Doctor` role is selected
- Calls `Auth.auth().createUser()` to register with Firebase Auth
- Upon success, creates a `MediUser` document in Firestore's `users` collection
- The `isFormValid` computed property enforces field-level validation before allowing submission

**Sign In Logic:**
- **Admin Fast Path:** If credentials match the hardcoded admin email/password (`admin@gmail.com` / `123456`), an in-memory admin session is created without any Firebase Auth call. This avoids creating a Firebase Auth entry for the admin account.
- **Normal Users:** Uses `Auth.auth().signIn()`, then fetches the user's Firestore document to load their role and profile data
- On success, `isSignedIn = true` triggers the role-based router in `MediChainApp.swift`

**Role-Based Routing (`MediChainApp.swift`):**
```
isSignedIn == true
    ├── isAdminSession OR role == .admin  →  AdminDashboardView
    ├── role == .doctor                   →  DoctorDashboardView
    └── default (patient)                 →  PatientDashboardView
```

**Sign Out:** Clears Firebase Auth session, resets all `@Published` state variables to empty, and sets `isSignedIn = false`.

---

### 2. 🗓 Appointment Booking System (`BookingView.swift`, `AuthViewModel.swift`)

**Booking Flow:**
1. Patient selects a date via `DatePicker` (restricted to today and future dates)
2. `fetchAvailableDoctors(for:)` is called — queries all users with `role == "Doctor"`, then cross-references the `availability` collection to filter out fully-booked doctors
3. A **Region Filter** (`Picker`) dynamically builds available regions from the doctor list
4. Patient selects a doctor from the filtered list and adds optional notes
5. `scheduleAppointment()` is called with a Firestore **atomic transaction**

**Duplicate Booking Prevention:**
Before initiating the transaction, the system checks if the patient already has an appointment on the selected date:
```swift
let alreadyBooked = patientAppointments.contains {
    formatDate($0.date) == dateString
}
if alreadyBooked { completion(false, errorMessage); return }
```

**Atomic Transaction & Serial Number Logic:**
The booking uses `db.runTransaction()` to atomically:
1. Read the current `currentPatientCount` for the doctor on that date
2. Increment it by 1
3. Return the new count as the patient's **serial number** (their position in the queue)
4. Write the new appointment document with the serial number embedded

This prevents race conditions where two patients might book the same serial slot simultaneously.

**Doctor Name Formatting:**
The app automatically prepends `"Dr. "` to a doctor's name if it doesn't already start with that prefix, ensuring consistent display throughout the app.

---

### 3. 📋 Patient Dashboard (`PatientDashboardView.swift`)

The patient dashboard is the central hub for patients, featuring:

- **Profile Picture System** — Tap to open a confirmation dialog offering "View" or "Set" options. Uses `PhotosPicker` to select from the gallery. The selected image is uploaded to Firebase Storage at `profile_pictures/{uid}.jpg` (overwriting any previous image), and the download URL is stored in Firestore.
- **Digital Identity (QR Code)** — A QR button in the header opens `DigitalWalletView`, which generates a QR code from the user's UID using CoreImage's `CIFilter.qrCodeGenerator()`.
- **Appointments Feed (Paginated)** — Upcoming appointments are displayed in pages of 5. The `paginatedAppointments` computed property slices the `patientAppointments` array. Navigation uses Previous/Next buttons with a `"Page X of Y"` indicator.
- **Appointment Cancellation** — Each card has an ellipsis `(...)` menu with a destructive "Cancel Appointment" option. On cancellation, the appointment document is deleted and the doctor's `currentPatientCount` in the availability collection is decremented via a transaction.
- **Expired Appointment Auto-Cleanup** — During `fetchPatientAppointments()`, any appointment with a date before today's midnight is automatically deleted from Firestore.

---

### 4. 👨‍⚕️ Doctor Dashboard (`DoctorDashboardView.swift`)

- **Duty Settings Card** — Allows the doctor to set their `dailyLimit` (max patients per day), `dutyStart`/`dutyEnd` times (using `DatePicker` in `.hourAndMinute` mode), and `specialty` (from a predefined list of 8 specialties). Saved to Firestore via `updateDoctorDuty()`.
- **Smart Patient Queue** — Appointments are fetched via a Firestore real-time listener. The queue is organized using a **two-step sort**: first by calendar day (ignoring time), then by `serialNumber` within the same day.
- **Date-Based Pagination** — The queue extracts all unique appointment dates using a `Set`, sorts them, and displays one day's appointments at a time. Chevron buttons navigate between date pages.
- **Patient Profile Viewer** — Each patient card has a "View Patient Profile" button. Tapping it calls `fetchUserDetails(uid:)` to retrieve that specific patient's full Firestore document, then opens `PatientDetailView` as a sheet. Email is deliberately hidden in this view for privacy.

---

### 5. 🤖 Smart Prescription Scanner (`PrescriptionScannerView.swift`)

This is the most technically complex module, integrating 4 separate services in a pipeline:

**Step 1 — Document Scanning:**
- On a real iPhone: Uses `VNDocumentCameraViewController` (VisionKit) for automatic document edge detection and perspective correction
- On Simulator: Falls back to `UIImagePickerController` (photo gallery) via compiler directives (`#if targetEnvironment(simulator)`)

**Step 2 — Offline OCR (`TextRecognizer.swift`):**
- Uses Apple's `VNRecognizeTextRequest` with `recognitionLevel = .accurate` and `usesLanguageCorrection = true`
- Raw text is post-processed: extra whitespace is trimmed, lines starting with `->`, `-`, `+`, `*` are converted to `•` bullet points
- Runs fully offline — no data leaves the device at this stage

**Step 3 — AI Cleaning with Google Gemini (`GeminiService.swift`):**
- The raw, potentially garbled OCR text is sent to `gemini-flash-latest` with a carefully crafted prompt
- The prompt instructs the model to act as a medical AI assistant, fix OCR typos, correct misspelled drug names, and return a structured output in a specific format:
  ```
  👨‍⚕️ Doctor: [Name]
  📅 Date: [Date]
  🩺 Diagnosis: [Symptoms/Concern]
  💊 Medications: [List of meds]
  🔍 Main Drug: [Primary drug name]
  ```
- The API key is loaded securely from `Info.plist` (via `Config.xcconfig`), never hardcoded
- Rate limit errors (HTTP 429) are caught and displayed with a user-friendly retry message

**Step 4 — OpenFDA Drug Lookup (`OpenFDAService.swift`):**
- After Gemini cleans the text, medicine names are extracted from the structured output by parsing the `Medications:` and `Main Drug:` lines
- Multiple candidate terms are built from each drug name (original, dosage-stripped, alphabetic-only, first token) to maximize match probability
- Each candidate hits the FDA API: `openfda.brand_name`, `openfda.generic_name`, or `openfda.substance_name`
- Results are displayed as collapsible `FDAInfoCard` components with toggle between "Brief" and "Full" detail modes

**Step 5 — MyHealthFinder Integration:**
- The `Diagnosis:` line from Gemini output is parsed and the first keyword is auto-populated into the health tips search box
- Users can search for any condition; results are fetched from `odphp.health.gov/myhealthfinder/api/v4/topicsearch.json`
- Links to full official health articles are provided

**Step 6 — PDF Report Generation (`PDFGenerator.swift`):**
- Uses SwiftUI's `ImageRenderer` to render `MedicalReportView` to a PDF
- The PDF is saved to the app's temporary directory and shared via iOS `ShareLink`

---

### 6. 📰 Breaking News / Public Alerts (`AdminDashboardView.swift`, `BreakingNewsFeedView.swift`)

**Admin-Side Publishing:**
- Admin types a Title, Brief (1-2 lines), and full Article body
- Formatting syntax: `#` for heading, `##` for subheading, `-` for bullets, plain text for paragraphs. Also supports `£` and `££` as alternatives for users whose keyboards produce that instead of `#`
- Published items are stored in Firestore's `breakingNews` collection with a `createdAt` timestamp, ordered descending

**Patient/Public-Side Viewing:**
- Accessible from the Login screen (before authentication) via a "Breaking Information" button
- Articles are rendered with rich formatting using a custom `ArticleBlock` enum parser that converts the markdown-like syntax into styled SwiftUI views
- Each alert card has a unique color theme chosen from a rotating set of 5 themes based on its index

---

### 7. 🛡 Admin Dashboard (`AdminDashboardView.swift`)

Uses `NavigationSplitView` for a sidebar + detail layout that adapts between iPad (split view) and iPhone (sheets):

- **Doctors Panel** — Searchable list of all registered doctors (by name, specialty, region, email). Shows duty hours, daily limit, and region chips. Admin can delete any doctor (cascades to delete all their appointments and availability records).
- **Patients Panel** — Searchable list of all patients (by name, email, or booked doctor name). Shows appointment count and list of unique doctors they've booked with.
- **Breaking Info Panel** — Create and delete public health alerts.

**Deletion Cascade Logic:**
When a doctor is deleted, `deleteUserRegistration()` uses a `DispatchGroup` to concurrently:
1. Delete the user document from `users`
2. Batch-delete all documents in `appointments` where `doctorId == uid`
3. Batch-delete all documents in `availability` where `doctorId == uid`

All operations complete before the `group.notify` completion handler fires.

---

## 📊 Data Models

### `MediUser` (`MediUser.swift`)
```swift
struct MediUser: Codable, Identifiable, Hashable {
    var id: String { uid }
    let uid: String
    let email: String
    var fullName: String?
    let role: UserRole           // "Admin", "Doctor", "Patient"
    var dutyStart: String?       // Doctor-only: e.g. "18:00"
    var dutyEnd: String?         // Doctor-only: e.g. "20:00"
    var dailyLimit: Int?         // Doctor-only: max patients/day
    var specialty: String?       // Doctor-only
    var region: String?          // Doctor-only: geographic region
    var bloodGroup: String?      // Patient-only
    var age: String?             // Patient-only
    var weight: String?          // Patient-only
    var profileImageUrl: String? // Optional cloud storage URL
}
```

### `Appointment` (`AppointmentModels.swift`)
```swift
struct Appointment: Codable, Identifiable {
    @DocumentID var id: String?
    let patientId: String
    var patientName: String?     // Stored at booking time (denormalized)
    let doctorId: String
    var doctorName: String?      // Stored at booking time (denormalized)
    var timeSlot: String?        // e.g. "18:00 - 20:00"
    let date: Date
    let status: String           // "Scheduled"
    let notes: String
    var serialNumber: Int?       // Queue position (1-indexed, from transaction)
}
```

### `BreakingNewsItem` (`BreakingNewsModels.swift`)
```swift
struct BreakingNewsItem: Codable, Identifiable {
    @DocumentID var id: String?
    let title: String
    let brief: String?           // Short 1-2 line summary
    let article: String?         // Full formatted article body
    let message: String?         // Legacy field (fallback for brief)
    let createdAt: Date
}
```

### `DoctorAvailability` (`AppointmentModels.swift`)
```swift
struct DoctorAvailability: Codable {
    let doctorId: String
    let date: String             // "yyyy-MM-dd" format
    var currentPatientCount: Int
    let maxLimit: Int
}
```

---

## 🗄 Firebase Database Structure

```
Firestore (Root)
│
├── users/
│   └── {uid}/
│       ├── uid: String
│       ├── email: String
│       ├── fullName: String
│       ├── role: "Doctor" | "Patient" | "Admin"
│       ├── region: String (Doctor only)
│       ├── specialty: String (Doctor only)
│       ├── dutyStart: String (Doctor only)
│       ├── dutyEnd: String (Doctor only)
│       ├── dailyLimit: Int (Doctor only)
│       ├── bloodGroup: String (Patient only)
│       ├── age: String (Patient only)
│       ├── weight: String (Patient only)
│       └── profileImageUrl: String (optional)
│
├── appointments/
│   └── {auto-id}/
│       ├── patientId: String
│       ├── patientName: String
│       ├── doctorId: String
│       ├── doctorName: String
│       ├── timeSlot: String
│       ├── date: Timestamp
│       ├── status: "Scheduled"
│       ├── notes: String
│       └── serialNumber: Int
│
├── availability/
│   └── {doctorId}_{yyyy-MM-dd}/
│       ├── doctorId: String
│       ├── date: String
│       └── currentPatientCount: Int
│
└── breakingNews/
    └── {auto-id}/
        ├── title: String
        ├── brief: String
        ├── article: String
        └── createdAt: Timestamp

Firebase Storage
└── profile_pictures/
    └── {uid}.jpg
```

---

## 🔐 Authentication & Authorization

| User Type | Auth Method | Session Flag | Dashboard |
|---|---|---|---|
| Admin | Hardcoded credentials check | `isAdminSession = true` | `AdminDashboardView` |
| Doctor | Firebase Auth + Firestore role check | `isSignedIn = true` | `DoctorDashboardView` |
| Patient | Firebase Auth + Firestore role check | `isSignedIn = true` | `PatientDashboardView` |

**Security considerations implemented:**
- Admin credentials are not stored in Firebase Auth (no Firebase account exists for admin)
- Patient email is hidden from the doctor's `PatientDetailView` for privacy
- API keys for Gemini are loaded from `Info.plist`/`Config.xcconfig`, not source code
- Firebase Security Rules (configured in Firebase Console, not in source) should restrict reads/writes by `request.auth.uid`

---

## 🤖 AI & External API Integrations

### Google Gemini AI (`GeminiService.swift`)
- **Model:** `gemini-flash-latest`
- **SDK:** `GoogleGenerativeAI` (Swift package)
- **Use Case:** Medical prescription text cleaning and structured data extraction
- **Key Design:** The prompt is engineered to output a specific labeled format so the app can parse `Doctor:`, `Medications:`, `Main Drug:`, and `Diagnosis:` fields programmatically
- **Error Handling:** Catches 429 rate limit errors and provides user-friendly retry instructions

### Apple Vision OCR (`TextRecognizer.swift`)
- **Framework:** `Vision` (VNRecognizeTextRequest)
- **Recognition Level:** `.accurate`
- **Language Correction:** Enabled
- **Post-Processing:** Custom `cleanUpText()` method normalizes whitespace and standardizes bullet point symbols
- **Advantage:** Fully offline, no data transmitted

### OpenFDA API (`OpenFDAService.swift`)
- **Endpoint:** `https://api.fda.gov/drug/label.json`
- **Search Strategy:** Multi-term fallback — original name → dosage-stripped → alphabetic-only → first token
- **Query:** Searches `openfda.brand_name`, `openfda.generic_name`, AND `openfda.substance_name` in a single OR query
- **Rate Limit Handling:** Returns `nil` gracefully on 429; logs 404 as a normal no-match state

### ApiMedic Symptom Checker (`ApiMedicService.swift`)
- **Auth:** HMAC-MD5 signature over the auth endpoint URL, using `CryptoKit`
- **Flow:** Generate token → map symptom keywords to IDs → query diagnosis endpoint → return first specialist recommendation
- **Use Case:** Suggest the right type of doctor based on patient symptoms

### MyHealthFinder API (`HealthfinderService.swift`)
- **Endpoint:** `https://odphp.health.gov/myhealthfinder/api/v4/topicsearch.json`
- **Use Case:** Return official US government health articles for a given medical keyword
- **Empty State Handling:** Returns empty array (not an error) on 404 or empty JSON

---

## 🎨 UI/UX Design Decisions

### Design System
- **Color Palette:** Teal/Cyan for patient-facing features, Indigo for doctor-facing features, Dark Navy gradient for admin
- **Card Style:** Consistent `.adminCardStyle()` / custom card modifiers with `RoundedRectangle`, subtle drop shadows, and translucent borders
- **Gradients:** Used extensively in headers (`LinearGradient`) to establish visual hierarchy
- **Animations:** `withAnimation(.spring())` for state transitions; `.easeInOut` for login/signup mode switches; `.transition(.move.combined(with: .opacity))` for card entrances

### Adaptive Layout
- `AdminDashboardView` uses `NavigationSplitView` with `.balanced` style — on iPad, both sidebar and detail are visible simultaneously; on iPhone (`horizontalSizeClass == .compact`), detail panels open as sheets
- `NavigationSplitViewVisibility` is managed via `@State private var splitVisibility` to programmatically control sidebar visibility

### Accessibility & UX Patterns
- Doctor name auto-formatting (`"Dr. "` prefix) ensures consistent display across booking, dashboards, and appointment cards
- Serial number badges (`#1`, `#2`, etc.) use orange color tokens to immediately convey queue position
- Empty state views use contextual icons and guidance text instead of blank screens
- `ProgressView` spinners with descriptive labels show during all async operations

---

## ⚙️ Core Algorithms & Business Logic

### Two-Step Appointment Sort
Used in both `fetchDoctorAppointments()` and `fetchPatientAppointments()`:
```swift
appointments.sort { appt1, appt2 in
    let day1 = Calendar.current.startOfDay(for: appt1.date)
    let day2 = Calendar.current.startOfDay(for: appt2.date)
    if day1 == day2 {
        return (appt1.serialNumber ?? 0) < (appt2.serialNumber ?? 0)
    }
    return day1 < day2
}
```
This ensures appointments are first sorted by calendar day (stripping time), then by serial number within the same day — giving doctors a correct, ordered patient queue.

### Atomic Serial Number Assignment
The booking transaction guarantees no two patients get the same serial number for the same doctor on the same day, even under concurrent load:
```swift
db.runTransaction { transaction, errorPointer in
    let currentCount = availDoc.data()?["currentPatientCount"] as? Int ?? 0
    let newSerial = currentCount + 1
    transaction.setData([...], forDocument: availabilityRef, merge: true)
    return newSerial
}
```

### Doctor Availability Filter
`fetchAvailableDoctors(for:)` runs an async fan-out: it fetches all doctors, then for each doctor independently checks the `availability/{doctorId}_{date}` document. Only doctors whose `currentPatientCount < dailyLimit` are added to the `availableDoctors` array.

### FDA Multi-Term Fallback
`buildCandidateTerms(from:)` generates up to 4 progressively simpler search terms from a raw drug name:
1. Original normalized string (e.g., `"Paracetamol 500mg"`)
2. Dosage-stripped (`"Paracetamol"`)
3. Alphabetic-only (removes numbers, symbols)
4. First token only

The FDA API is queried with each term in order until a match is found, maximizing the chance of a successful lookup despite OCR or Gemini formatting variations.

---

## 📁 File Structure

```
MediChain/
│
├── App
│   ├── MediChainApp.swift          # Entry point, role router
│   ├── ContentView.swift           # Default (unused) template
│   └── APIKeys.swift               # ApiMedic credentials placeholder
│
├── ViewModels
│   └── AuthViewModel.swift         # Central state manager (750+ lines)
│
├── Models
│   ├── MediUser.swift              # User data model + UserRole enum
│   ├── AppointmentModels.swift     # Appointment + DoctorAvailability
│   └── BreakingNewsModels.swift    # BreakingNewsItem model
│
├── Views — Auth
│   └── LoginView.swift             # Login + Signup UI
│
├── Views — Patient
│   ├── PatientDashboardView.swift  # Main patient hub
│   ├── BookingView.swift           # Doctor booking flow
│   ├── MyInfoView.swift            # Medical info editor
│   └── DigitalWalletView.swift     # QR code identity card
│
├── Views — Doctor
│   ├── DoctorDashboardView.swift   # Duty settings + queue
│   └── PatientDetailView.swift     # Patient profile viewer
│
├── Views — Admin
│   └── AdminDashboardView.swift    # Doctors, patients, news panels
│
├── Views — Scanner
│   ├── PrescriptionScannerView.swift  # Main scanner pipeline
│   ├── ScannerView.swift              # VisionKit / UIImagePicker wrapper
│   ├── MedicalReportView.swift        # PDF layout view
│   └── FDAInfoCard.swift              # Expandable drug info card
│
├── Views — News
│   ├── BreakingNewsFeedView.swift  # Public alert feed + article view
│   └── PreventionTipsView.swift    # HealthFinder results list
│
├── Services
│   ├── GeminiService.swift         # Google Gemini AI integration
│   ├── OpenFDAService.swift        # FDA drug label API
│   ├── ApiMedicService.swift       # Symptom → Specialist API
│   └── HealthfinderService.swift   # MyHealthFinder API
│
└── Utilities
    ├── TextRecognizer.swift        # Apple Vision OCR
    ├── PDFGenerator.swift          # ImageRenderer → PDF
    └── QRCodeGenerator.swift       # CoreImage QR generation
```

---

## 🚀 Setup & Installation

### Prerequisites
- Xcode 15.0+
- iOS 16.0+ deployment target
- Active Apple Developer account (for VisionKit on device)
- Firebase project with Firestore, Auth, and Storage enabled
- Google Gemini API key (from [Google AI Studio](https://aistudio.google.com))
- ApiMedic Sandbox account (optional, for symptom checker)

### Step 1 — Clone the Repository
```bash
git clone https://github.com/yourusername/MediChain.git
cd MediChain
```

### Step 2 — Install Swift Package Dependencies
Open `MediChain.xcodeproj` in Xcode. The following packages are required (add via **File → Add Packages**):

```
https://github.com/firebase/firebase-ios-sdk     (Firebase)
https://github.com/google/generative-ai-swift    (GoogleGenerativeAI)
```

Or add to `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
    .package(url: "https://github.com/google/generative-ai-swift", from: "0.5.0")
]
```

### Step 3 — Firebase Configuration
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new iOS project
3. Download `GoogleService-Info.plist`
4. Drag it into the Xcode project root (check "Copy items if needed")
5. Enable **Authentication → Email/Password**
6. Enable **Firestore Database** (start in test mode for development)
7. Enable **Storage**

### Step 4 — Gemini API Key Configuration
Create a `Config.xcconfig` file in the project root:
```
GEMINI_API_KEY = YOUR_GEMINI_API_KEY_HERE
```

Add to `Info.plist`:
```xml
<key>GEMINI_API_KEY</key>
<string>$(GEMINI_API_KEY)</string>
```

### Step 5 — ApiMedic Keys (Optional)
Open `APIKeys.swift` and replace the placeholder values:
```swift
struct APIKeys {
    static let apiMedicKey    = "YOUR_API_KEY_HERE"
    static let apiMedicSecret = "YOUR_SECRET_KEY_HERE"
}
```

### Step 6 — Build & Run
Select your target device or simulator and press **⌘R**.

> **Note:** The Document Camera (`VNDocumentCameraViewController`) requires a physical iPhone. The simulator automatically falls back to the photo gallery picker.

---

## ⚙️ Build Configuration

### Required Capabilities (in Xcode → Signing & Capabilities)
- Push Notifications (for future versions)
- Camera Usage (`NSCameraUsageDescription` in Info.plist)
- Photo Library Usage (`NSPhotoLibraryUsageDescription` in Info.plist)

### Info.plist Required Keys
```xml
<key>NSCameraUsageDescription</key>
<string>MediChain uses the camera to scan prescription documents.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>MediChain needs photo access to set your profile picture.</string>

<key>GEMINI_API_KEY</key>
<string>$(GEMINI_API_KEY)</string>
```

---


## 📸 App UI Gallery

<table align="center">
  <tr>
    <td align="center"><b>Login Page</b></td>
    <td align="center"><b>Patient Dashboard</b></td>
    <td align="center"><b>Smart Scanner</b></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/e7c969ce-6e4a-4778-97e1-3c48108700dd" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/dbd2f56e-0cdc-4205-8e71-4c247bbce630" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/d6316459-cf65-4c43-bc10-126e8c8e8011" width="300"/></td>
  </tr>
  
  <tr>
    <td align="center"><b>Scanning Prescription</b></td>
    <td align="center"><b>API Module</b></td>
    <td align="center"><b>Medical Records</b></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/10383a21-1bc3-4c9e-bd43-21de8234d4d7" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/e8429dc6-67ab-4f1d-99f5-4aeb75830121" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/cf51efcd-6b1b-432f-b862-86138ddea6f2" width="300"/></td>
  </tr>

  <tr>
    <td align="center"><b>Digital Scanner</b></td>
    <td align="center"><b>Info Section</b></td>
    <td align="center"><b>Appointment Request Page</b></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/6030f0b4-4e85-4762-b26d-ce2c4ce5b74b" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/8e6deb4e-67a3-4949-a818-0c8773b84f48" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/52ec53a9-046a-453f-bff1-0eee6ca46160" width="300"/></td>
  </tr>

  <tr>
    <td align="center"><b>Take an Appointment</b></td>
    <td align="center"><b>SignUp Page</b></td>
    <td align="center"><b>Breaking Info Page</b></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/627cd29c-a692-4240-b93e-95bec8d599c4" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/f8f6dc41-08e7-455c-baba-5e9497e2817d" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/b26448d4-6ab1-462a-98da-c428f4ea960c" width="300"/></td>
  </tr>

  <tr>
    <td align="center"><b>Article of disease</b></td>
    <td align="center"><b>Doctor Dashboard</b></td>
    <td align="center"><b>Doctor visiting Patient Profile</b></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/a8636f70-31a5-4838-aaaf-1817c5fbe553" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/c1f3fd2b-dcb1-4aa0-9575-502d4d65c5cc" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/9638076c-ffcd-4e0e-bb08-0ae34a1f3016" width="300"/></td>
  </tr>

  <tr>
    <td align="center"><b>Doctor can suggest Prescription and see Tests Report</b></td>
    <td align="center"><b>Admin Dashboard</b></td>
    <td align="center"><b>Admin can see Doctor's list</b></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/76dace44-dbf7-4325-8340-689589ed58a4" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/ce2aaed0-2b7d-49c3-a16f-f4f8682797a4" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/76fe86f1-450b-46db-b03c-826ba6501bbd" width="300"/></td>
  </tr>

  <tr>
    <td align="center"><b>Admin can see Patient's list</b></td>
    <td align="center"><b>Breaking Info Page</b></td>
    <td></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/aaf3ef7a-c984-4b69-8f33-066e07d5715c" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/da335d6c-3ac0-4480-9f21-0850aba694d9" width="300"/></td>
    <td></td>
  </tr>
</table>

## 🧪 Testing Notes

| Scenario | Expected Behavior |
|---|---|
| Sign up as Doctor with empty Region | "Create Account" button stays disabled |
| Book same doctor on same date twice | Alert: "You already have an appointment for [date]" |
| Two patients book simultaneously | Atomic transaction ensures unique serial numbers |
| Gemini called with rate limit hit | User sees friendly retry message, original OCR text preserved |
| FDA search for unknown drug | "No official FDA result found" message shown |
| Admin deletes a doctor | Cascades to delete all their appointments and availability docs |
| Appointment date passes midnight | Auto-deleted on next `fetchPatientAppointments()` call |
| Scan on iOS Simulator | Falls back to UIImagePickerController (photo gallery) |
| No doctors available for selected date | Empty state: "No doctors available for this date" |

---

## ⚠️ Known Limitations & Future Work

### Current Limitations
1. **Admin account is not managed by Firebase Auth** — the admin credentials are hardcoded for simplicity; in production this should be replaced with Firebase Admin SDK or a custom claims approach
2. **No real-time appointment notifications** — doctors are not pushed a notification when a new patient books; they must open the app to see updates
3. **ApiMedic symptom dictionary is limited** — only 7 keywords are mapped to IDs; a production version would need a full symptom database
4. **OCR accuracy on handwritten prescriptions** — Apple Vision is optimized for printed text; highly stylized handwriting may still produce garbled output requiring Gemini correction
5. **Profile image is stored publicly** — Firebase Storage rules should be tightened to restrict access by UID

### Future Enhancements
- Push Notifications via APNs + Firebase Cloud Messaging when appointments are booked or approaching
- Video/telehealth consultation integration (WebRTC or Daily.co SDK)
- Multi-language support via `LocalizedStringKey`
- Doctor rating and review system
- Prescription history stored persistently in Firestore per patient
- End-to-end encryption for sensitive medical documents
- Apple HealthKit integration for real-time vitals monitoring
- Biometric login (`Face ID` / `Touch ID`) via `LocalAuthentication`

---

## 📄 License

This project was developed as an academic project. All external APIs (OpenFDA, MyHealthFinder) are used in compliance with their respective public usage policies. Firebase and Google Gemini are used under their respective developer terms of service.

---

## 🙏 Acknowledgements

- **Apple** — Vision Framework, VisionKit, SwiftUI, CoreImage
- **Google** — Firebase platform, Gemini AI generative model
- **US Department of Health** — OpenFDA and MyHealthFinder public APIs
- **ApiMedic** — Symptom checker sandbox API
- All team members for their dedicated contributions to each module

---

*MediChain — Bridging the gap between patients and healthcare, one scan at a time.*
