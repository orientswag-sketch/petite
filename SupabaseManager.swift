import Foundation
// MARK: - Supabase Manager
final class SupabaseManager {
    
    static let shared = SupabaseManager()
    
    private let baseURL = URL(
        string: "https://urqnzvqmqrxwtxcgwphs.supabase.co"
    )!
    
    // Ta clé publishable Supabase actuelle
    private let apiKey = "sb_publishable_lP6L-bx38KGIygQikoyODA_b8v_yv3D"
    
    private init() {}
    
    // MARK: - Requête authentifiée
    
    private func authenticatedRequest(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) throws -> URLRequest {
        
        guard let token = UserDefaults.standard.string(
            forKey: "supabase_access_token"
        ),
              !token.isEmpty else {
            throw SupabaseError.server(
                "Tu n'es pas connecté."
            )
        }
        
        guard let url = URL(
            string: "\(baseURL.absoluteString)\(path)"
        ) else {
            throw SupabaseError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = method
        
        request.setValue(
            apiKey,
            forHTTPHeaderField: "apikey"
        )
        
        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )
        
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        request.httpBody = body
        
        return request
    }
    
    // MARK: - Inscription
    
    func signUp(
        email: String,
        password: String
    ) async throws {
        
        let url = URL(
            string:
                "\(baseURL.absoluteString)/auth/v1/signup"
        )!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        
        request.setValue(
            apiKey,
            forHTTPHeaderField: "apikey"
        )
        
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(
            withJSONObject: body
        )
        
        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            httpResponse.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: data)
            )
        }
        
        let result =
        try? JSONDecoder().decode(
            AuthResponse.self,
            from: data
        )
        
        if let userId = result?.user?.id {
            UserDefaults.standard.set(
                userId,
                forKey: "supabase_user_id"
            )
        }
        
        if let accessToken = result?.access_token,
           !accessToken.isEmpty {
            
            UserDefaults.standard.set(
                accessToken,
                forKey: "supabase_access_token"
            )
        }
    }
    
    // MARK: - Connexion
    
    func signIn(
        email: String,
        password: String
    ) async throws {
        
        let url = URL(
            string:
                "\(baseURL.absoluteString)/auth/v1/token?grant_type=password"
        )!
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        
        request.setValue(
            apiKey,
            forHTTPHeaderField: "apikey"
        )
        
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(
            withJSONObject: body
        )
        
        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            httpResponse.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: data)
            )
        }
        
        let result =
        try JSONDecoder().decode(
            AuthResponse.self,
            from: data
        )
        
        if let accessToken = result.access_token,
           !accessToken.isEmpty {
            
            UserDefaults.standard.set(
                accessToken,
                forKey: "supabase_access_token"
            )
        }
        
        if let userId = result.user?.id {
            UserDefaults.standard.set(
                userId,
                forKey: "supabase_user_id"
            )
        }
    }
    
    // MARK: - Utilisateur actuel
    
    func fetchCurrentUserId() async throws -> String {
        
        if let savedUserId =
            UserDefaults.standard.string(
                forKey: "supabase_user_id"
            ),
           !savedUserId.isEmpty {
            
            return savedUserId
        }
        
        let request = try authenticatedRequest(
            path: "/auth/v1/user"
        )
        
        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            httpResponse.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: data)
            )
        }
        
        let user =
        try JSONDecoder().decode(
            SupabaseUser.self,
            from: data
        )
        
        UserDefaults.standard.set(
            user.id,
            forKey: "supabase_user_id"
        )
        
        return user.id
    }
    
    // MARK: - Mon équipe
    
    func fetchMyWorkspace()
    async throws
    -> (name: String, inviteCode: String)? {
        
        let userId = try await fetchCurrentUserId()
        
        let path =
        "/rest/v1/workspace_members" +
        "?user_id=eq.\(userId)" +
        "&select=workspace_id"
        
        let request = try authenticatedRequest(
            path: path
        )
        
        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            httpResponse.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: data)
            )
        }
        
        struct Membership: Decodable {
            let workspace_id: String
        }
        
        let memberships =
        try JSONDecoder().decode(
            [Membership].self,
            from: data
        )
        
        guard let workspaceId =
                memberships.first?.workspace_id else {
            return nil
        }
        
        let workspacePath =
        "/rest/v1/workspaces" +
        "?id=eq.\(workspaceId)" +
        "&select=name,invite_code" +
        "&limit=1"
        
        let workspaceRequest =
        try authenticatedRequest(
            path: workspacePath
        )
        
        let (workspaceData, workspaceResponse) =
        try await URLSession.shared.data(
            for: workspaceRequest
        )
        
        guard let workspaceHTTP =
                workspaceResponse as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            workspaceHTTP.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: workspaceData)
            )
        }
        
        struct Workspace: Decodable {
            let name: String
            let invite_code: String
        }
        
        let workspaces =
        try JSONDecoder().decode(
            [Workspace].self,
            from: workspaceData
        )
        
        guard let workspace = workspaces.first else {
            return nil
        }
        
        return (
            name: workspace.name,
            inviteCode: workspace.invite_code
        )
    }
    
    // MARK: - ID de mon équipe
    
    func fetchMyWorkspaceId() async throws -> String? {
        
        let userId = try await fetchCurrentUserId()
        
        let path =
        "/rest/v1/workspace_members" +
        "?user_id=eq.\(userId)" +
        "&select=workspace_id" +
        "&limit=1"
        
        let request = try authenticatedRequest(
            path: path
        )
        
        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            httpResponse.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: data)
            )
        }
        
        struct WorkspaceMember: Decodable {
            let workspace_id: String
        }
        
        let members =
        try JSONDecoder().decode(
            [WorkspaceMember].self,
            from: data
        )
        
        return members.first?.workspace_id
    }
    
    // MARK: - Nombre de membres
    
    func fetchMemberCount() async throws -> Int {
        
        guard let workspaceId =
                try await fetchMyWorkspaceId() else {
            return 0
        }
        
        let path =
        "/rest/v1/workspace_members" +
        "?workspace_id=eq.\(workspaceId)" +
        "&select=user_id"
        
        let request = try authenticatedRequest(
            path: path
        )
        
        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            httpResponse.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: data)
            )
        }
        
        struct Member: Decodable {
            let user_id: String
        }
        
        let members =
        try JSONDecoder().decode(
            [Member].self,
            from: data
        )
        
        return members.count
    }
    
    // MARK: - Membres
    
    func fetchMembers()
    async throws
    -> [(userId: String, displayName: String)] {
        
        guard let workspaceId =
                try await fetchMyWorkspaceId() else {
            return []
        }
        
        let path =
        "/rest/v1/workspace_members" +
        "?workspace_id=eq.\(workspaceId)" +
        "&select=user_id,display_name"
        
        let request = try authenticatedRequest(
            path: path
        )
        
        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            httpResponse.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: data)
            )
        }
        
        struct Member: Decodable {
            let user_id: String
            let display_name: String?
        }
        
        let decoded =
        try JSONDecoder().decode(
            [Member].self,
            from: data
        )
        
        return decoded.map {
            (
                userId: $0.user_id,
                displayName: $0.display_name ?? ""
            )
        }
    }
    
    // MARK: - Rejoindre une équipe
    
    func joinWorkspace(
        inviteCode: String,
        displayName: String
    ) async throws {
        
        let userId = try await fetchCurrentUserId()
        
        // Cherche le workspace correspondant au code
        let encodedCode =
        inviteCode.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? inviteCode
        
        let workspacePath =
        "/rest/v1/workspaces" +
        "?invite_code=eq.\(encodedCode)" +
        "&select=id,name,invite_code" +
        "&limit=1"
        
        let workspaceRequest =
        try authenticatedRequest(
            path: workspacePath
        )
        
        let (workspaceData, workspaceResponse) =
        try await URLSession.shared.data(
            for: workspaceRequest
        )
        
        guard let workspaceHTTP =
                workspaceResponse as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            workspaceHTTP.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: workspaceData)
            )
        }
        
        struct Workspace: Decodable {
            let id: String
            let name: String
            let invite_code: String
        }
        
        let workspaces =
        try JSONDecoder().decode(
            [Workspace].self,
            from: workspaceData
        )
        
        guard let workspace = workspaces.first else {
            throw SupabaseError.server(
                "Code d'invitation incorrect."
            )
        }
        
        // Vérifie si l'utilisateur est déjà membre
        let existingPath =
        "/rest/v1/workspace_members" +
        "?workspace_id=eq.\(workspace.id)" +
        "&user_id=eq.\(userId)" +
        "&select=user_id" +
        "&limit=1"
        
        let existingRequest =
        try authenticatedRequest(
            path: existingPath
        )
        
        let (existingData, existingResponse) =
        try await URLSession.shared.data(
            for: existingRequest
        )
        
        guard let existingHTTP =
                existingResponse as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            existingHTTP.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: existingData)
            )
        }
        
        struct ExistingMember: Decodable {
            let user_id: String
        }
        
        let existingMembers =
        try JSONDecoder().decode(
            [ExistingMember].self,
            from: existingData
        )
        
        if !existingMembers.isEmpty {
            throw SupabaseError.server(
                "Tu fais déjà partie de cette équipe."
            )
        }
        
        // Ajoute le membre
        struct NewMember: Encodable {
            let workspace_id: String
            let user_id: String
            let display_name: String
        }
        
        let member = NewMember(
            workspace_id: workspace.id,
            user_id: userId,
            display_name: displayName
        )
        
        let body =
        try JSONEncoder().encode(member)
        
        let insertRequest =
        try authenticatedRequest(
            path: "/rest/v1/workspace_members",
            method: "POST",
            body: body
        )
        
        let (insertData, insertResponse) =
        try await URLSession.shared.data(
            for: insertRequest
        )
        
        guard let insertHTTP =
                insertResponse as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            insertHTTP.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: insertData)
            )
        }
    }
    
    // MARK: - PÉPITE — Photo
    
    func uploadPepiteImage(
        imageData: Data,
        itemId: UUID,
        workspaceId: String
    ) async throws -> String {
        
        let filePath = "\(workspaceId)/\(itemId.uuidString).jpg"
        
        let urlString = "\(baseURL.absoluteString)/storage/v1/object/pepite-images/\(filePath)"
        
        guard let url = URL(string: urlString) else {
            throw SupabaseError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue(
            apiKey,
            forHTTPHeaderField: "apikey"
        )
        
        guard let token = UserDefaults.standard.string(
            forKey: "supabase_access_token"
        ),
              !token.isEmpty else {
            throw SupabaseError.server(
                "Session Supabase introuvable."
            )
        }
        
        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )
        
        request.setValue(
            "image/jpeg",
            forHTTPHeaderField: "Content-Type"
        )
        
        request.setValue(
            "true",
            forHTTPHeaderField: "x-upsert"
        )
        
        request.httpBody = imageData
        
        let (data, response) = try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SupabaseError.server(
                supabaseMessage(from: data)
            )
        }
        
        let publicURL = "\(baseURL.absoluteString)/storage/v1/object/public/pepite-images/\(filePath)"
        
        return publicURL
    }
    
    // MARK: - PÉPITE — Créer un article
    
    func createPepiteItem(
        id: UUID,
        workspaceId: String,
        name: String,
        brand: String,
        category: String,
        condition: String,
        buyPrice: Double,
        salePrice: Double,
        soldPrice: Double?,
        imageURL: String?,
        addedDate: Date
    ) async throws {
        
        struct PepiteItemPayload: Encodable {
            let id: UUID
            let workspace_id: String
            let created_by: String
            let name: String
            let brand: String
            let category: String
            let condition: String
            let buy_price: Double
            let sale_price: Double
            let sold_price: Double?
            let image_url: String?
            let added_date: String
        }
        
        let userId =
        try await fetchCurrentUserId()
        
        let formatter =
        ISO8601DateFormatter()
        
        let payload = PepiteItemPayload(
            id: id,
            workspace_id: workspaceId,
            created_by: userId,
            name: name,
            brand: brand,
            category: category,
            condition: condition,
            buy_price: buyPrice,
            sale_price: salePrice,
            sold_price: soldPrice,
            image_url: imageURL,
            added_date: formatter.string(
                from: addedDate
            )
        )
        
        let body =
        try JSONEncoder().encode(payload)
        
        let request =
        try authenticatedRequest(
            path: "/rest/v1/pepite_items",
            method: "POST",
            body: body
        )
        
        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            httpResponse.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: data)
            )
        }
    }
    
    // MARK: - PÉPITE — Récupérer les articles
    
    func fetchPepiteItems()
    async throws
    -> [[String: Any]] {
        
        guard let workspaceId =
                try await fetchMyWorkspaceId() else {
            return []
        }
        
        let path =
        "/rest/v1/pepite_items" +
        "?workspace_id=eq.\(workspaceId)" +
        "&select=*" +
        "&order=added_date.desc"
        
        let request =
        try authenticatedRequest(
            path: path
        )
        
        let (data, response) =
        try await URLSession.shared.data(
            for: request
        )
        
        guard let httpResponse =
                response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        guard (200...299).contains(
            httpResponse.statusCode
        ) else {
            throw SupabaseError.server(
                supabaseMessage(from: data)
            )
        }
        
        guard let json =
                try JSONSerialization.jsonObject(
                    with: data
                ) as? [[String: Any]] else {
            throw SupabaseError.server(
                "Format des articles invalide."
            )
        }
        
        return json
    }
    
    // MARK: - Erreur Supabase
    
    private func supabaseMessage(
        from data: Data
    ) -> String {
        
        if let json =
            try? JSONSerialization.jsonObject(
                with: data
            ) as? [String: Any] {
            
            if let message =
                json["message"] as? String,
               !message.isEmpty {
                return message
            }
            
            if let error =
                json["error"] as? String,
               !error.isEmpty {
                return error
            }
            
            if let details =
                json["details"] as? String,
               !details.isEmpty {
                return details
            }
        }
        
        if let text =
            String(data: data, encoding: .utf8),
           !text.isEmpty {
            return text
        }
        
        return "Une erreur est survenue avec Supabase."
    }
}
// MARK: - Structures Auth
private struct AuthResponse: Decodable {
    let access_token: String?
    let user: SupabaseUser?
}
private struct SupabaseUser: Decodable {
    let id: String
}
// MARK: - Erreurs
enum SupabaseError: LocalizedError {
    case invalidResponse
    case server(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Réponse invalide du serveur."
            
        case .server(let message):
            return message
        }
    }
}
