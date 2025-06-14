import SwiftUI
import PDFKit

struct PagePickerView: View {
    let pdfDocument: PDFDocument
    let onDeleteMultiple: ([Int]) -> Void
    let onRotateMultiple: ([Int]) -> Void
    let onMove: (IndexSet, Int) -> Void
    let onCreate: ([Int], String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isSelecting = false
    @State private var selected: Set<Int> = []
    @State private var showingCreate = false
    @State private var newTitle = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(0..<pdfDocument.pageCount, id: \.self) { idx in
                    HStack {
                        if isSelecting {
                            Image(systemName: selected.contains(idx) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(.blue)
                                .onTapGesture { toggle(idx) }
                        }
                        Text("\(idx+1)")
                            .frame(width: 24)
                        if let page = pdfDocument.page(at: idx) {
                            Image(uiImage: page.thumbnail(of: CGSize(width: 80, height: 80), for: .cropBox))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                        }
                        Spacer()
                    }
                    // свайп вправо — поворот + сохранить страницу
                    .swipeActions(edge: .leading) {
                        Button {
                            onRotateMultiple([idx])
                        } label: { Label("Повернуть", systemImage: "rotate.right") }
                        .tint(.purple)

                        Button {
                            selected = [idx]
                            showingCreate = true
                        } label: { Label("Сохранить", systemImage: "square.and.arrow.down") }
                        .tint(.orange)
                    }
                    // свайп влево — удалить страницу
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDeleteMultiple([idx])
                        } label: { Label("Удалить", systemImage: "trash") }
                    }
                    // долгий тап — контекстное меню
                    .contextMenu {
                        Button { onRotateMultiple([idx]) } label: {
                            Label("Повернуть", systemImage: "rotate.right")
                        }
                        Button {
                            selected = [idx]
                            showingCreate = true
                        } label: {
                            Label("Сохранить", systemImage: "square.and.arrow.down")
                        }
                        Button(role: .destructive) {
                            onDeleteMultiple([idx])
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
                // Перетаскивание
                .onMove { offsets, dest in
                    onMove(offsets, dest)
                }
                .moveDisabled(!isSelecting)
            }
            .environment(\.editMode, .constant(isSelecting ? .active : .inactive))
            .navigationTitle("Страницы")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isSelecting ? "Отменить" : "Выбрать") {
                        isSelecting.toggle()
                        if !isSelecting { selected.removeAll() }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isSelecting ? "Готово" : "Закрыть") {
                        if isSelecting {
                            isSelecting = false
                            selected.removeAll()
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isSelecting {
                    HStack {
                        Button("Создать") { showingCreate = true }
                        Spacer()
                        Button("Повернуть") { onRotateMultiple(Array(selected)) }
                        Spacer()
                        Button(role: .destructive) { onDeleteMultiple(Array(selected)) } label: {
                            Text("Удалить")
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground).opacity(0.9))
                }
            }
            .sheet(isPresented: $showingCreate) {
                NavigationView {
                    Form {
                        Section("Название") {
                            TextField("Введите", text: $newTitle)
                        }
                        Section {
                            Button("Создать") {
                                onCreate(Array(selected), newTitle)
                                dismiss()
                            }
                            .disabled(newTitle.isEmpty || selected.isEmpty)
                        }
                    }
                    .navigationTitle("Генерация PDF")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Отмена") { showingCreate = false }
                        }
                    }
                }
            }
        }
    }

    private func toggle(_ idx: Int) {
        if selected.contains(idx) { selected.remove(idx) } else { selected.insert(idx) }
    }
}
