import Foundation

struct ObjectColor: Codable, Equatable {
    var red: Double = 0
    var green: Double = 0
    var blue: Double = 0
    var alpha: Double = 1
    var isValid: Bool { [red, green, blue, alpha].allSatisfy { $0.isFinite && (0...1).contains($0) } }
}

enum PhotoStyle: String, Codable, CaseIterable, Identifiable {
    case plain, polaroid, corners
    var id: Self { self }
    var title: String { switch self { case .plain: "일반"; case .polaroid: "폴라로이드"; case .corners: "종이 코너" } }
}

struct PageObject: Codable, Equatable, Identifiable {
    enum Kind: String, Codable { case text, photo }
    var id: UUID = UUID()
    var pageID: UUID
    var kind: Kind
    var text: String = ""
    var fontName: String = "system"
    var fontSize: Double = 28
    var color = ObjectColor()
    var assetID: UUID?
    var photoStyle: PhotoStyle = .plain
    /// 중심 좌표와 크기. 화면 크기와 무관한 페이지 논리 단위입니다.
    var x: Double = 180
    var y: Double = 180
    var width: Double = 280
    var height: Double = 160
    var rotation: Double = 0
    var zIndex: Int = 0

    func validate(pageID: UUID) throws {
        guard self.pageID == pageID,
              [x, y, width, height, rotation, fontSize].allSatisfy(\.isFinite),
              width > 0, height > 0, fontSize > 0, color.isValid,
              kind != .photo || assetID != nil else { throw DiaryStorageError.damagedDocument }
    }
}

struct PageDecoration: Codable, Equatable {
    var version = 1
    let diaryID: UUID
    var pageID: UUID
    let width: Double
    let height: Double
    var objects: [PageObject] = []

    init(page: DiaryPage, width: Double? = nil, height: Double? = nil) {
        diaryID = page.diaryID
        pageID = page.id
        self.width = width ?? page.widthMM * 4
        self.height = height ?? page.heightMM * 4
    }

    func validate(for page: DiaryPage) throws {
        guard version == 1 else { throw DiaryStorageError.unsupportedVersion }
        guard diaryID == page.diaryID, pageID == page.id,
              width.isFinite, height.isFinite, width > 0, height > 0,
              Set(objects.map(\.id)).count == objects.count else { throw DiaryStorageError.damagedDocument }
        for object in objects { try object.validate(pageID: pageID) }
    }

    func copied(to page: DiaryPage) -> Self {
        var copy = Self(page: page, width: width, height: height)
        copy.objects = objects.map {
            var object = $0
            object.id = UUID()
            object.pageID = page.id
            return object
        }
        return copy
    }
}
