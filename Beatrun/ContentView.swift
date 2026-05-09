import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(.tint)

                VStack(spacing: 8) {
                    Text("Beatrun")
                        .font(.largeTitle.bold())

                    Text("Track rhythm, movement, and progress in one focused iOS app.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .navigationTitle("Beatrun")
        }
    }
}

#Preview {
    ContentView()
}
