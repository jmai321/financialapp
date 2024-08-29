import SwiftUI
import UserNotifications

struct Reminder: Identifiable {
    let id = UUID()  // Unique identifier for each reminder
    var name: String // Name of the payment
    var date: Date   // Due date of the payment
}

struct ReminderView: View {
    @State private var reminders: [Reminder] = [] // List of reminders
    @State private var isShowingReminderForm = false // Controls the visibility of the reminder form
    @State private var reminderToEdit: Reminder? // Holds the reminder being edited, if any
    
    var body: some View {
        NavigationView {
            List {
                ForEach(reminders) { reminder in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(reminder.name) // Display the reminder name
                            Text(reminder.date, style: .date) // Display the reminder date
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            reminderToEdit = reminder // Set the reminder to be edited
                            isShowingReminderForm = true // Show the reminder form
                        }) {
                            Image(systemName: "pencil") // Edit icon
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .onDelete(perform: deleteReminder) // Enable deletion of reminders
            }
            .navigationTitle("Upcoming Bills") // Title of the view
            .navigationBarItems(trailing: Button(action: {
                reminderToEdit = nil // No reminder to edit
                isShowingReminderForm = true // Show the reminder form
            }) {
                Image(systemName: "plus") // Add icon
            })
            .sheet(isPresented: $isShowingReminderForm) {
                ReminderFormView(reminders: $reminders, reminderToEdit: $reminderToEdit) // Show the form view
            }
            .onAppear(perform: requestNotificationPermission) // Request notification permission on view appear
        }
    }
    
    // Function to delete a reminder
    private func deleteReminder(at offsets: IndexSet) {
        reminders.remove(atOffsets: offsets)
    }
    
    // Request permission to show notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Failed to request authorization: \(error.localizedDescription)")
            }
        }
    }
}

struct ReminderFormView: View {
    @Binding var reminders: [Reminder] // Binding to the list of reminders
    @Binding var reminderToEdit: Reminder? // Binding to the reminder being edited
    @Environment(\.presentationMode) var presentationMode // Environment value to manage the view's presentation
    
    @State private var reminderName: String = "" // State for the reminder name
    @State private var reminderDate: Date = Date() // State for the reminder date
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Payment Name", text: $reminderName) // Input field for the payment name
                DatePicker("Due Date", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute]) // Date picker for the due date
            }
            .navigationBarTitle(reminderToEdit == nil ? "Add Payment" : "Edit Reminder", displayMode: .inline) // Title of the form
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss() // Dismiss the form
            }, trailing: Button("Save") {
                saveReminder() // Save the reminder
                presentationMode.wrappedValue.dismiss() // Dismiss the form
            })
        }
        .onAppear {
            // Populate the form fields if editing an existing reminder
            if let reminder = reminderToEdit {
                reminderName = reminder.name
                reminderDate = reminder.date
            }
        }
    }
    
    // Function to save a reminder
    private func saveReminder() {
        if let index = reminders.firstIndex(where: { $0.id == reminderToEdit?.id }) {
            // Update existing reminder
            reminders[index].name = reminderName
            reminders[index].date = reminderDate
            scheduleNotification(for: reminders[index]) // Schedule notification for the updated reminder
        } else {
            // Add new reminder
            let newReminder = Reminder(name: reminderName, date: reminderDate)
            reminders.append(newReminder)
            scheduleNotification(for: newReminder) // Schedule notification for the new reminder
        }
    }
    
    // Function to schedule a notification for a reminder
    private func scheduleNotification(for reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = "Payment Reminder"
        content.body = "Don't forget to pay: \(reminder.name)"
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}

// Preview provider for the main view
struct ReminderView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderView()
    }
}
