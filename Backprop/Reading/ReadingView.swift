import SafariServices
import SwiftUI

/// Curated, bundled list of ML/AI books, articles, papers and courses.
/// Links open in SFSafariViewController so the user never leaves the app.
struct ReadingView: View {
    @State private var result = ReadingLibrary.loadBundled()
    @State private var kindFilter: ReadingItem.Kind?
    @State private var openItem: ReadingItem?

    var body: some View {
        NavigationStack {
            Group {
                switch result {
                case .success(let items):
                    list(items)
                case .failure(let error):
                    ContentUnavailableView(
                        "Reading list failed to load",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.description)
                    )
                }
            }
            .navigationTitle("Reading")
            .sheet(item: $openItem) { item in
                SafariView(url: item.url).ignoresSafeArea()
            }
        }
    }

    private func list(_ items: [ReadingItem]) -> some View {
        let filtered = items.filter { kindFilter == nil || $0.kind == kindFilter }
        let byLevel = Dictionary(grouping: filtered, by: \.level)
        return List {
            Section {
                Picker("Type", selection: $kindFilter) {
                    Text("All").tag(ReadingItem.Kind?.none)
                    ForEach(ReadingItem.Kind.allCases, id: \.self) { kind in
                        Text(kind.title).tag(Optional(kind))
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            ForEach(byLevel.keys.sorted(), id: \.self) { level in
                Section(level.title) {
                    ForEach(byLevel[level] ?? []) { item in
                        Button { openItem = item } label: { ReadingRow(item: item) }
                            .accessibilityHint("Opens in Safari")
                    }
                }
            }
        }
        .overlay {
            if filtered.isEmpty {
                ContentUnavailableView("Nothing here yet", systemImage: "books.vertical")
            }
        }
    }
}

private struct ReadingRow: View {
    let item: ReadingItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.kind.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.headline).foregroundStyle(.primary)
                Text(item.year.map { "\(item.authors) · \(String($0))" } ?? item.authors)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.summary).font(.subheadline).foregroundStyle(.primary)
                Text(item.topic)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.tint.opacity(0.15), in: Capsule())
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
