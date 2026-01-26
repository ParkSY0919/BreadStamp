import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("스탬프북", systemImage: "house.fill")
                }

            CollectionView()
                .tabItem {
                    Label("도감", systemImage: "book.fill")
                }

            MapTabView()
                .tabItem {
                    Label("지도", systemImage: "map.fill")
                }

            ProfileView()
                .tabItem {
                    Label("프로필", systemImage: "person.fill")
                }
        }
        .tint(Color.brandPrimary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Bakery.self, Bread.self], inMemory: true)
}
