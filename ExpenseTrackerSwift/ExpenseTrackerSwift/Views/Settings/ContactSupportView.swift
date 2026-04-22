import SwiftUI
import PhotosUI
import MessageUI

struct ContactSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showingMailView = false
    @State private var showingMailError = false
    @State private var mailErrorMsg = ""
    
    private let supportEmail = "ravencsolis@gmail.com"
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "How can we help?"))
                        .font(.headline)
                    
                    Text(String(localized: "If you're experiencing an issue or have a suggestion, please send us an email. Attaching a screenshot helps us understand the problem better."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section(String(localized: "Attachment")) {
                VStack(alignment: .center, spacing: 16) {
                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(radius: 5)
                        
                        Button(role: .destructive) {
                            withAnimation {
                                selectedItem = nil
                                selectedImageData = nil
                            }
                        } label: {
                            Label(String(localized: "Remove Photo"), systemImage: "trash")
                        }
                    } else {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.accent)
                                
                                Text(String(localized: "Attach a Photo or Screenshot"))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    .foregroundStyle(.secondary.opacity(0.3))
                            )
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Button {
                    if MailView.canSendMail() {
                        showingMailView = true
                    } else {
                        mailErrorMsg = String(localized: "Mail services are not available on this device. Please email us directly at \(supportEmail)")
                        showingMailError = true
                    }
                } label: {
                    HStack {
                        Spacer()
                        Label(String(localized: "Send Email"), systemImage: "paperplane.fill")
                            .font(.headline)
                        Spacer()
                    }
                }
                .listRowBackground(Color.accentColor)
                .foregroundStyle(.white)
            }
        }
        .navigationTitle(String(localized: "Contact Support"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMailView) {
            MailView(
                recipient: supportEmail,
                subject: String(localized: "ExpenseMe Support Request"),
                body: supportEmailBody,
                attachmentData: selectedImageData,
                attachmentName: "screenshot.jpg",
                attachmentMimeType: "image/jpeg"
            ) { result in
                switch result {
                case .success(let mailResult):
                    if mailResult == .sent {
                        dismiss()
                    }
                case .failure(let error):
                    print("Mail error: \(error.localizedDescription)")
                }
            }
        }
        .alert(String(localized: "Cannot Send Mail"), isPresented: $showingMailError) {
            Button(String(localized: "Copy Email")) {
                UIPasteboard.general.string = supportEmail
            }
            Button(String(localized: "OK"), role: .cancel) { }
        } message: {
            Text(mailErrorMsg)
        }
    }
    
    private var supportEmailBody: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let device = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        return """
        
        
        --- \(String(localized: "Device Information")) ---
        \(String(localized: "App Version")): \(version) (\(build))
        \(String(localized: "Device")): \(device)
        \(String(localized: "iOS Version")): \(systemVersion)
        ---------------------------
        """
    }
}

#Preview {
    NavigationStack {
        ContactSupportView()
    }
}
