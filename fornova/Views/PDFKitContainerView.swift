// PDFKitContainerView.swift

import SwiftUI
import PDFKit

// UIViewRepresentable — «представляемый вид UIView» (view ← англ. «вид»,
// от староангл. *ġewīsan* «показывать»; representable ← лат. *repraesentāre* «представлять»)
struct PDFKitContainerView: UIViewRepresentable {
    let pdfDocument: PDFDocument
    @Binding var currentPageIndex: Int

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = pdfDocument
        view.autoScales = true  // автоматически масштабирует (scale ← англ. «масштаб», от лат. *scala* «лестница»)
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // Прокрутка к текущей странице
        if let page = uiView.document?.page(at: currentPageIndex) {
            uiView.go(to: page)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, PDFViewDelegate {
        let parent: PDFKitContainerView
        init(parent: PDFKitContainerView) { self.parent = parent }

        func pdfViewPageChanged(_ sender: PDFView) {
            if let page = sender.currentPage,
               let idx = sender.document?.index(for: page) {
                parent.currentPageIndex = idx
            }
        }
    }
}
