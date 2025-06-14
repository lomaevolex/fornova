import SwiftUI
import PDFKit
import CoreData

struct PDFReaderView: View {
    @ObservedObject var document: DocumentEntity
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var pdfDoc: PDFDocument?
    @State private var currentPage = 0

    @State private var showingDictation = false
    @State private var showingPagePicker = false
    @State private var transcript = ""
    @State private var isTranscribing = false

    private let transcriber = SpeechTranscriber()

    var body: some View {
        VStack {
            if let pdf = pdfDoc {
                PDFKitContainerView(
                    pdfDocument: pdf,
                    currentPageIndex: $currentPage
                )
                .ignoresSafeArea()
                // Чтобы PDFKit реагировал на замену документа
                .id(pdf.documentURL)
            } else {
                Text("Не удалось загрузить PDF")
            }
        }
        .navigationTitle(document.title ?? "")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingDictation = true
                } label: {
                    Image(systemName: "mic.fill")
                }
                .tint(.purple)

                Button {
                    showingPagePicker = true
                } label: {
                    Image(systemName: "list.bullet.rectangle")
                }
                .tint(.blue)
            }
        }
        .onAppear(perform: loadDocument)
        .sheet(isPresented: $showingPagePicker) {
            if let pdf = pdfDoc {
                PagePickerView(
                    pdfDocument: pdf,
                    onDeleteMultiple: deletePages(at:),
                    onRotateMultiple: rotatePages(at:),
                    onMove: movePages(at:to:),
                    onCreate: createNewDocument(pages:title:)
                )
            }
        }
        .sheet(isPresented: $showingDictation) {
            NavigationView {
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(radius: 3)
                        TextEditor(text: $transcript)
                            .padding(8)
                    }
                    .frame(height: 200)

                    Button(isTranscribing ? "Отмена" : "Начать") {
                        if isTranscribing {
                            transcriber.stop()
                            isTranscribing = false
                        } else {
                            do {
                                try transcriber.startTranscribing { text in
                                    transcript = text
                                }
                                isTranscribing = true
                            } catch {
                                print("Ошибка транскрипции: \(error)")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Добавить страницу") {
                        guard let path = document.url else { return }
                        let fileURL = URL(fileURLWithPath: path)

                        // 1) Добавляем текстовую страницу
                        try? PDFService.appendTextPage(to: fileURL, text: transcript)
                        // 2) Сразу пересоздаём pdfDoc из файла
                        if let newDoc = PDFDocument(url: fileURL) {
                            pdfDoc = newDoc
                            // 3) Переключаемся на только что добавленную страницу
                            currentPage = newDoc.pageCount - 1
                        }
                        // 4) Обновляем CoreData миниатюру
                        document.thumbnail = PDFService.generateThumbnail(from: fileURL)
                        try? ctx.save()
                        showingDictation = false
                    }
                    .disabled(transcript.isEmpty)
                    .buttonStyle(.bordered)
                    .padding(.top, 10)

                    Spacer()
                }
                .padding()
                .navigationTitle("Диктовка")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            if isTranscribing {
                                transcriber.stop()
                                isTranscribing = false
                            }
                            showingDictation = false
                        }
                    }
                }
            }
        }
    }

    // MARK: – Helpers

    private func loadDocument() {
        guard let path = document.url else { return }
        let url = URL(fileURLWithPath: path)
        pdfDoc = PDFDocument(url: url)
        currentPage = 0
    }

    private func deletePages(at indices: [Int]) {
        guard var pdf = pdfDoc else { return }
        for idx in indices.sorted(by: >) where idx < pdf.pageCount {
            pdf.removePage(at: idx)
        }
        saveModified(pdf)
        pdfDoc = pdf
        currentPage = min(currentPage, pdf.pageCount - 1)
    }

    private func rotatePages(at indices: [Int]) {
        guard let pdf = pdfDoc else { return }
        for idx in indices where idx < pdf.pageCount {
            let page = pdf.page(at: idx)!
            page.rotation = (page.rotation + 90) % 360
        }
        saveModified(pdf)
    }

    private func movePages(at offsets: IndexSet, to destination: Int) {
        guard let pdf = pdfDoc else { return }
        var pages = (0..<pdf.pageCount).compactMap { pdf.page(at: $0) }
        pages.move(fromOffsets: offsets, toOffset: destination)
        let newDoc = PDFDocument()
        pages.forEach { newDoc.insert($0, at: newDoc.pageCount) }
        saveModified(newDoc)
        pdfDoc = newDoc
        currentPage = min(currentPage, newDoc.pageCount - 1)
    }

    private func createNewDocument(pages indices: [Int], title: String) {
        guard let pdf = pdfDoc else { return }
        let newDoc = PDFDocument()
        for idx in indices.sorted() where idx < pdf.pageCount {
            if let p = pdf.page(at: idx)?.copy() as? PDFPage {
                newDoc.insert(p, at: newDoc.pageCount)
            }
        }
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(title).pdf")
        newDoc.write(to: fileURL)
        let entity = DocumentEntity(context: ctx)
        entity.id = UUID()
        entity.title = title
        entity.creationDate = Date()
        entity.url = fileURL.path
        entity.thumbnail = PDFService.generateThumbnail(from: fileURL)
        try? ctx.save()
    }

    private func saveModified(_ pdf: PDFDocument) {
        guard let path = document.url else { return }
        let url = URL(fileURLWithPath: path)
        pdf.write(to: url)
        document.thumbnail = PDFService.generateThumbnail(from: url)
        try? ctx.save()
    }
}
