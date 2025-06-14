import SwiftUI
import CoreData
import PDFKit
import UIKit

struct DocumentListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DocumentEntity.creationDate, ascending: false)],
        animation: .default
    ) private var docs: FetchedResults<DocumentEntity>

    @State private var showingMerge = false
    @State private var baseDoc: DocumentEntity?
    @State private var showingGenerator = false
    @State private var showHelp = false    // для показа экрана помощи

    var body: some View {
        NavigationView {
            List {
                ForEach(docs) { doc in
                    NavigationLink(destination: PDFReaderView(document: doc)) {
                        HStack {
                            if let data = doc.thumbnail,
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(5)
                            }
                            VStack(alignment: .leading) {
                                Text(doc.title ?? "")
                                Text("pdf")
                                if let date = doc.creationDate {
                                    Text(date, style: .date)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            saveToFiles(doc)
                        } label: {
                            Label("Сохранить", systemImage: "square.and.arrow.down")
                        }
                        .tint(.orange)

                        Button {
                            baseDoc = doc
                            showingMerge = true
                        } label: {
                            Label("Объединить", systemImage: "rectangle.3.offgrid")
                        }
                        .tint(.green)

                        Button {
                            share(doc)
                        } label: {
                            Label("Поделиться", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            try? DataService.shared.delete(doc)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            saveToFiles(doc)
                        } label: {
                            Label("Сохранить", systemImage: "square.and.arrow.down")
                        }
                        .tint(.orange)

                        Button {
                            baseDoc = doc
                            showingMerge = true
                        } label: {
                            Label("Объединить", systemImage: "rectangle.3.offgrid")
                        }
                        .tint(.green)

                        Button {
                            share(doc)
                        } label: {
                            Label("Поделиться", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)

                        Button(role: .destructive) {
                            try? DataService.shared.delete(doc)
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Документы")
            .toolbar {
                // Левая кнопка: показать справку
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showHelp = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
                // Правая кнопка: создать PDF
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingGenerator = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        // Генератор
        .sheet(isPresented: $showingGenerator) {
            PDFGeneratorView()
                .environment(\.managedObjectContext,
                              PersistenceController.shared.container.viewContext)
        }
        // Объединение
        .sheet(item: $baseDoc) { doc in
            MergeView(base: doc)
        }
        // Справка / welcome
        .sheet(isPresented: $showHelp) {
            WelcomeFirstView(isPresented: $showHelp)
        }
    }

    // MARK: – Методы

    private func share(_ doc: DocumentEntity) {
        guard let path = doc.url else { return }
        let url = URL(fileURLWithPath: path)
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(vc)
    }

    private func saveToFiles(_ doc: DocumentEntity) {
        guard let path = doc.url else { return }
        let url = URL(fileURLWithPath: path)
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            picker.modalPresentationStyle = .formSheet
            root.present(picker, animated: true)
        }
    }

    private func present(_ controller: UIViewController) {
        if let scene = UIApplication.shared.connectedScenes
                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(controller, animated: true)
        }
    }
}
