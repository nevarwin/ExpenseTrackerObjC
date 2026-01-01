//
//  ContentView.swift
//  ExpenseTracker
//
//  Created by raven on 6/26/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            TransactionsHomeView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            
            BudgetListView()
                .tabItem {
                    Label("Budgets", systemImage: "chart.pie")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

