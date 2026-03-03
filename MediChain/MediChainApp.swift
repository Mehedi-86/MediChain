//
//  MediChainApp.swift
//  MediChain
//
//  Created by mehedi hasan on 3/3/26.
//

import SwiftUI
import Firebase

@main
struct MediChainApp: App {
    // Phase 1: Mehedi - Initializing the "System Architect" Environment [cite: 31, 37]
    @StateObject var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    // Optimized MediChainApp.swift
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isSignedIn {
                    if authViewModel.currentUser?.role == .doctor {
                        DoctorDashboardView()
                    } else {
                        PatientDashboardView()
                    }
                } else {
                    LoginView()
                }
            }
            .environmentObject(authViewModel) // Inject once for all views
        }
    }
}
