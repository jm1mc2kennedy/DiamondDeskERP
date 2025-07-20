//
//  ModernContentView.swift
//  DiamondDeskERP
//
//  Created by J.Michael McDermott on 7/20/25.
//

import SwiftUI

/// Modern main content view using iOS 16+ navigation APIs
/// Provides adaptive navigation experience across iPhone and iPad
struct ModernContentView: View {
    
    @StateObject private var router = NavigationRouter.shared
    @StateObject private var consentService = AnalyticsConsentService.shared
    
    var body: some View {
        TabAdaptiveNavigationView()
            .navigationDestinationHandler()
            .onOpenURL { url in
                router.handleDeepLink(url)
            }
            .sheet(isPresented: $consentService.shouldShowConsentBanner) {
                AnalyticsConsentBanner()
            }
            .alert("Navigation Error", isPresented: .constant(false)) {
                Button("OK") { }
            } message: {
                Text("Unable to navigate to the requested destination.")
            }
    }
}

// MARK: - Preview

#if DEBUG
struct ModernContentView_Previews: PreviewProvider {
    static var previews: some View {
        ModernContentView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
        
        ModernContentView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        
        ModernContentView()
            .previewDevice("iPad Pro (12.9-inch) (6th generation)")
            .previewDisplayName("iPad Pro")
        
        ModernContentView()
            .previewDevice("iPhone 15 Pro")
            .previewDisplayName("iPhone 15 Pro")
    }
}
#endif
