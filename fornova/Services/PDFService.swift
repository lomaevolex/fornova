import UIKit
import PDFKit

final class PDFService {
    /// Размер страницы A4 в пунктах: 595×842
    private static let a4Size = CGSize(width: 595, height: 842)

    /// Создаёт PDF формата A4, с картинками, вписанными по размеру страницы
    static func createPDF(from images: [UIImage], title: String) throws -> URL {
        guard !images.isEmpty else {
            throw NSError(
                domain: "PDFService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Нет изображений"]
            )
        }

        let pageSize = a4Size
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize),
            format: format
        )

        let data = renderer.pdfData { ctx in
            for image in images {
                ctx.beginPage()
                let scale = min(
                    pageSize.width / image.size.width,
                    pageSize.height / image.size.height
                )
                let scaledSize = CGSize(
                    width: image.size.width * scale,
                    height: image.size.height * scale
                )
                let origin = CGPoint(
                    x: (pageSize.width - scaledSize.width) / 2,
                    y: (pageSize.height - scaledSize.height) / 2
                )
                image.draw(in: CGRect(origin: origin, size: scaledSize))
            }
        }

        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(title).pdf")
        try data.write(to: fileURL)
        return fileURL
    }

    /// Генерирует миниатюру первой страницы
    static func generateThumbnail(from url: URL) -> Data? {
        guard let doc = PDFDocument(url: url),
              let page = doc.page(at: 0) else { return nil }
        let thumb = page.thumbnail(of: CGSize(width: 100, height: 100), for: .cropBox)
        return thumb.pngData()
    }
}

// Расширение вынесено за пределы класса
extension PDFService {
    static func appendTextPage(to pdfURL: URL, text: String) throws {
        guard let pdf = PDFDocument(url: pdfURL) else { throw NSError() }
        let size = CGSize(width: 595, height: 842)  // A4
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let style = NSMutableParagraphStyle(); style.alignment = .left
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: style
            ]
            let rect = CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 40)
            (text as NSString).draw(in: rect, withAttributes: attrs)
        }
        if let newPage = PDFDocument(data: data)?.page(at: 0) {
            pdf.insert(newPage, at: pdf.pageCount)
            pdf.write(to: pdfURL)
        }
    }
}
