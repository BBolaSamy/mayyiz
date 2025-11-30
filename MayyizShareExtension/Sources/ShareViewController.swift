import UIKit
import Social
import UniformTypeIdentifiers

/// Share Extension View Controller
class ShareViewController: UIViewController {
    
    // MARK: - Properties
    
    private var sharedText: String?
    private var sharedURL: URL?
    private var sharedImages: [UIImage] = []
    private let shareId = UUID().uuidString
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractSharedContent()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = "Share to Mayyiz"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Preparing content for analysis..."
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        let shareButton = UIButton(type: .system)
        shareButton.setTitle("Share", for: .normal)
        shareButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(cancelButton)
        view.addSubview(shareButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            shareButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Content Extraction
    
    private func extractSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProviders = extensionItem.attachments else {
            return
        }
        
        for provider in itemProviders {
            // Handle URLs
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
                    if let url = item as? URL {
                        DispatchQueue.main.async {
                            self?.sharedURL = url
                        }
                    }
                }
            }
            
            // Handle text
            if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { [weak self] (item, error) in
                    if let text = item as? String {
                        DispatchQueue.main.async {
                            self?.sharedText = text
                        }
                    }
                }
            }
            
            // Handle images
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, error) in
                    if let url = item as? URL,
                       let imageData = try? Data(contentsOf: url),
                       let image = UIImage(data: imageData) {
                        DispatchQueue.main.async {
                            self?.sharedImages.append(image)
                        }
                    } else if let image = item as? UIImage {
                        DispatchQueue.main.async {
                            self?.sharedImages.append(image)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        extensionContext?.cancelRequest(withError: NSError(domain: "com.mayyiz.app.share", code: -1, userInfo: nil))
    }
    
    @objc private func shareTapped() {
        saveSharedContent()
        openMainApp()
    }
    
    // MARK: - Data Persistence
    
    private func saveSharedContent() {
        var imagePaths: [String] = []
        
        // Save images to shared container
        for (index, image) in sharedImages.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                // Use shared/ directory. Primary image gets the ID, others get index suffix.
                let fileName = index == 0 ? "shared/\(shareId).jpg" : "shared/\(shareId)_\(index).jpg"
                do {
                    try SharedContainer.writeData(imageData, to: fileName)
                    imagePaths.append(fileName)
                    print("✅ Saved image: \(fileName)")
                } catch {
                    print("❌ Error saving image: \(error)")
                }
            }
        }
        
        // Create SharedContent object
        let sharedContent = SharedContent(
            id: shareId,
            timestamp: Date(),
            text: sharedText,
            url: sharedURL?.absoluteString,
            imagePaths: imagePaths
        )
        
        // Save to SharedContainer using new format
        let key = "share_\(shareId)"
        SharedContainer.saveToDefaults(sharedContent, forKey: key)
        
        // Also save as JSON file for redundancy in shared/ directory
        do {
            try SharedContainer.saveCodable(sharedContent, to: "shared/\(shareId).json")
            print("✅ Saved shared content with ID: \(shareId)")
        } catch {
            print("❌ Error saving shared content: \(error)")
        }
    }
    
    private func openMainApp() {
        // Build URL with share ID parameter
        guard let url = URLHandler.buildShareURL(shareId: shareId) else {
            print("❌ Failed to build share URL")
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        print("🔗 Opening main app with URL: \(url.absoluteString)")
        
        // Try to open the URL
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:]) { [weak self] success in
                    print(success ? "✅ Successfully opened main app" : "❌ Failed to open main app")
                    self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
                return
            }
            responder = responder?.next
        }
        
        // Fallback: complete the request
        print("⚠️ Could not find UIApplication, completing request")
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
