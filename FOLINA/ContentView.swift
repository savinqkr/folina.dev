import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            BookshelfView(diaries: SampleDiaries.bookshelf)
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ContentView()
}
