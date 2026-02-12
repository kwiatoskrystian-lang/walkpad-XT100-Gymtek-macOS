import Foundation

struct UserProfile: Codable, Identifiable, Equatable {
    let id: String
    var displayName: String
    var petType: PetType
}
