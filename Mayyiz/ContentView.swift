//
//  ContentView.swift
//  Mayyiz
//
//  Created by Bola Samy on 09/11/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var testResult: String = "Tap button to test"
    @State private var testStatus: TestStatus = .idle
    
    enum TestStatus {
        case idle, success, failure
        
        var color: Color {
            switch self {
            case .idle: return .secondary
            case .success: return .green
            case .failure: return .red
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Icon/Logo placeholder
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Mayyiz")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("iOS App with Share Extension")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.horizontal)
                
                // Test Section
                VStack(spacing: 15) {
                    Text("App Group Test")
                        .font(.headline)
                    
                    Text(testResult)
                        .font(.caption)
                        .foregroundColor(testStatus.color)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: testSharedContainer) {
                        Label("Test Shared Container", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Configuration Info
                VStack(spacing: 8) {
                    InfoRow(label: "Bundle ID", value: "com.mayyiz.app")
                    InfoRow(label: "App Group", value: "group.com.mayyiz.shared")
                    InfoRow(label: "URL Scheme", value: "mayyiz://")
                }
                .font(.caption)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .navigationTitle("Mayyiz")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func testSharedContainer() {
        do {
            // Test 1: Write and read file
            let testData = "Hello from Mayyiz! \(Date())"
            try SharedContainer.writeData(testData.data(using: .utf8)!, to: "test.txt")
            
            let readData = try SharedContainer.readData(from: "test.txt")
            guard let readText = String(data: readData, encoding: .utf8) else {
                throw SharedContainerError.invalidData
            }
            
            // Test 2: UserDefaults
            SharedContainer.saveToDefaults("Test Value", forKey: "testKey")
            let value: String? = SharedContainer.readFromDefaults(forKey: "testKey")
            
            // Test 3: Codable
            struct TestObject: Codable {
                let message: String
                let timestamp: Date
            }
            
            let testObject = TestObject(message: "Codable test", timestamp: Date())
            try SharedContainer.saveCodable(testObject, to: "test.json")
            let loadedObject = try SharedContainer.loadCodable(TestObject.self, from: "test.json")
            
            // All tests passed
            testResult = """
            ✅ All tests passed!
            
            File I/O: \(readText.prefix(20))...
            UserDefaults: \(value ?? "nil")
            Codable: \(loadedObject.message)
            
            Container URL:
            \(SharedContainer.containerURL?.path ?? "Not available")
            """
            testStatus = .success
            
            // Cleanup
            try? SharedContainer.deleteFile("test.txt")
            try? SharedContainer.deleteFile("test.json")
            SharedContainer.removeFromDefaults(forKey: "testKey")
            
        } catch {
            testResult = """
            ❌ Test failed!
            
            Error: \(error.localizedDescription)
            
            Make sure App Groups are properly configured in Xcode:
            1. Select Mayyiz target
            2. Signing & Capabilities
            3. Add App Groups capability
            4. Enable: group.com.mayyiz.shared
            """
            testStatus = .failure
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ContentView()
}

