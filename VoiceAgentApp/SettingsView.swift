import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var activeTab = 0
    
    // User settings
    @State private var name = ""
    @State private var email = "iammap26@gmail.com"
    @State private var bio = ""
    @State private var favoriteMusic = ""
    @State private var favoriteMovies = ""
    
    // Contacts
    @State private var contacts: [Contact] = []
    @State private var showingAddContact = false
    @State private var editingContact: Contact? = nil
    
    // UI States
    @State private var isSaving = false
    @State private var showingSaveSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom tab selector
                    HStack(spacing: 0) {
                        TabButton(title: "Personalization", isSelected: activeTab == 0) {
                            activeTab = 0
                        }
                        TabButton(title: "Contacts", isSelected: activeTab == 1) {
                            activeTab = 1
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Tab content
                    TabView(selection: $activeTab) {
                        personalizationView
                            .tag(0)
                        
                        contactsView
                            .tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.15),
                        Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.1),
                        Color.clear,
                        Color(red: 1.0, green: 0.3, blue: 0.5).opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadSettings()
            loadContacts()
        }
        .alert("Settings Saved!", isPresented: $showingSaveSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your personalization settings have been saved successfully.")
        }
    }
    
    // MARK: - Personalization View
    private var personalizationView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Profile Section
                VStack(spacing: 20) {
                    settingsField(title: "Name", text: $name, placeholder: "Your name")
                    settingsField(title: "Email", text: $email, placeholder: "your@email.com")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bio")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.leading, 4)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3),
                                                    Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.3)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                            
                            TextEditor(text: $bio)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .padding(12)
                        }
                        .frame(height: 100)
                    }
                }
                
                // Preferences Section
                VStack(spacing: 20) {
                    Text("Preferences")
                        .font(.headline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.2, blue: 0.8),
                                    Color(red: 0.2, green: 0.6, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    settingsField(title: "Favorite Music Genre", text: $favoriteMusic, placeholder: "Rock, Jazz, Pop...")
                    settingsField(title: "Favorite Movie Category", text: $favoriteMovies, placeholder: "Action, Comedy, Drama...")
                }
                
                // Save Button
                Button(action: saveSettings) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.6, blue: 1.0),
                                        Color(red: 0.4, green: 0.2, blue: 0.8),
                                        Color(red: 1.0, green: 0.3, blue: 0.5)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text("Save Settings")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 50)
                }
                .disabled(isSaving)
                .padding(.top, 10)
            }
            .padding()
        }
    }
    
    // MARK: - Contacts View
    private var contactsView: some View {
        VStack {
            // Add Contact Button
            Button(action: { showingAddContact = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.6, blue: 1.0),
                                    Color(red: 0.4, green: 0.2, blue: 0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Add Contact")
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .padding()
            
            // Contacts List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(contacts) { contact in
                        ContactRow(contact: contact) {
                            editingContact = contact
                        } onDelete: {
                            deleteContact(contact)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingAddContact) {
            AddContactView { name, email, nickname in
                addContact(name: name, email: email, nickname: nickname)
            }
        }
        .sheet(item: $editingContact) { contact in
            EditContactView(contact: contact) { updatedContact in
                updateContact(updatedContact)
            }
        }
    }
    
    // MARK: - Helper Views
    private func settingsField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.leading, 4)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3),
                                        Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.3)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                TextField(placeholder, text: text)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
            }
            .frame(height: 50)
        }
    }
    
    // MARK: - Actions
    private func loadSettings() {
        // Load from Convex
        Task {
            guard let url = URL(string: "https://quick-ermine-34.convex.cloud/api/query") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "path": "settings:get",
                "args": ["userId": "default_user"]
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (data, _) = try await URLSession.shared.data(for: request)
                
                print("Load response: \(String(data: data, encoding: .utf8) ?? "nil")")
                
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let value = json["value"] as? [String: Any] {
                    await MainActor.run {
                        self.name = value["name"] as? String ?? ""
                        self.email = value["email"] as? String ?? "iammap26@gmail.com"
                        self.bio = value["bio"] as? String ?? ""
                        self.favoriteMusic = value["favoriteMusic"] as? String ?? ""
                        self.favoriteMovies = value["favoriteMovies"] as? String ?? ""
                        print("Loaded settings - Name: \(self.name), Email: \(self.email)")
                    }
                } else {
                    print("No settings found for user")
                }
            } catch {
                print("Failed to load settings: \(error)")
            }
        }
    }
    
    private func saveSettings() {
        isSaving = true
        
        Task {
            guard let url = URL(string: "https://quick-ermine-34.convex.cloud/api/mutation") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "path": "settings:save",
                "args": [
                    "userId": "default_user",
                    "name": name,
                    "email": email,
                    "bio": bio.isEmpty ? nil : bio,
                    "favoriteMusic": favoriteMusic.isEmpty ? nil : favoriteMusic,
                    "favoriteMovies": favoriteMovies.isEmpty ? nil : favoriteMovies
                ].compactMapValues { $0 }
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (data, response) = try await URLSession.shared.data(for: request)
                
                print("Save response: \(String(data: data, encoding: .utf8) ?? "nil")")
                
                await MainActor.run {
                    isSaving = false
                    showingSaveSuccess = true
                }
            } catch {
                print("Failed to save settings: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
    
    private func loadContacts() {
        Task {
            guard let url = URL(string: "https://quick-ermine-34.convex.cloud/api/query") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "path": "settings:getContacts",
                "args": ["userId": "default_user"]
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (data, _) = try await URLSession.shared.data(for: request)
                
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let value = json["value"] as? [[String: Any]] {
                    let loadedContacts = value.compactMap { contactData -> Contact? in
                        guard let id = contactData["_id"] as? String,
                              let name = contactData["name"] as? String,
                              let email = contactData["email"] as? String else { return nil }
                        
                        return Contact(
                            id: id,
                            name: name,
                            email: email,
                            nickname: contactData["nickname"] as? String
                        )
                    }
                    
                    await MainActor.run {
                        self.contacts = loadedContacts
                    }
                }
            } catch {
                print("Failed to load contacts: \(error)")
            }
        }
    }
    
    private func addContact(name: String, email: String, nickname: String?) {
        Task {
            guard let url = URL(string: "https://quick-ermine-34.convex.cloud/api/mutation") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "path": "settings:addContact",
                "args": [
                    "userId": "default_user",
                    "name": name,
                    "email": email,
                    "nickname": nickname
                ].compactMapValues { $0 }
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (_, _) = try await URLSession.shared.data(for: request)
                
                await MainActor.run {
                    showingAddContact = false
                    loadContacts()
                }
            } catch {
                print("Failed to add contact: \(error)")
            }
        }
    }
    
    private func updateContact(_ contact: Contact) {
        // Implementation for updating contact
        loadContacts()
    }
    
    private func deleteContact(_ contact: Contact) {
        Task {
            guard let url = URL(string: "https://quick-ermine-34.convex.cloud/api/mutation") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "path": "settings:deleteContact",
                "args": ["id": contact.id]
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (_, _) = try await URLSession.shared.data(for: request)
                
                await MainActor.run {
                    loadContacts()
                }
            } catch {
                print("Failed to delete contact: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                
                Rectangle()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.6, blue: 1.0),
                                Color(red: 0.4, green: 0.2, blue: 0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ContactRow: View {
    let contact: Contact
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let nickname = contact.nickname {
                        Text("(\(nickname))")
                            .font(.caption)
                            .foregroundColor(.purple.opacity(0.8))
                    }
                }
                
                Text(contact.email)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue.opacity(0.8))
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct AddContactView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var nickname = ""
    
    let onSave: (String, String, String?) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Name", text: $name)
                        .textFieldStyle(CustomTextFieldStyle())
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Nickname (Optional)", text: $nickname)
                        .textFieldStyle(CustomTextFieldStyle())
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(name, email, nickname.isEmpty ? nil : nickname)
                    }
                    .foregroundColor(.blue)
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct EditContactView: View {
    @Environment(\.dismiss) var dismiss
    let contact: Contact
    @State private var name: String
    @State private var email: String
    @State private var nickname: String
    
    let onSave: (Contact) -> Void
    
    init(contact: Contact, onSave: @escaping (Contact) -> Void) {
        self.contact = contact
        self.onSave = onSave
        _name = State(initialValue: contact.name)
        _email = State(initialValue: contact.email)
        _nickname = State(initialValue: contact.nickname ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Name", text: $name)
                        .textFieldStyle(CustomTextFieldStyle())
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Nickname (Optional)", text: $nickname)
                        .textFieldStyle(CustomTextFieldStyle())
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedContact = contact
                        updatedContact.name = name
                        updatedContact.email = email
                        updatedContact.nickname = nickname.isEmpty ? nil : nickname
                        onSave(updatedContact)
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.3),
                                Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.3)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
            .foregroundColor(.white)
    }
}

// MARK: - Models
struct Contact: Identifiable {
    var id: String
    var name: String
    var email: String
    var nickname: String?
}