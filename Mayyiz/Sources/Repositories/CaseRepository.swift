import Foundation
import FirebaseFirestore
import Combine

class CaseRepository {
    private let db = Firestore.firestore()
    
    /// Save a new case and update user counters
    /// - Parameters:
    ///   - userId: The user's ID
    ///   - casePayload: The case data to save
    func save(userId: String, casePayload: CasePayload) async throws {
        let batch = db.batch()
        
        // 1. Reference for the new case
        let casesRef = db.collection("users").document(userId).collection("cases").document()
        
        // Encode the payload
        // We need to handle the optional ID manually or let Firestore generate it.
        // Since we are using a batch, we generated the ref above.
        // We'll encode the struct to a dictionary to pass to batch.setData
        let data = try Firestore.Encoder().encode(casePayload)
        batch.setData(data, forDocument: casesRef)
        
        // 2. Reference for counters
        let countersRef = db.collection("users").document(userId).collection("counters").document("stats")
        
        // 3. Increment counters
        var counterUpdates: [String: Any] = [
            "totalCases": FieldValue.increment(Int64(1)),
            "lastActive": Timestamp(date: Date())
        ]
        
        if casePayload.result.riskScore >= 70 {
            counterUpdates["highRiskCases"] = FieldValue.increment(Int64(1))
        }
        
        // Use set with merge to create if not exists
        batch.setData(counterUpdates, forDocument: countersRef, merge: true)
        
        // 4. Commit batch
        try await batch.commit()
    }
    
    /// Fetch cases for a user
    func fetchCases(userId: String, limit: Int = 20) async throws -> [CasePayload] {
        let snapshot = try await db.collection("users").document(userId).collection("cases")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.map { document in
            try document.data(as: CasePayload.self)
        }
    }
    
    /// Fetch user counters
    func fetchCounters(userId: String) async throws -> UserCounters? {
        let document = try await db.collection("users").document(userId).collection("counters").document("stats").getDocument()
        
        if document.exists {
            return try document.data(as: UserCounters.self)
        }
        return nil
    }
}
