import SwiftUI
import UIKit

/// 종이 위에서 직접 입력합니다. UITextView의 조합 입력과 커서 선택을 유지합니다.
struct InlinePageTextEditor: UIViewRepresentable {
    let object: PageObject
    let update: ((inout PageObject) -> Void) -> Void
    let endEditing: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.isScrollEnabled = false
        view.delegate = context.coordinator
        view.accessibilityLabel = "페이지 텍스트 입력"
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        keyboardToolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "완료", style: .done, target: context.coordinator,
                            action: #selector(Coordinator.finishEditing))
        ]
        view.inputAccessoryView = keyboardToolbar
        context.coordinator.textView = view
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        // 한글 조합 중에는 외부 갱신으로 marked text와 커서를 교체하지 않습니다.
        if view.markedTextRange == nil {
            if view.text != object.text {
                let selection = view.selectedRange
                view.text = object.text
                let length = (object.text as NSString).length
                let location = min(selection.location, length)
                view.selectedRange = NSRange(location: location, length: min(selection.length, length - location))
            }
            view.font = .systemFont(ofSize: object.fontSize)
            view.textColor = UIColor(object.color.swiftUIColor)
        }
        if !view.isFirstResponder {
            DispatchQueue.main.async { [weak view, weak coordinator = context.coordinator] in
                guard let view, let coordinator, coordinator.active, view.window != nil else { return }
                view.becomeFirstResponder()
            }
        }
    }

    static func dismantleUIView(_ view: UITextView, coordinator: Coordinator) {
        coordinator.active = false
        view.delegate = nil
        view.resignFirstResponder()
    }

    @MainActor final class Coordinator: NSObject, UITextViewDelegate {
        var parent: InlinePageTextEditor
        weak var textView: UITextView?
        var active = true
        init(parent: InlinePageTextEditor) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            let text = textView.text ?? ""
            parent.update { $0.text = text }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            active = false
            textViewDidChange(textView)
            parent.endEditing()
        }

        @objc func finishEditing() { textView?.resignFirstResponder() }
    }
}
