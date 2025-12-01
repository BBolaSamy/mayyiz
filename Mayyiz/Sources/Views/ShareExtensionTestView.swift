import SwiftUI
import UIKit

struct ShareExtensionTestView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share Extension Test")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Test the Share Extension by sharing a screenshot")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                // Display selected image
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .padding()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 300)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No image selected")
                                    .foregroundColor(.secondary)
                            }
                        )
                        .padding()
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Label("Select Screenshot", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    if selectedImage != nil {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share to Mayyiz Extension", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions:")
                        .font(.headline)
                    
                    Text("1. Tap 'Select Screenshot' to choose an image")
                    Text("2. Tap 'Share to Mayyiz Extension'")
                    Text("3. Select 'Mayyiz' from the share sheet")
                    Text("4. The extension will process and open the main app")
                    Text("5. OCR will extract text from the image")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = selectedImage {
                    ShareSheet(activityItems: [image])
                }
            }
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

struct ShareExtensionTestView_Previews: PreviewProvider {
    static var previews: some View {
        ShareExtensionTestView()
    }
}
