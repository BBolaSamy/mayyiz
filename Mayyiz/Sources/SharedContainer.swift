import Foundation

/// Helper class to manage shared container access between the main app and Share Extension
public final class SharedContainer {
    
    // MARK: - Properties
    
    /// The App Group identifier shared between targets
    public static let appGroupIdentifier = "group.com.mayyiz.shared"
    
    /// Shared container URL
    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    // MARK: - File Management
    
    /// Get URL for a file in the shared container
    /// - Parameter fileName: Name of the file
    /// - Returns: URL for the file, or nil if container is not accessible
    public static func fileURL(for fileName: String) -> URL? {
        containerURL?.appendingPathComponent(fileName)
    }
    
    /// Write data to a file in the shared container
    /// - Parameters:
    ///   - data: Data to write
    ///   - fileName: Name of the file
    /// - Throws: Error if writing fails
    public static func writeData(_ data: Data, to fileName: String) throws {
        guard let url = fileURL(for: fileName) else {
            throw SharedContainerError.containerNotAccessible
        }
        
        // Ensure parent directory exists
        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        try data.write(to: url, options: .atomic)
    }
    
    /// Read data from a file in the shared container
    /// - Parameter fileName: Name of the file
    /// - Returns: Data from the file
    /// - Throws: Error if reading fails
    public static func readData(from fileName: String) throws -> Data {
        guard let url = fileURL(for: fileName) else {
            throw SharedContainerError.containerNotAccessible
        }
        return try Data(contentsOf: url)
    }
    
    /// Delete a file from the shared container
    /// - Parameter fileName: Name of the file to delete
    /// - Throws: Error if deletion fails
    public static func deleteFile(_ fileName: String) throws {
        guard let url = fileURL(for: fileName) else {
            throw SharedContainerError.containerNotAccessible
        }
        try FileManager.default.removeItem(at: url)
    }
    
    /// Check if a file exists in the shared container
    /// - Parameter fileName: Name of the file
    /// - Returns: True if the file exists, false otherwise
    public static func fileExists(_ fileName: String) -> Bool {
        guard let url = fileURL(for: fileName) else {
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    /// List all files in the shared container
    /// - Returns: Array of file names
    /// - Throws: Error if listing fails
    public static func listFiles() throws -> [String] {
        guard let url = containerURL else {
            throw SharedContainerError.containerNotAccessible
        }
        return try FileManager.default.contentsOfDirectory(atPath: url.path)
    }
    
    // MARK: - UserDefaults
    
    /// Shared UserDefaults for the app group
    public static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    /// Save a value to shared UserDefaults
    /// - Parameters:
    ///   - value: Value to save
    ///   - key: Key to save the value under
    public static func saveToDefaults<T>(_ value: T, forKey key: String) {
        sharedDefaults?.set(value, forKey: key)
        sharedDefaults?.synchronize()
    }
    
    /// Read a value from shared UserDefaults
    /// - Parameter key: Key to read the value from
    /// - Returns: Value for the key, or nil if not found
    public static func readFromDefaults<T>(forKey key: String) -> T? {
        sharedDefaults?.object(forKey: key) as? T
    }
    
    /// Remove a value from shared UserDefaults
    /// - Parameter key: Key to remove
    public static func removeFromDefaults(forKey key: String) {
        sharedDefaults?.removeObject(forKey: key)
        sharedDefaults?.synchronize()
    }
    
    // MARK: - Codable Support
    
    /// Save a Codable object to the shared container
    /// - Parameters:
    ///   - object: Object to save
    ///   - fileName: Name of the file
    /// - Throws: Error if encoding or writing fails
    public static func saveCodable<T: Encodable>(_ object: T, to fileName: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(object)
        try writeData(data, to: fileName)
    }
    
    /// Load a Codable object from the shared container
    /// - Parameters:
    ///   - type: Type of the object to load
    ///   - fileName: Name of the file
    /// - Returns: Decoded object
    /// - Throws: Error if reading or decoding fails
    public static func loadCodable<T: Decodable>(_ type: T.Type, from fileName: String) throws -> T {
        let data = try readData(from: fileName)
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}

// MARK: - Error Types

public enum SharedContainerError: LocalizedError {
    case containerNotAccessible
    case fileNotFound
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .containerNotAccessible:
            return "Shared container is not accessible. Make sure App Groups are properly configured."
        case .fileNotFound:
            return "The requested file was not found in the shared container."
        case .invalidData:
            return "The data in the shared container is invalid or corrupted."
        }
    }
}
