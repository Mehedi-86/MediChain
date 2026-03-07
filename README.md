# 🏥 MediChain: Advanced Health Management System

MediChain is a professional-grade iOS application designed to modernize how patients and doctors interact by digitizing medical records and streamlining telehealth appointments. Built with **SwiftUI** and a robust **MVVM architecture**, this system serves as a secure "Digital Wallet" for patients to store, manage, and share their medical history.

---

## 🚀 Tech Stack & Architecture
* **Frontend:** SwiftUI
* **Architecture:** Professional MVVM Pattern
* **Backend / Cloud:** Firebase Auth & Firestore (Real-time synchronization)
* **Local Storage:** SwiftData (Offline caching & fast access)

---

## ✅ Phase 1: Foundations & System Logic (Completed)
**Lead Architect:** Mehedi Hasan Rabby

The foundational architecture and core backend logic have been successfully implemented. This phase serves as the "brain" of the application.

### 1. Identity & Role Management (Module 1)
* **Firebase Authentication:** Secure login and registration flow with smart fallbacks for legacy accounts.
* **Dual-Portal Access:** Two distinct, premium UI dashboards dynamically routed based on user roles:
  * **Patient Portal:** Displays a personal medical timeline, upcoming appointments with pagination, and quick-action features.
  * **Doctor Portal:** Features duty shift management (limits, start/end times) and a smart, date-based paginated patient queue.

### 2. Telehealth Appointment Engine (Module 5)
* **Asynchronous Booking System:** Real-time scheduling engine where patients can book available slots.
* **Concurrency Protection:** Implemented Firestore transactions to prevent double-booking if two patients attempt to book the same slot simultaneously.
* **Smart Queuing:** Automatic serial number generation and chronological two-step sorting (by Date, then Serial Number) for doctors' queues.
* **Capacity Management:** Doctors can dynamically set daily patient limits, automatically hiding them from the availability pool once capacity is reached.

---

## 🚧 Upcoming Phases (In Progress)

### Phase 2: Intelligence & Digital Identity (Assigned to Azrof)
* **Medical Document Digitization (Module 3):** Integrating Apple's Vision Framework (OCR) to allow patients to scan physical prescriptions and automatically extract metadata (Date, Doctor Name) into SwiftData.
* **Digital Health Wallet (Module 4):** Generating unique Digital QR Profiles for secure, simulated patient history sharing.

### Phase 3: Integration & External Systems (Assigned to Mubin)
* **Live Doctor & Hospital Finder (Module 2):** Integrating Google Maps/Places REST APIs to fetch and display real-time clinic data based on simulated locations (e.g., Dhaka, Khulna).
* **Portable Health Records (Module 4):** Utilizing PDFKit to compile database notes, appointments, and histories into professional, exportable PDF reports.

---

## 🛠 Setup & Installation
1. Clone the repository: `git clone [repository-url]`
2. Ensure you are running the latest version of Xcode.
3. Fetch required dependencies (Firebase SDK).
4. Run the application in the iOS Simulator.
