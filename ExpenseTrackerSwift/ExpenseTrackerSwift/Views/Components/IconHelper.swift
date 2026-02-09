import SwiftUI

struct IconHelper {
    static func icon(for name: String) -> String {
        let n = name.lowercased()
        if n.contains("food") || n.contains("eat") || n.contains("restaurant") { return "fork.knife" }
        if n.contains("transport") || n.contains("travel") || n.contains("gas") || n.contains("car") { return "car.fill" }
        if n.contains("shop") || n.contains("cloth") || n.contains("buy") { return "bag.fill" }
        if n.contains("house") || n.contains("rent") || n.contains("home") { return "house.fill" }
        if n.contains("bill") || n.contains("utility") || n.contains("electric") { return "bolt.fill" }
        if n.contains("entertainment") || n.contains("movie") || n.contains("game") { return "tv.fill" }
        if n.contains("health") || n.contains("med") || n.contains("doctor") { return "heart.fill" }
        if n.contains("work") || n.contains("salary") { return "briefcase.fill" }
        if n.contains("money") || n.contains("cash") { return "banknote.fill" }
        return "tag.fill"
    }
}
