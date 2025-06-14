import SwiftUI
import PhotosUI
import UIKit
import CoreData

@MainActor
final class PDFGeneratorViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    @Published var isLoading = false

    func generate(title: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let url = try PDFService.createPDF(from: images, title: title)
            let thumbData = PDFService.generateThumbnail(from: url)
            let ctx = DataService.shared.context
            let doc = DocumentEntity(context: ctx)
            doc.id = UUID()
            doc.title = title
            doc.creationDate = Date()
            doc.url = url.path
            doc.thumbnail = thumbData
            try DataService.shared.saveContext()
        } catch {
            print("Ошибка создания PDF: \(error)")
        }
    }
}
