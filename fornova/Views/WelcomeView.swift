import SwiftUI

struct WelcomeView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Text("Добро пожаловать")
                .font(.largeTitle)
                .bold()

            VStack(alignment: .leading, spacing: 15) {
                FeatureRow(
                    icon: "photo.on.rectangle",
                    title: "Генерация PDF",
                    description: "Создавайте PDF из изображений и фото."
                )
                FeatureRow(
                    icon: "doc.on.doc.fill",
                    title: "Объединение",
                    description: "Сливайте несколько PDF в один."
                )
                FeatureRow(
                    icon: "rotate.right",
                    title: "Ротация",
                    description: "Поворачивайте отдельные страницы."
                )
                FeatureRow(
                    icon: "mic.fill",
                    title: "Диктовка",
                    description: "Добавляйте страницы с надиктованным текстом."
                )
            }
            .padding(.horizontal, 40)

            Spacer()

            Button(action: {
                isPresented = false
            }) {
                Text("Начать")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.cornerRadius(10))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 50)

            Spacer()
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
