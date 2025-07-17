import SwiftUI

struct DocumentStatisticsView: View {
    @ObservedObject var documentStore: DocumentStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Overall Statistics
                Section("Overall Statistics") {
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
                
                // Block Statistics
                Section("Block Statistics") {
                    StatisticRow(
                        title: "Total Blocks",
                        value: "\(totalBlocks)",
                        icon: "square.stack.3d.up"
                    )
                    
                    StatisticRow(
                        title: "Heading Blocks",
                        value: "\(headingBlocks)",
                        icon: "textformat.size"
                    )
                    
                    StatisticRow(
                        title: "Paragraph Blocks",
                        value: "\(paragraphBlocks)",
                        icon: "text.alignleft"
                    )
                    
                    StatisticRow(
                        title: "Average Blocks per Document",
                        value: String(format: "%.1f", averageBlocksPerDocument),
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
                
                // Most Active Tags
                Section("Most Active Tags") {
                    ForEach(Array(topTags.enumerated()), id: \.offset) { index, tagData in
                        HStack {
                            Text("#\(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .leading)
                            
                            Text("#\(tagData.tag)")
                                .font(.body)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text("\(tagData.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Backup & Recovery
                Section("Backup & Recovery") {
                    Button(action: {
                        exportAllDocuments()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export All Documents")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        cleanupBackupFiles()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clean Backup Files")
                                .foregroundColor(.red)
                        }
                    }
                    
                    StatisticRow(
                        title: "Backup Files",
                        value: "\(backupFileCount)",
                        icon: "doc.badge.gearshape"
                    )
                }
            }
            .navigationTitle("Document Statistics")
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
    
    private var totalBlocks: Int {
        return documentStore.documents.reduce(0) { $0 + $1.blocks.count }
    }
    
    private var headingBlocks: Int {
        return documentStore.documents.reduce(0) { total, document in
            total + document.blocks.filter { $0.blockType == .heading }.count
        }
    }
    
    private var paragraphBlocks: Int {
        return documentStore.documents.reduce(0) { total, document in
            total + document.blocks.filter { $0.blockType == .paragraph }.count
        }
    }
    
    private var averageBlocksPerDocument: Double {
        guard documentStore.totalDocuments > 0 else { return 0.0 }
        return Double(totalBlocks) / Double(documentStore.totalDocuments)
    }
    
    private var topTags: [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]
        
        for document in documentStore.documents {
            for tag in document.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts.sorted { $0.value > $1.value }
            .prefix(10)
            .map { (tag: $0.key, count: $0.value) }
    }
    
    private var backupFileCount: Int {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MagicNotes", isDirectory: true)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path)
            return files.filter { $0.hasSuffix(".backup") }.count
        } catch {
            return 0
        }
    }
    
    // MARK: - Actions
    
    private func exportAllDocuments() {
        let exportData = documentStore.documents.map { document in
            """
            # \(document.generatedTitle)
            Created: \(document.createdAt)
            Last Edited: \(document.lastEditedAt)
            Word Count: \(document.totalWordCount)
            Tags: \(document.tags.joined(separator: ", "))
            
            \(document.blocks.map { block in
                switch block.blockType {
                case .heading:
                    return "# \(block.content)"
                case .paragraph:
                    return block.content
                }
            }.joined(separator: "\n\n"))
            
            ---
            
            """
        }.joined(separator: "\n")
        
        let activityVC = UIActivityViewController(activityItems: [exportData], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func cleanupBackupFiles() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MagicNotes", isDirectory: true)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path)
            let backupFiles = files.filter { $0.hasSuffix(".backup") }
            
            for backupFile in backupFiles {
                let backupURL = documentsDirectory.appendingPathComponent(backupFile)
                try FileManager.default.removeItem(at: backupURL)
            }
            
            print("Cleaned up \(backupFiles.count) backup files")
        } catch {
            print("Failed to clean backup files: \(error.localizedDescription)")
        }
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