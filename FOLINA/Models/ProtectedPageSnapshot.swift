import Foundation

struct ProtectedPageSnapshot: Identifiable {
    let id: String
    let pageID: UUID
    let createdAt: Date
    let ink: PageInk?
    let decoration: PageDecoration?
    var title: String { ink == nil ? "꾸미기 보호 사본" : "필기 보호 사본" }
}
