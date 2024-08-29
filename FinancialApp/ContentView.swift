import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BudgetingView()
                .tabItem {
                    Label("Budgeting", systemImage: "chart.bar.fill")
                }
            Chatbot()
                .tabItem {
                    Label("Chatbot", systemImage: "message.fill")
                }
            
            ReminderView()
                .tabItem {
                    Label("Reminders", systemImage: "bell.fill")
                }
        }
    }
}
