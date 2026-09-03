//
//  CategoryIconHelper.swift
//  ExpenseTrackerSwift
//
//  Created by raven on 6/30/26.
//

import Foundation

/// Resolves semantic SF Symbol icon names based on category names and transaction descriptions.
enum CategoryIconHelper {
    
    /// Maps a category name or transaction text to an appropriate SF Symbol name.
    static func iconName(for text: String, isIncome: Bool = false) -> String {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Income categories
        if isIncome {
            if lower.contains("salary") || lower.contains("wage") || lower.contains("payroll") || lower.contains("paycheck") {
                return "dollarsign.circle.fill"
            }
            if lower.contains("bonus") || lower.contains("dividend") || lower.contains("interest") || lower.contains("invest") || lower.contains("stock") {
                return "chart.line.uptrend.xyaxis.circle.fill"
            }
            if lower.contains("gift") || lower.contains("reward") || lower.contains("cashback") {
                return "gift.fill"
            }
            if lower.contains("refund") || lower.contains("reimburse") || lower.contains("return") {
                return "arrow.uturn.backward.circle.fill"
            }
            if lower.contains("sale") || lower.contains("selling") || lower.contains("freelance") {
                return "briefcase.fill"
            }
            return "arrow.down.left.circle.fill"
        }
        
        // Expense categories & descriptions
        if lower.contains("food") || lower.contains("dining") || lower.contains("restaurant") ||
            lower.contains("lunch") || lower.contains("dinner") || lower.contains("breakfast") ||
            lower.contains("cafe") || lower.contains("coffee") || lower.contains("snack") ||
            lower.contains("fastfood") || lower.contains("bakery") || lower.contains("burger") ||
            lower.contains("pizza") {
            return "fork.knife"
        }
        
        if lower.contains("grocer") || lower.contains("supermarket") || lower.contains("market") || lower.contains("pantry") {
            return "cart.fill"
        }
        
        if lower.contains("transport") || lower.contains("commute") || lower.contains("gas") ||
            lower.contains("fuel") || lower.contains("car") || lower.contains("parking") ||
            lower.contains("uber") || lower.contains("grab") || lower.contains("taxi") ||
            lower.contains("transit") || lower.contains("bus") || lower.contains("train") ||
            lower.contains("toll") {
            return "car.fill"
        }
        
        if lower.contains("shop") || lower.contains("clothes") || lower.contains("apparel") ||
            lower.contains("retail") || lower.contains("shoes") || lower.contains("mall") ||
            lower.contains("electronics") {
            return "bag.fill"
        }
        
        if lower.contains("bill") || lower.contains("utilit") || lower.contains("electric") ||
            lower.contains("water") || lower.contains("power") || lower.contains("energy") {
            return "bolt.fill"
        }
        
        if lower.contains("rent") || lower.contains("mortgage") || lower.contains("home") ||
            lower.contains("housing") || lower.contains("apartment") || lower.contains("condo") ||
            lower.contains("maintenance") {
            return "house.fill"
        }
        
        if lower.contains("health") || lower.contains("medical") || lower.contains("doctor") ||
            lower.contains("pharmacy") || lower.contains("medicine") || lower.contains("dental") ||
            lower.contains("clinic") || lower.contains("hospital") {
            return "cross.case.fill"
        }
        
        if lower.contains("entertain") || lower.contains("movie") || lower.contains("game") ||
            lower.contains("subscription") || lower.contains("streaming") || lower.contains("music") ||
            lower.contains("netflix") || lower.contains("spotify") || lower.contains("youtube") ||
            lower.contains("cinema") {
            return "tv.fill"
        }
        
        if lower.contains("travel") || lower.contains("flight") || lower.contains("hotel") ||
            lower.contains("vacation") || lower.contains("airline") || lower.contains("trip") {
            return "airplane"
        }
        
        if lower.contains("phone") || lower.contains("mobile") || lower.contains("telecom") ||
            lower.contains("internet") || lower.contains("wifi") || lower.contains("broadband") {
            return "antenna.radiowaves.left.and.right"
        }
        
        if lower.contains("educat") || lower.contains("course") || lower.contains("tuition") ||
            lower.contains("book") || lower.contains("school") || lower.contains("college") ||
            lower.contains("class") {
            return "book.fill"
        }
        
        if lower.contains("personal") || lower.contains("beauty") || lower.contains("salon") ||
            lower.contains("spa") || lower.contains("haircut") || lower.contains("cosmetic") {
            return "sparkles"
        }
        
        if lower.contains("credit") || lower.contains("card") || lower.contains("loan") ||
            lower.contains("debt") || lower.contains("installment") || lower.contains("interest") {
            return "creditcard.fill"
        }
        
        if lower.contains("pet") || lower.contains("vet") || lower.contains("dog") || lower.contains("cat") {
            return "pawprint.fill"
        }
        
        if lower.contains("fitness") || lower.contains("gym") || lower.contains("sport") || lower.contains("workout") {
            return "figure.run"
        }
        
        if lower.contains("insurance") || lower.contains("policy") {
            return "shield.fill"
        }
        
        return "tag.fill"
    }
}
