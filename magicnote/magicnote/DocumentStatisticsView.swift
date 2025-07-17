import SwiftUI

struct DocumentStatisticsView: View {
    @ObservedObject var documentStore: DocumentStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Overall Statistics
                Section("Overview") {
                    StatisticRow(
                        title: "Total Documents",
                        value: "\(documentStore.totalDocuments)",
                        icon: "doc.text"
                    )
                    
                    StatisticRow(
                        title: "Total Words",
                        value: "\(documentStore.totalWords)",
                        icon: "textformat.123"
                    )
                    
                    StatisticRow(
                        title: "Total Storage",
                        value: documentStore.totalFileSize,
                        icon: "internaldrive"
                    )
                    
                    StatisticRow(
                        title: "Average Document Length",
                        value: "\(averageDocumentLength) words",
                        icon: "chart.bar"
                    )
                }
                
                // Document Distribution
                Section("Document Distribution") {
                    StatisticRow(
                        title: "Short Documents (< 100 words)",
                        value: "\(shortDocuments.count)",
                        icon: "doc.text"
                    )
                    
                    StatisticRow(
                        title: "Medium Documents (100-500 words)",
                        value: "\(mediumDocuments.count)",
                        icon: "doc.text"
                    )
                    
                    StatisticRow(
                        title: "Long Documents (> 500 words)",
                        value: "\(longDocuments.count)",
                        icon: "doc.richtext"
                    )
                }
                
                // Top Tags
                if !topTags.isEmpty {
                    Section("Popular Tags") {
                        ForEach(topTags, id: \.tag) { tagInfo in
                            HStack {
                                Image(systemName: "tag")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                Text("#\(tagInfo.tag)")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(tagInfo.count)")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var averageDocumentLength: Int {
        guard documentStore.totalDocuments > 0 else { return 0 }
        return documentStore.totalWords / documentStore.totalDocuments
    }
    
    private var shortDocuments: [Document] {
        return documentStore.documents.filter { $0.totalWordCount < 100 }
    }
    
    private var mediumDocuments: [Document] {
        return documentStore.documents.filter { $0.totalWordCount >= 100 && $0.totalWordCount <= 500 }
    }
    
    private var longDocuments: [Document] {
        return documentStore.documents.filter { $0.totalWordCount > 500 }
    }
    
    private var topTags: [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]
        
        for document in documentStore.documents {
            for tag in document.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { (tag: $0.key, count: $0.value) }
    }
}

// MARK: - Statistic Row View
struct StatisticRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview
#Preview {
    DocumentStatisticsView(documentStore: DocumentStore())
} 