import SwiftOpenAI
import Foundation
import SwiftUI
import Network

struct Chatbot: View {
    @StateObject private var chatbotManager = ChatbotManager()
    @State private var inputText: String = ""
    @State private var chatMessages: [ChatMessage] = []

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(chatMessages) { message in
                        HStack {
                            if message.role == .user {
                                Spacer()
                                Text(message.content)
                                    .padding()
                                    .background(Color.blue.opacity(0.7))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            } else {
                                Text(message.content)
                                    .padding()
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                        .padding(5)
                    }
                }
            }

            HStack {
                TextField("Enter message", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    sendMessage()
                }) {
                    Text("Send")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        .padding()
        .onAppear {
            sendFirstMessage()
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let userMessage = ChatMessage(role: .user, content: inputText)
        chatMessages.append(userMessage)
        chatbotManager.sendMessage(message: inputText) { response in
            DispatchQueue.main.async {
                if let response = response {
                    let botMessage = ChatMessage(role: .assistant, content: response)
                    chatMessages.append(botMessage)
                }
            }
        }
        inputText = ""
    }
    private func sendFirstMessage() {
        chatbotManager.sendMessage(message: "Act as a Financial Consultant. Your name is FinanceBot. Begin by introducing yourself to a new client.") { response in
            DispatchQueue.main.async {
                if let response = response {
                    let botMessage = ChatMessage(role: .assistant, content: response)
                    chatMessages.append(botMessage)
                }
            }
        }
        inputText = ""
    }
}

@MainActor
class ChatbotManager: ObservableObject {
    private let service: OpenAIService

    init() {
        // insert api key
        service = OpenAIServiceFactory.service(apiKey: "")
        testNetworkConnection()
    }

    func sendMessage(message: String, completion: @escaping (String?) -> Void) {
        Task {
            let parameters = ChatCompletionParameters(messages: [.init(role: .user, content: .text(message))], model: .gpt4o)
            do {
                let response = try await service.startChat(parameters: parameters)
                if let reply = response.choices.first?.message.content {
                    completion(reply)
                } else {
                    print("No valid response received")
                    completion(nil)
                }
            } catch let error as APIError {
                print("API Error: \(error.localizedDescription)")
                switch error {
                case .responseUnsuccessful(let description, let statusCode):
                    print("Response unsuccessful: \(description), Status code: \(statusCode)")
                default:
                    print("Other API error: \(error)")
                }
                completion(nil)
            } catch {
                print("Error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    func testNetworkConnection() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)

        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Connected to the network.")
            } else {
                print("No network connection.")
            }
            monitor.cancel()
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String

    enum Role {
        case user, assistant, system
    }
}
