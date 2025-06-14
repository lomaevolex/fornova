import SwiftUI
import PDFKit
import CoreData

struct MergeView: View {
    let base: DocumentEntity
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DocumentEntity.creationDate,
                                           ascending: false)]
    ) private var docs: FetchedResults<DocumentEntity>

    var body: some View {
        List {
            ForEach(docs.filter { $0.objectID != base.objectID }) { other in
                Button {
                    merge(base: base, with: other)
                    dismiss()
                } label: {
                    Text(other.title ?? "")
                }
            }
        }
    }

    private func merge(base: DocumentEntity, with other: DocumentEntity) {
        guard let p1 = base.url, let p2 = other.url else { return }
        let url1 = URL(fileURLWithPath: p1)
        let url2 = URL(fileURLWithPath: p2)
        guard let d1 = PDFDocument(url: url1),
              let d2 = PDFDocument(url: url2)
        else { return }

        let merged = PDFDocument()
        for i in 0..<d1.pageCount {
            if let page = d1.page(at: i) { merged.insert(page, at: merged.pageCount) }
        }
        for i in 0..<d2.pageCount {
            if let page = d2.page(at: i) { merged.insert(page, at: merged.pageCount) }
        }

        let newTitle = "\(base.title ?? "")＋\(other.title ?? "")"
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(newTitle).pdf")
        merged.write(to: fileURL)

        let ctx = DataService.shared.context
        let newDoc = DocumentEntity(context: ctx)
        newDoc.id = UUID()
        newDoc.title = newTitle
        newDoc.creationDate = Date()
        newDoc.url = fileURL.path
        newDoc.thumbnail = PDFService.generateThumbnail(from: fileURL)
        try? DataService.shared.saveContext()
    }
}
