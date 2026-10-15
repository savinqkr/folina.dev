import SwiftUI

struct ContentView: View {
    var body: some View {
        BookshelfView(diaries: SampleDiaries.bookshelf)
    }
}

#Preview {
    ContentView()
}
