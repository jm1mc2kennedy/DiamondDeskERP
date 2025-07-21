import SwiftUI

extension View {
    @ViewBuilder
    func roleGated(for role: UserRole, feature: Feature) -> some View {
        if RoleGatingService.hasPermission(for: role, to: feature) {
            self
        } else {
            EmptyView()
        }
    }
}
