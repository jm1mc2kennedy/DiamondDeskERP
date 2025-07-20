import Foundation

extension Sequence where Element: Hashable {
    /// Returns an array of unique elements, preserving order
    func unique() -> [Element] {
        var seen = Set<Element>()
        return self.filter { element in
            if seen.contains(element) {
                return false
            } else {
                seen.insert(element)
                return true
            }
        }
    }
}
