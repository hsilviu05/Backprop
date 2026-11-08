import SafariServices
import SwiftUI

/// Curated, bundled list of ML/AI books, videos, articles, papers and courses.
/// Videos open in the YouTube app (or Safari if it isn't installed); everything
/// else opens in SFSafariViewController so the user stays in the app.
struct ReadingView: View {
    @State private var result = ReadingLibrary.loadBundled()
    @State private var kindFilter: ReadingItem.Kind?
    @State private var safariItem: ReadingItem?
    @Environment(\.openURL) private var openURL

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Show", selection: $kindFilter.animation(.snappy)) {
                            Label("Everything", systemImage: "square.grid.2x2").tag(ReadingItem.Kind?.none)
                            ForEach(ReadingItem.Kind.allCases, id: \.self) { kind in
                                Label(kind.title, systemImage: kind.systemImage).tag(Optional(kind))
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: kindFilter == nil
                              ? "line.3.horizontal.decrease.circle"
                              : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
            .sheet(item: $safariItem) { item in
                SafariView(url: item.url).ignoresSafeArea()
            }
        }
    }

    private func open(_ item: ReadingItem) {
        if item.kind == .video {
            openURL(item.url)
        } else {
            safariItem = item
        }
    }

    private func shows(_ kind: ReadingItem.Kind) -> Bool {
        kindFilter == nil || kindFilter == kind
    }

    private func list(_ items: [ReadingItem]) -> some View {
        let books = Self.byLevel(items.filter { $0.kind == .book })
        let videos = Self.byLevel(items.filter { $0.kind == .video })
        let others = items.filter { $0.kind != .book && $0.kind != .video && shows($0.kind) }
        let othersByLevel = Dictionary(grouping: others, by: \.level)
        let isFiltered = kindFilter != nil

        return List {
            if shows(.book), !books.isEmpty {
                Section {
                    if isFiltered {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 16)], spacing: 20) {
                            ForEach(books) { book in
                                Button { open(book) } label: { BookCover(item: book) }
                                    .buttonStyle(PressableButtonStyle())
                            }
                        }
                        .padding(.vertical, 8)
                    } else {
                        Shelf {
                            ForEach(books) { book in
                                Button { open(book) } label: { BookCover(item: book).frame(width: 104) }
                                    .buttonStyle(PressableButtonStyle())
                            }
                        }
                    }
                } header: {
                    Text("Books")
                } footer: {
                    Link("Covers from Open Library", destination: URL(string: "https://openlibrary.org")!)
                        .font(.caption2)
                }
            }

            if shows(.video), !videos.isEmpty {
                Section("Videos") {
                    if isFiltered {
                        ForEach(videos) { video in
                            Button { open(video) } label: { VideoCard(item: video) }
                                .buttonStyle(PressableButtonStyle())
                        }
                    } else {
                        Shelf {
                            ForEach(videos) { video in
                                Button { open(video) } label: { VideoCard(item: video).frame(width: 240) }
                                    .buttonStyle(PressableButtonStyle())
                            }
                        }
                    }
                }
            }

            ForEach(othersByLevel.keys.sorted(), id: \.self) { level in
                Section(isFiltered ? level.title : "\(level.title) reads") {
                    ForEach(othersByLevel[level] ?? []) { item in
                        Button { open(item) } label: { ReadingRow(item: item) }
                            .tint(.primary)
                            .accessibilityHint("Opens in Safari")
                    }
                }
            }
        }
    }

    /// Beginner first, keeping the curated order within a level.
    private static func byLevel(_ items: [ReadingItem]) -> [ReadingItem] {
        items.enumerated()
            .sorted { ($0.element.level, $0.offset) < ($1.element.level, $1.offset) }
            .map(\.element)
    }
}

/// Horizontally scrolling row that bleeds to the list row edges.
private struct Shelf<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 14) { content }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .scrollClipDisabled()
        .listRowInsets(EdgeInsets())
        // Shelves sit on the page background so cards can scroll past the screen edge.
        .listRowBackground(Color.clear)
    }
}

private struct BookCover: View {
    let item: ReadingItem

    var body: some View {
        Color.clear
            .aspectRatio(2 / 3, contentMode: .fit)
            .overlay {
                AsyncImage(url: item.coverURL, transaction: Transaction(animation: .easeOut(duration: 0.3))) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill().transition(.opacity)
                    } else {
                        GeneratedCover(item: item)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(.primary.opacity(0.08)))
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
            .accessibilityElement()
            .accessibilityLabel("\(item.title), by \(item.authors)")
            .accessibilityHint("Opens in Safari")
    }
}

/// Shown while a cover loads, and for books with no print cover.
private struct GeneratedCover: View {
    let item: ReadingItem

    private static let palette: [Color] = [.indigo, .teal, .orange, .pink, .blue, .green, .purple, .brown]

    private var color: Color {
        // Stable across launches, unlike hashValue.
        let seed = item.id.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return Self.palette[seed % Self.palette.count]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .lineLimit(5)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                Text(item.authors)
                    .font(.caption2)
                    .lineLimit(2)
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .padding(10)
        }
    }
}

private struct VideoCard: View {
    let item: ReadingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.secondary.opacity(0.15)
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay {
                    AsyncImage(url: item.thumbnailURL, transaction: Transaction(animation: .easeOut(duration: 0.3))) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill().transition(.opacity)
                        }
                    }
                }
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.black.opacity(0.45), in: Circle())
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
            Text(item.authors)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens in YouTube")
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

/// Gentle press-down feedback for cover and video cards.
private struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
