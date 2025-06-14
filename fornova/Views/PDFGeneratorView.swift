import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import PDFKit

struct PDFGeneratorView: View {
    @Environment(\.managedObjectContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var images: [UIImage] = []
    @State private var title = ""

    @State private var showingPhotoPicker = false
    @State private var showingDocPicker = false

    var body: some View {
        NavigationView {
            Form {
                // Просмотр уже добавленных изображений
                Section("Действие") {
                    if images.isEmpty {
                        Text("Ничего не выбрано")
                            .foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(images, id: \.self) { img in
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 80)
                                        .cornerRadius(5)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Добавить фото")
                        }
                    }
                }

                Section {
                    Button {
                        showingDocPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                            Text("Добавить файлы")
                        }
                    }
                }

                Section("Название") {
                    TextField("Введите", text: $title)
                }

                
                Section {
                    Button("Создать") {
                        Task { await generatePDF() }
                    }
                    .disabled(images.isEmpty || title.isEmpty)
                }
            }
            .navigationTitle("Генерация PDF")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(images: $images)
            }
            
            .sheet(isPresented: $showingDocPicker) {
                DocumentPicker(images: $images)
            }
        }
    }

    @MainActor
    private func generatePDF() async {
        do {
            let url = try PDFService.createPDF(from: images, title: title)
            let thumb = PDFService.generateThumbnail(from: url)
            let doc = DocumentEntity(context: ctx)
            doc.id = UUID()
            doc.title = title
            doc.creationDate = Date()
            doc.url = url.path
            doc.thumbnail = thumb
            try ctx.save()
            dismiss()
        } catch {
            print("Ошибка генерации: \(error)")
        }
    }
}
