import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    let recipient: String
    let subject: String
    let body: String
    let attachmentData: Data?
    let attachmentName: String?
    let attachmentMimeType: String?
    var result: (Result<MFMailComposeResult, Error>) -> Void

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView

        init(_ parent: MailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result(.failure(error))
            } else {
                parent.result(.success(result))
            }
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        
        if let data = attachmentData, let name = attachmentName, let mime = attachmentMimeType {
            vc.addAttachmentData(data, mimeType: mime, fileName: name)
        }
        
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    static func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
}
