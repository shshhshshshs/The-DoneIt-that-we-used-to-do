import SwiftUI
import PencilKit

struct LayeredEditorView: View {
    @State private var isDrawing = false
    @State private var text: String = ""
    @State private var canvasView = PKCanvasView()

    var body: some View {
        ZStack {
            CanvasRepresentable(canvasView: $canvasView)
                .allowsHitTesting(isDrawing)
            TextEditor(text: $text)
                .opacity(isDrawing ? 0 : 1)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isDrawing.toggle() }) {
                    Image(systemName: isDrawing ? "character.cursor.ibeam" : "pencil.tip")
                }
            }
        }
    }
}

struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .pencilOnly
        canvasView.allowsFingerDrawing = false
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
