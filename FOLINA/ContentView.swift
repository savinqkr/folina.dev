import SwiftUI

struct ContentView: View {
    @State private var library = DiaryLibrary()

    var body: some View {
        NavigationStack {
            BookshelfView(diaries: library.documents.map(\.summary))
                .toolbar(.hidden, for: .navigationBar)
        }
        .environment(library)
        .task { await library.load() }
    }
}

#Preview { ContentView() }
