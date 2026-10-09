import SwiftUI
import PhotosUI
import UIKit

// ============================================================
// PÉPITE : fichier unique à coller dans ContentView
// ============================================================

// MARK: - Couleurs et styles

extension Color {
    static let ppCream = Color(red: 0.957, green: 0.941, blue: 0.910)
    static let ppPaper = Color(red: 0.996, green: 0.988, blue: 0.969)
    static let ppPine = Color(red: 0.125, green: 0.267, blue: 0.220)
    static let ppClay = Color(red: 0.910, green: 0.447, blue: 0.267)
    static let ppSage = Color(red: 0.882, green: 0.918, blue: 0.867)
}

struct PpPrimaryStyle: ButtonStyle {
    var color: Color = .ppPine
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PpOutlineStyle: ButtonStyle {
    var color: Color = .ppPine
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.ppPaper.opacity(configuration.isPressed ? 0.7 : 1))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func ppField() -> some View {
        self
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(Color.ppSage.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .foregroundColor(.ppPine)
    }
}

struct PpBrand: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "tag.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.ppPine)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 1) {
                Text("PÉPITE")
                    .font(.system(size: 16, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(.ppPine)
                Text("La chasse aux bonnes affaires")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct PpPriceRow: View {
    let label: String
    @Binding var text: String
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.ppPine)
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
            Text("€").foregroundColor(.gray)
        }
        .ppField()
    }
}

// MARK: - Réglages enregistrés sur l'appareil

enum PpCfg {
    static var url: String {
        (UserDefaults.standard.string(forKey: "sb_url") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
    static var key: String {
        (UserDefaults.standard.string(forKey: "sb_key") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    static var gemKey: String {
        let shared = (UserDefaults.standard.string(forKey: "pp_team_gem") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !shared.isEmpty { return shared }
        return (UserDefaults.standard.string(forKey: "gem_key") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    static var model: String {
        let m = (UserDefaults.standard.string(forKey: "gem_model") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return m.isEmpty ? "gemini-3.5-flash-lite" : m
    }
    static var who: String {
        UserDefaults.standard.string(forKey: "who") ?? ""
    }
    static var ready: Bool { !url.isEmpty && !key.isEmpty }
}

// MARK: - Modèles

struct PpAuthUser: Decodable {
    var id: String
    var email: String?
}

struct PpAuthSession: Decodable {
    var access_token: String?
    var refresh_token: String?
    var expires_in: Double?
    var user: PpAuthUser?
}

struct PpTeam: Codable {
    var id: String
    var name: String
    var invite_code: String
    var gemini_key: String?
}

struct PpMembership: Decodable {
    var team_id: String
    var teams: PpTeam?
}

struct PpItem: Identifiable, Codable {
    var id: String
    var team_id: String?
    var name: String
    var size: String?
    var condition: String?
    var asked: Double?
    var resale_low: Double?
    var resale_high: Double?
    var score: Int?
    var status: String
    var buy: Double?
    var sold: Double?
    var photo_url: String?
    var added_by: String?
    var created_at: String?
    var brand: String?
    var photos: [String]?
    var sold_at: String?
    var deleted_at: String?
}

struct PpNewItem: Encodable {
    var id: String? = nil
    var team_id: String
    var name: String
    var size: String?
    var condition: String?
    var asked: Double?
    var resale_low: Double?
    var resale_high: Double?
    var score: Int?
    var status: String
    var buy: Double?
    var photo_url: String?
    var added_by: String?
    var brand: String? = nil
    var photos: [String]? = nil
}

struct PpAnalysis: Decodable {
    var nom: String?
    var marque: String?
    var type: String?
    var couleur: String?
    var taille: String?
    var etat: String?
    var revente_bas: Double?
    var revente_haut: Double?
    var nb_annonces: Int?
    var commentaire: String?
    var source: String?
}

struct PpError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// MARK: - Supabase

enum PpAPI {
    static var uid: String {
        UserDefaults.standard.string(forKey: "pp_uid") ?? ""
    }
    
    static func errorText(_ data: Data, _ code: Int) -> String {
        if let o = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            for k in ["msg", "error_description", "message", "hint", "error"] {
                if let s = o[k] as? String, !s.isEmpty { return s }
            }
        }
        return "Erreur \(code)"
    }
    
    static func authCall(_ path: String, _ body: [String: String]) async throws -> PpAuthSession {
        guard PpCfg.ready, let url = URL(string: PpCfg.url + path) else {
            throw PpError(message: "Renseigne l'adresse et la clé du serveur (Réglages du serveur).")
        }
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.setValue(PpCfg.key, forHTTPHeaderField: "apikey")
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: r)
        if let h = resp as? HTTPURLResponse, !(200...299).contains(h.statusCode) {
            throw PpError(message: errorText(data, h.statusCode))
        }
        return try JSONDecoder().decode(PpAuthSession.self, from: data)
    }
    
    static func save(_ s: PpAuthSession) {
        let d = UserDefaults.standard
        if let a = s.access_token { d.set(a, forKey: "pp_access") }
        if let r = s.refresh_token { d.set(r, forKey: "pp_refresh") }
        d.set(Date().timeIntervalSince1970 + (s.expires_in ?? 3600), forKey: "pp_expires")
        if let u = s.user {
            d.set(u.id, forKey: "pp_uid")
            if let e = u.email { d.set(e, forKey: "pp_email") }
        }
    }
    
    static func clear() {
        let d = UserDefaults.standard
        for k in ["pp_access", "pp_refresh", "pp_expires", "pp_uid", "pp_email", "pp_team_gem",
                  "pp_cache_team", "pp_cache_items", "pp_cache_members"] {
            d.removeObject(forKey: k)
        }
    }
    
    static func token() async throws -> String {
        let d = UserDefaults.standard
        let exp = d.double(forKey: "pp_expires")
        if let t = d.string(forKey: "pp_access"), Date().timeIntervalSince1970 < exp - 60 {
            return t
        }
        guard let rt = d.string(forKey: "pp_refresh") else {
            throw PpError(message: "Session expirée. Reconnecte-toi.")
        }
        let s = try await authCall("/auth/v1/token?grant_type=refresh_token", ["refresh_token": rt])
        save(s)
        return d.string(forKey: "pp_access") ?? ""
    }
    
    @discardableResult
    static func call(_ path: String, method: String = "GET", body: Data? = nil,
                     contentType: String = "application/json", prefer: String? = nil) async throws -> Data {
        guard PpCfg.ready, let url = URL(string: PpCfg.url + path) else {
            throw PpError(message: "Réglages du serveur manquants.")
        }
        let t = try await token()
        var r = URLRequest(url: url)
        r.httpMethod = method
        r.setValue(PpCfg.key, forHTTPHeaderField: "apikey")
        r.setValue("Bearer " + t, forHTTPHeaderField: "Authorization")
        if body != nil { r.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        if let p = prefer { r.setValue(p, forHTTPHeaderField: "Prefer") }
        r.httpBody = body
        let (data, resp) = try await URLSession.shared.data(for: r)
        if let h = resp as? HTTPURLResponse, !(200...299).contains(h.statusCode) {
            throw PpError(message: errorText(data, h.statusCode))
        }
        return data
    }
    
    static func rpc(_ name: String, _ body: [String: Any]) async throws -> Data {
        let data = try JSONSerialization.data(withJSONObject: body)
        return try await call("/rest/v1/rpc/" + name, method: "POST", body: data)
    }
    
    static func fetchItems() async throws -> [PpItem] {
        let d = try await call("/rest/v1/items?select=*&order=created_at.desc")
        return try JSONDecoder().decode([PpItem].self, from: d)
    }
    
    static func uploadPhoto(_ jpeg: Data) async throws -> String {
        let file = UUID().uuidString + ".jpg"
        try await call("/storage/v1/object/photos/" + file, method: "POST", body: jpeg, contentType: "image/jpeg")
        return PpCfg.url + "/storage/v1/object/public/photos/" + file
    }
    
    static func insert(_ item: PpNewItem, ignoreDuplicates: Bool = false) async throws {
        let body = try JSONEncoder().encode(item)
        let prefer = ignoreDuplicates ? "resolution=ignore-duplicates,return=minimal" : "return=minimal"
        try await call("/rest/v1/items", method: "POST", body: body, prefer: prefer)
    }
    
    static func update(_ id: String, _ fields: [String: Any]) async throws {
        let body = try JSONSerialization.data(withJSONObject: fields)
        try await call("/rest/v1/items?id=eq." + id, method: "PATCH", body: body, prefer: "return=minimal")
    }
    
    static func delete(_ id: String) async throws {
        try await call("/rest/v1/items?id=eq." + id, method: "DELETE")
    }
}

// MARK: - Gemini (identification par photo + prix Vinted via Google Search)

enum PpGemini {
    private static func generate(parts: [[String: Any]], search: Bool) async throws -> String {
        guard !PpCfg.gemKey.isEmpty else {
            throw PpError(message: "Clé Gemini manquante : saisis-la dans l'onglet Équipe.")
        }
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(PpCfg.model):generateContent") else {
            throw PpError(message: "Nom de modèle invalide.")
        }
        var body: [String: Any] = ["contents": [["parts": parts]]]
        if search {
            body["tools"] = [["google_search": [String: Any]()]]
        } else {
            body["generationConfig"] = ["response_mime_type": "application/json"]
        }
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.timeoutInterval = 60
        r.setValue(PpCfg.gemKey, forHTTPHeaderField: "x-goog-api-key")
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: r)
        if let h = resp as? HTTPURLResponse, !(200...299).contains(h.statusCode) {
            let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let detail = ((obj?["error"] as? [String: Any])?["message"] as? String) ?? ""
            throw PpError(message: "Gemini \(h.statusCode) : \(detail.prefix(200))")
        }
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let cands = json["candidates"] as? [[String: Any]],
            let content = cands.first?["content"] as? [String: Any],
            let ps = content["parts"] as? [[String: Any]]
        else { throw PpError(message: "Réponse Gemini illisible.") }
        return ps.compactMap { $0["text"] as? String }.joined()
    }
    
    // Avec l'outil de recherche, le mode JSON n'est pas dispo : on extrait l'objet à la main
    private static func decode(_ text: String) throws -> PpAnalysis {
        guard let a = text.firstIndex(of: "{"), let b = text.lastIndex(of: "}"), a < b,
              let d = String(text[a...b]).data(using: .utf8)
        else { throw PpError(message: "Réponse Gemini illisible.") }
        return try JSONDecoder().decode(PpAnalysis.self, from: d)
    }
    
    // Relit marque / type / couleur à partir d'un nom modifié à la main (texte seul, sans photo)
    static func extraireDuNom(_ nom: String) async throws -> PpAnalysis {
        let p = "Voici le nom d'un article de seconde main : « \(nom) ». Réponds uniquement en JSON avec : marque (la marque seule, chaîne vide si absente du nom), type (un ou deux mots simples en français, comme les vendeurs l'écrivent sur Vinted, par exemple polaire, jogging, jean, sans adjectif, chaîne vide si absent du nom), couleur (un seul mot, chaîne vide si absente du nom). N'invente rien : si une information n'est pas dans le nom, mets une chaîne vide."
        let t = try await generate(parts: [["text": p]], search: false)
        return try decode(t)
    }
    
    static func analyze(_ jpeg: Data) async throws -> PpAnalysis {
        let imagePart: [String: Any] = ["inline_data": ["mime_type": "image/jpeg", "data": jpeg.base64EncodedString()]]
        
        // Étape 1 : identifier la pièce à partir de la photo
        let idPrompt = "La photo montre un vêtement ou objet de seconde main. Réponds uniquement en JSON avec : nom (marque + modèle si reconnaissable + type + couleur ; description si la marque est illisible), marque (la marque seule, chaîne vide si illisible), type (un ou deux mots simples en français, comme les vendeurs les écrivent sur Vinted, par exemple polaire, doudoune, jean, sweat à capuche, robe, sans adjectif), couleur (un seul mot), taille (texte, vide si inconnue), etat (texte court)."
        let t1 = try await generate(parts: [["text": idPrompt], imagePart], search: false)
        var result = try decode(t1)
        
        // Étape 2 : prix réels sur Vinted via Google Search (la photo est renvoyée pour affiner la comparaison)
        let nom = result.nom ?? ""
        let q = "Recherche sur Vinted France (site:vinted.fr) des annonces ACTUELLES comparables à : \(nom), taille \(result.taille ?? "inconnue"), état \(result.etat ?? "inconnu"). Base-toi aussi sur la photo jointe pour identifier le modèle exact et ne comparer que des articles visuellement similaires. Relève uniquement les prix réellement affichés dans les annonces trouvées, en ignorant les articles différents. Réponds uniquement avec un objet JSON : {\"revente_bas\": nombre en euros (prix bas réaliste, environ 25e percentile), \"revente_haut\": nombre en euros (environ 75e percentile), \"nb_annonces\": nombre d'annonces comparables réellement trouvées, \"commentaire\": une phrase sur la fiabilité}. N'invente aucun prix : si tu ne trouves aucune annonce comparable, mets nb_annonces à 0 et revente_bas/revente_haut à null."
        let market: PpAnalysis
        do {
            let t2 = try await generate(parts: [["text": q], imagePart], search: true)
            market = try decode(t2)
        } catch {
            // Repli : la recherche a échoué, on garde l'identification et on estime sans recherche
            result.nb_annonces = 0
            result.commentaire = String(error.localizedDescription.prefix(120))
            let fb = "Tu aides à revendre sur Vinted France. Article : \(nom), taille \(result.taille ?? "inconnue"), état \(result.etat ?? "inconnu"). Réponds uniquement en JSON avec : revente_bas (nombre en euros), revente_haut (nombre en euros). Donne des prix de revente réalistes et prudents."
            if let t3 = try? await generate(parts: [["text": fb], imagePart], search: false),
               let est = try? decode(t3) {
                result.revente_bas = est.revente_bas
                result.revente_haut = est.revente_haut
                result.source = "estimation"
            }
            return result
        }
        if (market.nb_annonces ?? 0) > 0 {
            result.revente_bas = market.revente_bas
            result.revente_haut = market.revente_haut
        }
        result.nb_annonces = market.nb_annonces
        result.commentaire = market.commentaire
        return result
    }
}

// MARK: - Vinted : lecture directe des annonces depuis l'appareil

struct PpAnnonce: Identifiable {
    let id: String
    let titre: String
    let marque: String
    let etat: String
    let taille: String
    let prix: Double
    let lien: String
}

struct PpEstimation {
    var annonces: [PpAnnonce] = []
    var nbLues = 0
    var bas = 0.0
    var mediane = 0.0
    var haut = 0.0
    var venteProbable = 0.0
    var requete = ""
    var fiable = false
    var message = ""
    var tailleAppliquee = false
    var note = ""
}

enum PpVinted {
    static let agent = "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    static let decote = 0.85
    
    static func estimer(marque: String, type: String, couleur: String, taille: String) async -> PpEstimation {
        let m = nettoyer(marque)
        var requetes: [String] = []
        for mots in [[m, nettoyer(type), nettoyer(couleur)], [m, nettoyer(type)]] {
            let q = mots.filter { !$0.isEmpty }.joined(separator: " ")
            if !q.isEmpty && !requetes.contains(q) { requetes.append(q) }
        }
        if requetes.isEmpty {
            return PpEstimation(message: "Pas assez d'infos pour chercher : renseigne au moins la marque ou le type.")
        }
        
        let t = taille.trimmingCharacters(in: .whitespacesAndNewlines)
        var repondu = false
        var meilleur = PpEstimation()
        for q in requetes {
            var brutes: [PpAnnonce] = []
            var ids = Set<String>()
            for page in 1...3 {
                guard let p = await recuperer(requete: q, page: page) else { break }
                repondu = true
                for a in p where ids.insert(a.id).inserted { brutes.append(a) }
            }
            if brutes.isEmpty { continue }
            
            var liste = brutes
            if !m.isEmpty {
                liste = liste.filter { $0.marque.localizedCaseInsensitiveContains(m) }
            }
            var tailleOk = false
            if !t.isEmpty {
                let memeTaille = liste.filter { tailleCorrespond($0.taille, t) }
                if memeTaille.count >= 3 {
                    liste = memeTaille
                    tailleOk = true
                }
            }
            var est = calculer(liste, seuil: tailleOk ? 3 : 5)
            est.requete = q
            est.nbLues = brutes.count
            est.tailleAppliquee = tailleOk
            if !t.isEmpty {
                est.note = tailleOk
                ? "Filtré en taille \(t)."
                : "Pas assez d'annonces en taille \(t) : prix toutes tailles confondues."
            }
            if est.fiable && (t.isEmpty || tailleOk) { return est }
            if est.fiable || !meilleur.fiable { meilleur = est }
        }
        if !repondu {
            return PpEstimation(message: "Vinted n'a pas répondu : estimation non fiable.")
        }
        return meilleur
    }
    
    // Ramène une taille à une forme unique : "Medium", "m", "38" -> "M"
    static func tailleCanonique(_ s: String) -> String {
        let t = s.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        let equivalences: [String: String] = [
            "xxs": "XXS", "2xs": "XXS", "32": "XXS",
            "xs": "XS", "extrasmall": "XS", "34": "XS",
            "s": "S", "small": "S", "petit": "S", "36": "S",
            "m": "M", "medium": "M", "moyen": "M", "38": "M",
            "l": "L", "large": "L", "grand": "L", "40": "L",
            "xl": "XL", "xlarge": "XL", "extralarge": "XL", "42": "XL",
            "xxl": "XXL", "2xl": "XXL", "xxlarge": "XXL", "44": "XXL",
            "xxxl": "XXXL", "3xl": "XXXL", "46": "XXXL"
        ]
        return equivalences[t] ?? t.uppercased()
    }
    
    static func tailleCorrespond(_ annonce: String, _ voulue: String) -> Bool {
        func formes(_ s: String) -> Set<String> {
            Set(s.split(separator: "/").map { tailleCanonique($0.trimmingCharacters(in: .whitespaces)) })
        }
        return !formes(annonce).isDisjoint(with: formes(voulue))
    }
    
    static func nettoyer(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let vides = ["—", "-", "?", "inconnu", "inconnue", "n/a", "aucune", "sans marque", "null"]
        return vides.contains(t.lowercased()) ? "" : t
    }
    
    static func calculer(_ liste: [PpAnnonce], seuil: Int = 5) -> PpEstimation {
        var e = PpEstimation()
        e.annonces = liste
        guard liste.count >= seuil else {
            e.message = "Seulement \(liste.count) annonce(s) comparable(s) : estimation non fiable."
            return e
        }
        var prix = liste.map { $0.prix }.sorted()
        if prix.count >= 10 {
            let c = prix.count / 10
            prix = Array(prix[c..<(prix.count - c)])
        }
        let tri = prix
        func q(_ x: Double) -> Double { tri[Int(Double(tri.count - 1) * x)] }
        e.bas = q(0.25)
        e.mediane = q(0.5)
        e.haut = q(0.75)
        e.venteProbable = e.mediane * decote
        e.fiable = true
        return e
    }
    
    static func recuperer(requete: String, page: Int = 1) async -> [PpAnnonce]? {
        var comps = URLComponents(string: "https://www.vinted.fr/catalog")!
        comps.queryItems = [
            URLQueryItem(name: "search_text", value: requete),
            URLQueryItem(name: "page", value: String(page))
        ]
        guard let url = comps.url else { return nil }
        var req = URLRequest(url: url)
        req.setValue(agent, forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 20
        do {
            let (data, rep) = try await URLSession.shared.data(for: req)
            guard (rep as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return lire(String(decoding: data, as: UTF8.self))
        } catch {
            return nil
        }
    }
    
    static func lire(_ html: String) -> [PpAnnonce] {
        let motifLien = #"href="/items/(\d+)-([^"?]*)\?referrer=catalog"[^>]*?title="([^"]*)""#
        let motifTitre = #"^(.*?)(?:, Marque: (.*?))?(?:, État: (.*?))?(?:, Taille: (.*?))?, (\d+(?:[.,]\d+)?) €(?:, (\d+(?:[.,]\d+)?) €)?$"#
        guard let reLien = try? NSRegularExpression(pattern: motifLien),
              let reTitre = try? NSRegularExpression(pattern: motifTitre) else { return [] }
        let ns = html as NSString
        var vues = Set<String>()
        var sortie: [PpAnnonce] = []
        for m in reLien.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            let id = ns.substring(with: m.range(at: 1))
            if vues.contains(id) { continue }
            let slug = ns.substring(with: m.range(at: 2))
            let titre = decoder(ns.substring(with: m.range(at: 3)))
            let nt = titre as NSString
            guard let t = reTitre.firstMatch(in: titre, range: NSRange(location: 0, length: nt.length)) else { continue }
            func champ(_ i: Int) -> String {
                let r = t.range(at: i)
                return r.location == NSNotFound ? "—" : nt.substring(with: r)
            }
            guard let prix = Double(champ(5).replacingOccurrences(of: ",", with: ".")) else { continue }
            vues.insert(id)
            sortie.append(PpAnnonce(id: id, titre: champ(1), marque: champ(2), etat: champ(3),
                                    taille: champ(4), prix: prix,
                                    lien: "https://www.vinted.fr/items/\(id)-\(slug)"))
        }
        return sortie
    }
    
    static func decoder(_ s: String) -> String {
        s.replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}

struct PpVintedResultView: View {
    let est: PpEstimation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if est.fiable {
                Text("Vente probable : ~\(Int(est.venteProbable.rounded())) €")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.ppPine)
                Text(String(format: "Annonces comparables : %.0f – %.0f € (médiane %.0f €)", est.bas, est.haut, est.mediane))
                    .font(.system(size: 13))
                    .foregroundColor(.ppPine)
                Text("\(est.annonces.count) annonces retenues · recherche « \(est.requete) »")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                if !est.note.isEmpty {
                    Text(est.note)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(est.tailleAppliquee ? .ppPine : .orange)
                }
                ForEach(est.annonces.prefix(5)) { a in
                    if let url = URL(string: a.lien) {
                        Link("\(Int(a.prix)) € · \(a.taille) · \(a.titre)", destination: url)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                }
            } else {
                Text(est.message)
                    .font(.system(size: 13))
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Outils

func ppEur(_ v: Double) -> String { String(format: "%.0f €", v) }

func ppNum(_ s: String) -> Double {
    Double(s.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) ?? 0
}

func ppCompress(_ img: UIImage, maxSide: CGFloat = 1024) -> Data? {
    let s = max(img.size.width, img.size.height)
    guard s > 0 else { return nil }
    let k = min(1, maxSide / s)
    let size = CGSize(width: img.size.width * k, height: img.size.height * k)
    let f = UIGraphicsImageRendererFormat()
    f.scale = 1
    let out = UIGraphicsImageRenderer(size: size, format: f).image { _ in
        img.draw(in: CGRect(origin: .zero, size: size))
    }
    return out.jpegData(compressionQuality: 0.7)
}

func ppScore(low: Double, asked: Double, fees: Double = 2) -> Int {
    guard low > 0, asked > 0 else { return 0 }
    let profit = low - asked - fees
    let ratio = profit / asked
    let raw = 40 + min(max(profit, 0), 30) * 1.2 + min(max(ratio, 0), 3) * 8
    return Int(min(100, max(0, raw)).rounded())
}

func ppVerdict(_ s: Int) -> (String, Color) {
    switch s {
    case 90...: return ("Excellente pépite", .green)
    case 75..<90: return ("Bonne affaire", .green)
    case 60..<75: return ("À réfléchir", .orange)
    default: return ("Pas intéressant", .red)
    }
}

struct PpCameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PpCameraPicker
        init(_ p: PpCameraPicker) { parent = p }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onImage(img) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - Hors connexion : articles en attente, photos en cache, bandeau d'état

struct PpPending: Identifiable, Codable {
    var id: String
    var uid: String
    var team_id: String
    var name: String
    var brand: String
    var size: String
    var condition: String
    var asked: Double
    var resale_low: Double
    var resale_high: Double
    var score: Int
    var added_by: String
    var photoFiles: [String]
    var uploaded: [String] = []
}

// Modification d'un article existant (envoyée au serveur dès que possible)
struct PpPatch: Codable {
    var name: String? = nil
    var brand: String? = nil
    var size: String? = nil
    var condition: String? = nil
    var asked: Double? = nil
    var buy: Double? = nil
    var resale_low: Double? = nil
    var resale_high: Double? = nil
    var score: Int? = nil
    var status: String? = nil
    var sold: Double? = nil
    var clearSold: Bool = false
    var sold_at: String? = nil
    var deleted_at: String? = nil
    var clearDeleted: Bool? = nil
    
    var fields: [String: Any] {
        var d: [String: Any] = [:]
        if let v = name { d["name"] = v }
        if let v = brand { d["brand"] = v }
        if let v = size { d["size"] = v }
        if let v = condition { d["condition"] = v }
        if let v = asked { d["asked"] = v }
        if let v = buy { d["buy"] = v }
        if let v = resale_low { d["resale_low"] = v }
        if let v = resale_high { d["resale_high"] = v }
        if let v = score { d["score"] = v }
        if let v = status { d["status"] = v }
        if clearSold {
            d["sold"] = NSNull()
            d["sold_at"] = NSNull()
        } else {
            if let v = sold { d["sold"] = v }
            if let v = sold_at { d["sold_at"] = v }
        }
        if let v = deleted_at { d["deleted_at"] = v }
        if clearDeleted == true { d["deleted_at"] = NSNull() }
        return d
    }
    
    func apply(to item: PpItem) -> PpItem {
        var i = item
        if let v = name { i.name = v }
        if let v = brand { i.brand = v }
        if let v = size { i.size = v }
        if let v = condition { i.condition = v }
        if let v = asked { i.asked = v }
        if let v = buy { i.buy = v }
        if let v = resale_low { i.resale_low = v }
        if let v = resale_high { i.resale_high = v }
        if let v = score { i.score = v }
        if let v = status { i.status = v }
        if clearSold {
            i.sold = nil
            i.sold_at = nil
        } else {
            if let v = sold { i.sold = v }
            if let v = sold_at { i.sold_at = v }
        }
        if let v = deleted_at { i.deleted_at = v }
        if clearDeleted == true { i.deleted_at = nil }
        return i
    }
}

struct PpOp: Identifiable, Codable {
    var id: String
    var uid: String
    var itemId: String
    var delete: Bool
    var patch: PpPatch? = nil
}

enum PpPendingStore {
    static var dir: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("pp_pending", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }
    static func load() -> [PpPending] {
        guard let d = UserDefaults.standard.data(forKey: "pp_pending"),
              let a = try? JSONDecoder().decode([PpPending].self, from: d) else { return [] }
        return a
    }
    static func save(_ a: [PpPending]) {
        if let d = try? JSONEncoder().encode(a) {
            UserDefaults.standard.set(d, forKey: "pp_pending")
        }
    }
    static func loadOps() -> [PpOp] {
        guard let d = UserDefaults.standard.data(forKey: "pp_ops"),
              let a = try? JSONDecoder().decode([PpOp].self, from: d) else { return [] }
        return a
    }
    static func saveOps(_ a: [PpOp]) {
        if let d = try? JSONEncoder().encode(a) {
            UserDefaults.standard.set(d, forKey: "pp_ops")
        }
    }
    static func photo(_ file: String) -> Data? {
        try? Data(contentsOf: dir.appendingPathComponent(file))
    }
    static func writePhoto(_ data: Data, _ file: String) {
        try? data.write(to: dir.appendingPathComponent(file))
    }
    static func deletePhoto(_ file: String) {
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(file))
    }
}

extension PpPending {
    // Présente un article en attente comme un article du stock (id préfixé "local-")
    var asItem: PpItem {
        let urls = photoFiles.map { PpPendingStore.dir.appendingPathComponent($0).absoluteString }
        return PpItem(id: "local-" + id, team_id: team_id, name: name, size: size, condition: condition,
                      asked: asked, resale_low: resale_low, resale_high: resale_high, score: score,
                      status: "stock", buy: asked, sold: nil, photo_url: urls.first,
                      added_by: added_by, created_at: nil,
                      brand: brand.isEmpty ? nil : brand, photos: urls)
    }
}

enum PpImageCache {
    static var dir: URL {
        let d = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("pp_photos", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
    
    static func load(_ urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        if url.isFileURL { return UIImage(contentsOfFile: url.path) }
        let f = dir.appendingPathComponent(url.lastPathComponent)
        if let d = try? Data(contentsOf: f), let img = UIImage(data: d) { return img }
        guard let (data, resp) = try? await URLSession.shared.data(from: url),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let img = UIImage(data: data) else { return nil }
        try? data.write(to: f)
        return img
    }
}

struct PpRemoteImage: View {
    let url: String?
    var fill = true
    @State private var img: UIImage? = nil
    
    var body: some View {
        Group {
            if let img = img {
                if fill {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Image(uiImage: img).resizable().scaledToFit()
                }
            } else if fill {
                Color.ppSage
            } else {
                Color.ppSage.frame(height: 200)
            }
        }
        .task(id: url) {
            if let u = url, !u.isEmpty { img = await PpImageCache.load(u) }
        }
    }
}

struct PpStatusBanner: View {
    @EnvironmentObject var store: PpStore
    
    var body: some View {
        let n = store.pendingCount
        if store.offline || n > 0 || !store.syncError.isEmpty || (!store.error.isEmpty && store.checked) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: store.offline ? "wifi.slash" : "arrow.triangle.2.circlepath")
                    Text(titre(n))
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.orange)
                if !store.syncError.isEmpty {
                    Text(store.syncError)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                if !store.error.isEmpty && !store.offline {
                    Text(store.error)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                if !store.syncError.isEmpty && !store.opsMine.isEmpty {
                    Button("Abandonner les modifications en attente") { store.clearOps() }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
                Button("Réessayer maintenant") {
                    Task {
                        await store.refreshAll()
                        await store.syncPending()
                    }
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.ppPine)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.ppPaper)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private func titre(_ n: Int) -> String {
        let s = n > 1 ? "s" : ""
        if store.offline {
            return n > 0
            ? "Hors connexion · \(n) élément\(s) en attente d'envoi"
            : "Hors connexion : dernières données affichées"
        }
        if n > 0 { return "\(n) élément\(s) en attente d'envoi" }
        return "Problème de synchronisation"
    }
}

// MARK: - Données partagées

@MainActor
final class PpStore: ObservableObject {
    @Published var loggedIn = UserDefaults.standard.string(forKey: "pp_refresh") != nil
    @Published var email = UserDefaults.standard.string(forKey: "pp_email") ?? ""
    @Published var team: PpTeam? = nil
    @Published var members = 0
    @Published var items: [PpItem] = []
    @Published var checked = false
    @Published var error = ""
    @Published var offline = false
    @Published var syncError = ""
    @Published var syncing = false
    @Published var loadedOnce = false
    @Published var pending: [PpPending] = PpPendingStore.load()
    @Published var ops: [PpOp] = PpPendingStore.loadOps()
    
    init() {
        // Au lancement : on affiche tout de suite les dernières données connues
        let d = UserDefaults.standard
        if loggedIn,
           let td = d.data(forKey: "pp_cache_team"),
           let t = try? JSONDecoder().decode(PpTeam.self, from: td) {
            team = t
            if let idata = d.data(forKey: "pp_cache_items"),
               let list = try? JSONDecoder().decode([PpItem].self, from: idata) {
                items = list
            }
            members = d.integer(forKey: "pp_cache_members")
            checked = true
        }
    }
    
    // Éléments en attente d'envoi pour le compte connecté
    var pendingMine: [PpPending] { pending.filter { $0.uid == PpAPI.uid } }
    var opsMine: [PpOp] { ops.filter { $0.uid == PpAPI.uid } }
    var pendingCount: Int { pendingMine.count + opsMine.count }
    
    // Articles du serveur avec les modifications en attente appliquées,
    // précédés des nouveaux articles pas encore envoyés
    private var allItems: [PpItem] {
        var base = items
        for op in opsMine {
            if op.delete {
                base.removeAll { $0.id == op.itemId }
            } else if let patch = op.patch, let idx = base.firstIndex(where: { $0.id == op.itemId }) {
                base[idx] = patch.apply(to: base[idx])
            }
        }
        return base
    }
    
    // Articles actifs (hors corbeille), précédés des nouveaux articles pas encore envoyés
    var displayItems: [PpItem] {
        let live = allItems.filter { ($0.deleted_at ?? "").isEmpty }
        return pendingMine.reversed().map { $0.asItem } + live
    }
    
    // Articles supprimés depuis moins de 30 jours
    var trashItems: [PpItem] {
        allItems.filter { !($0.deleted_at ?? "").isEmpty }
            .sorted { ($0.deleted_at ?? "") > ($1.deleted_at ?? "") }
    }
    
    func authenticate(email: String, password: String, create: Bool) async -> String? {
        do {
            let path = create ? "/auth/v1/signup" : "/auth/v1/token?grant_type=password"
            let s = try await PpAPI.authCall(path, ["email": email, "password": password])
            if s.access_token == nil {
                return "Si cet e-mail n'a pas encore de compte, tu vas recevoir un mail de confirmation : ouvre le lien, puis choisis « Se connecter ». S'il en a déjà un, choisis directement « Se connecter »."
            }
            PpAPI.save(s)
            self.email = UserDefaults.standard.string(forKey: "pp_email") ?? email
            checked = false
            loggedIn = true
            await refreshAll()
            return nil
        } catch {
            return error.localizedDescription
        }
    }
    
    func signOut() {
        PpAPI.clear()
        loggedIn = false
        team = nil
        items = []
        members = 0
        checked = false
        email = ""
        offline = false
        error = ""
        syncError = ""
    }
    
    private func saveCache() {
        let d = UserDefaults.standard
        if let t = team, let data = try? JSONEncoder().encode(t) {
            d.set(data, forKey: "pp_cache_team")
        } else {
            d.removeObject(forKey: "pp_cache_team")
        }
        if let data = try? JSONEncoder().encode(items) {
            d.set(data, forKey: "pp_cache_items")
        }
        d.set(members, forKey: "pp_cache_members")
    }
    
    func refreshAll() async {
        defer { loadedOnce = true }
        do {
            let path = "/rest/v1/team_members?select=team_id,teams(id,name,invite_code,gemini_key)&user_id=eq." + PpAPI.uid
            let d = try await PpAPI.call(path)
            let ms = try JSONDecoder().decode([PpMembership].self, from: d)
            team = ms.first?.teams
            UserDefaults.standard.set(team?.gemini_key ?? "", forKey: "pp_team_gem")
            checked = true
            if let t = team {
                let m = try await PpAPI.call("/rest/v1/team_members?select=user_id&team_id=eq." + t.id)
                if let arr = try JSONSerialization.jsonObject(with: m) as? [Any] {
                    members = arr.count
                }
                items = try await PpAPI.fetchItems()
            } else {
                items = []
                members = 0
            }
            saveCache()
            offline = false
            error = ""
        } catch let err {
            if err is URLError {
                offline = true
            } else {
                self.error = err.localizedDescription
            }
            if !checked { self.error = err.localizedDescription }
        }
    }
    
    // Enregistre un nouvel article sur l'appareil ; il sera envoyé dès que possible
    func addPending(teamId: String, name: String, brand: String, size: String, condition: String,
                    asked: Double, low: Double, high: Double, score: Int, jpegs: [Data]) {
        let id = UUID().uuidString.lowercased()
        var files: [String] = []
        for (i, d) in jpegs.enumerated() {
            let f = "\(id)-\(i).jpg"
            PpPendingStore.writePhoto(d, f)
            files.append(f)
        }
        pending.append(PpPending(id: id, uid: PpAPI.uid, team_id: teamId, name: name, brand: brand,
                                 size: size, condition: condition, asked: asked, resale_low: low,
                                 resale_high: high, score: score, added_by: PpCfg.who,
                                 photoFiles: files))
        PpPendingStore.save(pending)
    }
    
    func removePending(_ localId: String) {
        let id = localId.replacingOccurrences(of: "local-", with: "")
        if let p = pending.first(where: { $0.id == id }) {
            for f in p.photoFiles { PpPendingStore.deletePhoto(f) }
        }
        pending.removeAll { $0.id == id }
        PpPendingStore.save(pending)
    }
    
    // Modification ou suppression d'un article : appliquée tout de suite à l'écran,
    // envoyée au serveur dès que possible
    func enqueue(itemId: String, delete: Bool = false, patch: PpPatch? = nil) {
        if itemId.hasPrefix("local-") {
            if delete {
                removePending(itemId)
            } else if let p = patch {
                modifierPending(itemId, p)
            }
            return
        }
        ops.append(PpOp(id: UUID().uuidString, uid: PpAPI.uid, itemId: itemId, delete: delete, patch: patch))
        PpPendingStore.saveOps(ops)
    }
    
    private func modifierPending(_ localId: String, _ p: PpPatch) {
        let id = localId.replacingOccurrences(of: "local-", with: "")
        guard let i = pending.firstIndex(where: { $0.id == id }) else { return }
        if let v = p.name { pending[i].name = v }
        if let v = p.brand { pending[i].brand = v }
        if let v = p.size { pending[i].size = v }
        if let v = p.condition { pending[i].condition = v }
        if let v = p.buy { pending[i].asked = v }
        if let v = p.asked { pending[i].asked = v }
        if let v = p.resale_low { pending[i].resale_low = v }
        if let v = p.resale_high { pending[i].resale_high = v }
        if let v = p.score { pending[i].score = v }
        PpPendingStore.save(pending)
    }
    
    func clearOps() {
        ops.removeAll { $0.uid == PpAPI.uid }
        PpPendingStore.saveOps(ops)
        syncError = ""
    }
    
    // Envoie d'abord les nouveaux articles, puis les modifications, dans l'ordre ;
    // s'arrête à la première erreur
    func syncPending() async {
        if syncing { return }
        let mine = pendingMine
        let myOps = opsMine
        guard !mine.isEmpty || !myOps.isEmpty else {
            syncError = ""
            return
        }
        syncing = true
        defer { syncing = false }
        var envoye = false
        var stop = false
        
        for p in mine {
            let restant = p.photoFiles.dropFirst(p.uploaded.count)
            if restant.contains(where: { PpPendingStore.photo($0) == nil }) {
                removePending("local-" + p.id)
                continue
            }
            do {
                var urls = p.uploaded
                for f in restant {
                    guard let jpeg = PpPendingStore.photo(f) else { continue }
                    let u = try await PpAPI.uploadPhoto(jpeg)
                    urls.append(u)
                    if let i = pending.firstIndex(where: { $0.id == p.id }) {
                        pending[i].uploaded = urls
                        PpPendingStore.save(pending)
                    }
                }
                let n = PpNewItem(id: p.id, team_id: p.team_id, name: p.name, size: p.size,
                                  condition: p.condition, asked: p.asked, resale_low: p.resale_low,
                                  resale_high: p.resale_high, score: p.score, status: "stock",
                                  buy: p.asked, photo_url: urls.first, added_by: p.added_by,
                                  brand: p.brand.isEmpty ? nil : p.brand,
                                  photos: urls.count > 1 ? urls : nil)
                try await PpAPI.insert(n, ignoreDuplicates: true)
                pending.removeAll { $0.id == p.id }
                PpPendingStore.save(pending)
                for f in p.photoFiles { PpPendingStore.deletePhoto(f) }
                envoye = true
                syncError = ""
            } catch let err {
                if err is URLError {
                    offline = true
                } else {
                    syncError = err.localizedDescription
                }
                stop = true
                break
            }
        }
        
        if !stop {
            for op in myOps {
                do {
                    if op.delete {
                        try await PpAPI.delete(op.itemId)
                    } else if let patch = op.patch {
                        try await PpAPI.update(op.itemId, patch.fields)
                    }
                    ops.removeAll { $0.id == op.id }
                    PpPendingStore.saveOps(ops)
                    envoye = true
                    syncError = ""
                } catch let err {
                    if err is URLError {
                        offline = true
                    } else {
                        syncError = err.localizedDescription
                    }
                    break
                }
            }
        }
        if envoye { await refreshAll() }
    }
    
    // Supprime pour de bon les articles restés plus de 30 jours dans la corbeille
    func purgeExpired() async {
        var any = false
        for it in trashItems {
            guard let d = PpDate.parse(it.deleted_at) else { continue }
            let j = Calendar.current.dateComponents([.day], from: d, to: Date()).day ?? 0
            if j >= 30 {
                do {
                    try await PpAPI.delete(it.id)
                    any = true
                } catch {
                    break
                }
            }
        }
        if any { await refreshAll() }
    }
    
    // Photos d'un article pas encore envoyé : modifiées sur l'appareil
    func addPhotoPending(_ localId: String, _ jpeg: Data) {
        let id = localId.replacingOccurrences(of: "local-", with: "")
        guard let i = pending.firstIndex(where: { $0.id == id }) else { return }
        let f = "\(id)-" + String(UUID().uuidString.prefix(8)) + ".jpg"
        PpPendingStore.writePhoto(jpeg, f)
        pending[i].photoFiles.append(f)
        PpPendingStore.save(pending)
    }
    
    func removePhotoPending(_ localId: String, index: Int) {
        let id = localId.replacingOccurrences(of: "local-", with: "")
        guard let i = pending.firstIndex(where: { $0.id == id }) else { return }
        guard index < pending[i].photoFiles.count else { return }
        let f = pending[i].photoFiles.remove(at: index)
        PpPendingStore.deletePhoto(f)
        if index < pending[i].uploaded.count {
            pending[i].uploaded.remove(at: index)
        }
        PpPendingStore.save(pending)
    }
    
    // Photos d'un article déjà sur le serveur : nouvelle liste enregistrée directement
    func setPhotos(itemId: String, urls: [String]) async -> String? {
        var fields: [String: Any] = ["photos": urls]
        if let first = urls.first {
            fields["photo_url"] = first
        } else {
            fields["photo_url"] = NSNull()
        }
        do {
            try await PpAPI.update(itemId, fields)
            await refreshAll()
            return nil
        } catch {
            if error is URLError {
                return "Pas de connexion : réessaie quand le réseau revient."
            }
            return error.localizedDescription
        }
    }
    
    func createTeam(name: String) async -> String? {
        do {
            _ = try await PpAPI.rpc("create_team", ["team_name": name])
            await refreshAll()
            return nil
        } catch {
            return error.localizedDescription
        }
    }
    
    func joinTeam(code: String) async -> String? {
        do {
            _ = try await PpAPI.rpc("join_team", ["code": code])
            await refreshAll()
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}

// MARK: - Racine

struct ContentView: View {
    @StateObject private var store = PpStore()
    @State private var booting = true
    
    var body: some View {
        ZStack {
            Group {
                if !store.loggedIn {
                    PpAuthView()
                } else if !store.checked {
                    PpLoadingView()
                } else if store.team == nil {
                    PpTeamSetupView()
                } else {
                    PpMainTabs()
                }
            }
            if booting {
                PpSplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .environmentObject(store)
        .preferredColorScheme(.light)
        .tint(.ppPine)
        .task {
            if store.loggedIn {
                Task {
                    await store.refreshAll()
                    await store.syncPending()
                    await store.purgeExpired()
                }
                // L'écran de lancement reste le temps du premier chargement (4 secondes au maximum)
                var attente = 0
                while !store.loadedOnce && attente < 40 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    attente += 1
                }
            }
            withAnimation(.easeOut(duration: 0.3)) {
                booting = false
            }
        }
    }
}

// Écran de lancement : logo et roue de chargement
struct PpSplashView: View {
    @State private var shown = false
    
    var body: some View {
        ZStack {
            Color.ppCream.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 84, height: 84)
                    .background(Color.ppPine)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .scaleEffect(shown ? 1 : 0.8)
                Text("PÉPITE")
                    .font(.system(size: 24, weight: .heavy))
                    .tracking(4)
                    .foregroundColor(.ppPine)
                Text("La chasse aux bonnes affaires")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                ProgressView()
                    .tint(.ppPine)
                    .padding(.top, 8)
            }
            .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                shown = true
            }
        }
    }
}

struct PpLoadingView: View {
    @EnvironmentObject var store: PpStore
    var body: some View {
        VStack(spacing: 16) {
            PpBrand()
            ProgressView()
            if !store.error.isEmpty {
                Text(store.error)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                Button("Réessayer") { Task { await store.refreshAll() } }
                    .buttonStyle(PpPrimaryStyle())
                Button("Se déconnecter") { store.signOut() }
                    .buttonStyle(PpOutlineStyle())
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ppCream.ignoresSafeArea())
    }
}

// MARK: - Connexion

struct PpAuthView: View {
    @EnvironmentObject var store: PpStore
    @AppStorage("sb_url") private var sbURL = ""
    @AppStorage("sb_key") private var sbKey = ""
    @State private var create = true
    @State private var email = ""
    @State private var password = ""
    @State private var msg = ""
    @State private var busy = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PpBrand()
                    .padding(.top, 20)
                
                Image(systemName: "person.2")
                    .font(.system(size: 22))
                    .foregroundColor(.ppPine)
                    .frame(width: 56, height: 56)
                    .background(Color.ppSage)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text("À deux, chaque pièce compte.")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.ppPine)
                
                Text("Connectez-vous pour retrouver vos achats, vos estimations et votre marge depuis le même vestiaire.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 12) {
                    Picker("", selection: $create) {
                        Text("Créer un compte").tag(true)
                        Text("Se connecter").tag(false)
                    }
                    .pickerStyle(.segmented)
                    
                    Text("E-mail")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.ppPine)
                    TextField("E-mail", text: $email,
                              prompt: Text(verbatim: "vous@exemple.fr").foregroundColor(.gray))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .ppField()
                    
                    Text("Mot de passe")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.ppPine)
                    SecureField("8 caractères minimum", text: $password)
                        .ppField()
                    
                    Button(create ? "Créer mon compte" : "Continuer") { submit() }
                        .buttonStyle(PpPrimaryStyle())
                        .disabled(busy)
                    
                    if !msg.isEmpty {
                        Text(msg)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                .padding(16)
                .background(Color.ppPaper)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                
                DisclosureGroup("Réglages du serveur") {
                    VStack(spacing: 10) {
                        TextField("Adresse Supabase (https://…supabase.co)", text: $sbURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .ppField()
                        SecureField("Clé publique Supabase", text: $sbKey)
                            .ppField()
                    }
                    .padding(.top, 8)
                }
                .font(.system(size: 13))
                .foregroundColor(.ppPine)
                
                Text("Vos vêtements et vos estimations restent privés à votre équipe.")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .padding(20)
        }
        .background(Color.ppCream.ignoresSafeArea())
    }
    
    func submit() {
        let clean = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.contains("@"), password.count >= 8 else {
            msg = "Entre un e-mail valide et un mot de passe de 8 caractères minimum."
            return
        }
        busy = true
        msg = ""
        Task {
            if let err = await store.authenticate(email: clean, password: password, create: create) {
                msg = err
            }
            busy = false
        }
    }
}

// MARK: - Création ou jonction de l'espace

struct PpTeamSetupView: View {
    @EnvironmentObject var store: PpStore
    @State private var teamName = "Les trouvailles du dimanche"
    @State private var code = ""
    @State private var msg = ""
    @State private var busy = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PpBrand().padding(.top, 20)
                
                Text("Votre vestiaire à deux.")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.ppPine)
                
                Text("Un seul de vous crée l'espace. L'autre le rejoint avec le code d'invitation.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("CRÉER L'ESPACE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.ppClay)
                    TextField("Nom de l'espace", text: $teamName)
                        .ppField()
                    Button("Créer notre espace") {
                        run { await store.createTeam(name: teamName) }
                    }
                    .buttonStyle(PpPrimaryStyle())
                    .disabled(busy)
                }
                .padding(16)
                .background(Color.ppPaper)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("REJOINDRE AVEC UN CODE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.ppClay)
                    TextField("Code d'invitation", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .ppField()
                    Button("Rejoindre") {
                        run { await store.joinTeam(code: code) }
                    }
                    .buttonStyle(PpOutlineStyle())
                    .disabled(busy)
                }
                .padding(16)
                .background(Color.ppPaper)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                
                if !msg.isEmpty {
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                
                Button("Se déconnecter") { store.signOut() }
                    .buttonStyle(PpOutlineStyle(color: .red))
            }
            .padding(20)
        }
        .background(Color.ppCream.ignoresSafeArea())
    }
    
    func run(_ action: @escaping () async -> String?) {
        busy = true
        msg = ""
        Task {
            if let err = await action() { msg = err }
            busy = false
        }
    }
}

// MARK: - Onglets

struct PpMainTabs: View {
    @EnvironmentObject var store: PpStore
    @State private var tab = 0
    @AppStorage("stale_days") private var staleDays = 30
    
    var staleCount: Int { PpStale.list(store.displayItems, days: staleDays).count }
    
    var body: some View {
        TabView(selection: $tab) {
            PpStockTab(tab: $tab)
                .tabItem { Label("Stock", systemImage: "shippingbox") }
                .badge(staleCount)
                .tag(0)
            PpScannerTab(tab: $tab)
                .tabItem { Label("Scanner", systemImage: "camera") }
                .tag(1)
            PpStatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
                .tag(3)
            PpTeamTab()
                .tabItem { Label("Équipe", systemImage: "person.2") }
                .tag(2)
        }
        .tint(.ppPine)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                await store.refreshAll()
                await store.syncPending()
            }
        }
    }
}

// MARK: - Stock

struct PpStockTab: View {
    @EnvironmentObject var store: PpStore
    @Binding var tab: Int
    @State private var query = ""
    @State private var showSold = false
    
    enum Tri: String, CaseIterable, Hashable {
        case recents = "Plus récents"
        case anciens = "Plus anciens"
        case marge = "Marge décroissante"
        case revente = "Revente décroissante"
        case nom = "Nom A–Z"
    }
    @State private var tri: Tri = .recents
    @State private var brandFilter = ""
    @State private var sizeFilter = ""
    @State private var staleOnly = false
    @State private var copied = false
    @AppStorage("stale_days") private var staleDays = 30
    
    var forSale: [PpItem] { store.displayItems.filter { $0.status == "stock" } }
    var sold: [PpItem] { store.displayItems.filter { $0.status == "vendu" } }
    
    var staleItems: [PpItem] { PpStale.list(forSale, days: staleDays) }
    
    func gain(_ i: PpItem) -> Double {
        i.status == "vendu" ? (i.sold ?? 0) - (i.buy ?? 0) : (i.resale_low ?? 0) - (i.buy ?? 0)
    }
    
    var hasFilters: Bool { !brandFilter.isEmpty || !sizeFilter.isEmpty || staleOnly }
    
    var shown: [PpItem] {
        var base = showSold ? sold : forSale
        if staleOnly && !showSold {
            let ids = Set(staleItems.map { $0.id })
            base = base.filter { ids.contains($0.id) }
        }
        if !query.isEmpty {
            base = base.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        if !brandFilter.isEmpty {
            base = base.filter { ($0.brand ?? "").caseInsensitiveCompare(brandFilter) == .orderedSame }
        }
        if !sizeFilter.isEmpty {
            base = base.filter { PpVinted.tailleCorrespond($0.size ?? "", sizeFilter) }
        }
        switch tri {
        case .recents: break
        case .anciens: base.reverse()
        case .marge: base.sort { gain($0) > gain($1) }
        case .revente: base.sort { ($0.resale_low ?? 0) > ($1.resale_low ?? 0) }
        case .nom: base.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        return base
    }
    
    var brands: [String] {
        var seen: [String: String] = [:]
        for i in store.displayItems {
            let b = (i.brand ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !b.isEmpty && seen[b.lowercased()] == nil { seen[b.lowercased()] = b }
        }
        return seen.values.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
    
    var sizes: [String] {
        var set = Set<String>()
        for i in store.displayItems {
            for t in (i.size ?? "").split(separator: "/") {
                let c = PpVinted.tailleCanonique(t.trimmingCharacters(in: .whitespaces))
                if !c.isEmpty { set.insert(c) }
            }
        }
        let ordre = ["XXS", "XS", "S", "M", "L", "XL", "XXL", "XXXL"]
        return set.sorted { (ordre.firstIndex(of: $0) ?? 99, $0) < (ordre.firstIndex(of: $1) ?? 99, $1) }
    }
    
    var margin: Double {
        forSale.reduce(0) { $0 + max(0, ($1.resale_low ?? 0) - ($1.buy ?? 0)) }
    }
    var engaged: Double {
        forSale.reduce(0) { $0 + ($1.buy ?? 0) }
    }
    var realProfit: Double {
        sold.reduce(0) { $0 + (($1.sold ?? 0) - ($1.buy ?? 0)) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        PpBrand()
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "person.2").font(.system(size: 11))
                            Text("\(store.members)/2").font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.ppPine)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.ppSage)
                        .clipShape(Capsule())
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("VOTRE VESTIAIRE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2)
                                .foregroundColor(.ppClay)
                            Text(store.team?.name ?? "")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.ppPine)
                        }
                        Spacer()
                        Button {
                            tab = 1
                        } label: {
                            Image(systemName: "camera")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.ppClay)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    
                    PpStatusBanner()
                    
                    summaryCard
                    
                    if !showSold && !staleItems.isEmpty {
                        staleCard
                    }
                    
                    HStack(spacing: 6) {
                        Text("Les pièces")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.ppPine)
                        Text("\(shown.count)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Rechercher une pièce", text: $query)
                            .foregroundColor(.ppPine)
                    }
                    .padding(12)
                    .background(Color.ppPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    HStack(spacing: 8) {
                        chip("En vente", forSale.count, !showSold) { showSold = false }
                        chip("Vendus", sold.count, showSold) { showSold = true }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Menu {
                                Picker("Tri", selection: $tri) {
                                    ForEach(Tri.allCases, id: \.self) { t in
                                        Text(t.rawValue).tag(t)
                                    }
                                }
                            } label: {
                                pill("arrow.up.arrow.down", tri.rawValue, active: tri != .recents)
                            }
                            Menu {
                                Button("Toutes les marques") { brandFilter = "" }
                                ForEach(brands, id: \.self) { b in
                                    Button(b) { brandFilter = b }
                                }
                            } label: {
                                pill("tag", brandFilter.isEmpty ? "Marque" : brandFilter, active: !brandFilter.isEmpty)
                            }
                            Menu {
                                Button("Toutes les tailles") { sizeFilter = "" }
                                ForEach(sizes, id: \.self) { t in
                                    Button(t) { sizeFilter = t }
                                }
                            } label: {
                                pill("textformat.size", sizeFilter.isEmpty ? "Taille" : sizeFilter, active: !sizeFilter.isEmpty)
                            }
                            Button {
                                UIPasteboard.general.string = PpCSV.texte(store.displayItems)
                                copied = true
                                Task {
                                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                                    copied = false
                                }
                            } label: {
                                pill(copied ? "checkmark" : "doc.on.doc",
                                     copied ? "Copié" : "Copier le stock",
                                     active: copied)
                            }
                        }
                    }
                    
                    if shown.isEmpty && (hasFilters || !query.isEmpty) {
                        Text("Aucune pièce ne correspond à ces filtres.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    } else if shown.isEmpty {
                        emptyCard
                    } else {
                        ForEach(shown) { item in
                            NavigationLink {
                                PpItemDetail(itemId: item.id)
                            } label: {
                                PpItemCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .refreshable {
                await store.refreshAll()
                await store.syncPending()
            }
            .background(Color.ppCream.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private func pill(_ icon: String, _ text: String, active: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundColor(active ? .white : .ppPine)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(active ? Color.ppPine : Color.ppSage)
        .clipShape(Capsule())
    }
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(showSold ? "BÉNÉFICE RÉEL" : "MARGE POTENTIELLE")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.7))
            Text(ppEur(showSold ? realProfit : margin))
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.white)
            Divider().background(Color.white.opacity(0.3))
            HStack {
                Text("\(forSale.count) articles en vente")
                Spacer()
                Text("Achat engagé · \(ppEur(engaged))")
            }
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.85))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppPine)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private var staleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "clock.badge.exclamationmark")
                Text("À RELANCER · \(staleItems.count)")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
            }
            .foregroundColor(.ppClay)
            Text("Invendus depuis \(staleDays) jours ou plus. Baisse le prix ou remets l'annonce en avant.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            ForEach(staleItems.prefix(3)) { it in
                NavigationLink {
                    PpItemDetail(itemId: it.id)
                } label: {
                    HStack {
                        Text(it.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.ppPine)
                            .lineLimit(1)
                        Spacer()
                        Text("\(PpStale.age(it) ?? 0) j")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.ppClay)
                    }
                }
                .buttonStyle(.plain)
            }
            Button(staleOnly ? "Tout afficher" : "Voir tous les invendus") { staleOnly.toggle() }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.ppPine)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppPaper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "archivebox")
                .font(.system(size: 20))
                .foregroundColor(.ppPine)
                .frame(width: 48, height: 48)
                .background(Color.ppSage)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            Text(showSold ? "Rien de vendu pour l'instant." : "La première pièce vous attend.")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.ppPine)
            Text("Photographiez un vêtement : l'IA estimera sa valeur de revente.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Button("Scanner une pièce") { tab = 1 }
                .buttonStyle(PpPrimaryStyle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppPaper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private func chip(_ title: String, _ count: Int, _ active: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("\(title)  \(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(active ? .white : .ppPine)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(active ? Color.ppPine : Color.ppSage)
                .clipShape(Capsule())
        }
    }
}

struct PpItemCard: View {
    let item: PpItem
    
    var body: some View {
        HStack(spacing: 12) {
            PpRemoteImage(url: item.photo_url)
                .frame(width: 70, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.ppPine)
                    .lineLimit(2)
                Text(infoLine)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                Text(priceLine)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.ppPine)
            }
            Spacer()
            if item.status == "stock", let s = item.score {
                Text("\(s)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ppVerdict(s).1)
                    .padding(8)
                    .background(Color.ppSage)
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(Color.ppPaper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    var infoLine: String {
        var parts: [String] = []
        if let s = item.size, !s.isEmpty { parts.append(s) }
        if let c = item.condition, !c.isEmpty { parts.append(c) }
        if let w = item.added_by, !w.isEmpty { parts.append("par \(w)") }
        if item.id.hasPrefix("local-") { parts.append("en attente d'envoi") }
        if item.status == "stock", let a = PpStale.age(item), a >= PpStale.days {
            parts.append("invendu depuis \(a) j")
        }
        return parts.joined(separator: " · ")
    }
    
    var priceLine: String {
        if item.status == "vendu" {
            let profit = (item.sold ?? 0) - (item.buy ?? 0)
            return "Vendu \(ppEur(item.sold ?? 0)) · bénéfice \(ppEur(profit))"
        }
        return "Acheté \(ppEur(item.buy ?? 0)) · revente \(ppEur(item.resale_low ?? 0))–\(ppEur(item.resale_high ?? 0))"
    }
}

// Liste des photos d'un article (anciens articles : une seule photo_url)
func ppPhotoURLs(_ item: PpItem) -> [String] {
    if let p = item.photos, !p.isEmpty { return p }
    if let u = item.photo_url, !u.isEmpty { return [u] }
    return []
}

struct PpGallery: View {
    let item: PpItem
    
    var urls: [String] {
        if let p = item.photos, !p.isEmpty { return p }
        if let u = item.photo_url, !u.isEmpty { return [u] }
        return []
    }
    
    var body: some View {
        if urls.count > 1 {
            TabView {
                ForEach(urls, id: \.self) { u in
                    PpRemoteImage(url: u, fill: false)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 340)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        } else {
            PpRemoteImage(url: urls.first, fill: false)
                .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}

struct PpItemDetail: View {
    @EnvironmentObject var store: PpStore
    @Environment(\.dismiss) var dismiss
    let itemId: String
    @State private var priceText = ""
    @State private var showEdit = false
    @State private var picker: [PhotosPickerItem] = []
    @State private var showCam = false
    @State private var photoBusy = false
    @State private var photoMsg = ""
    @State private var toRemove: Int? = nil
    
    var item: PpItem? { store.displayItems.first { $0.id == itemId } }
    
    private var removeBinding: Binding<Bool> {
        Binding(get: { toRemove != nil },
                set: { v in if !v { toRemove = nil } })
    }
    
    @ViewBuilder
    private var editSheet: some View {
        if let item = item {
            PpItemEditView(item: item)
                .environmentObject(store)
        }
    }
    
    private func resume(_ item: PpItem) -> String {
        let bas: String = ppEur(item.resale_low ?? 0)
        let haut: String = ppEur(item.resale_high ?? 0)
        let achat: String = ppEur(item.buy ?? 0)
        return "Revente estimée " + bas + "–" + haut + " · acheté " + achat
    }
    
    private func chargerPhotos() {
        Task {
            var imgs: [UIImage] = []
            for it in picker {
                if let d = try? await it.loadTransferable(type: Data.self),
                   let img = UIImage(data: d) {
                    imgs.append(img)
                }
            }
            picker = []
            addImages(imgs)
        }
    }
    
    var body: some View {
        ScrollView {
            if let item = item {
                content(item)
            }
        }
        .background(Color.ppCream.ignoresSafeArea())
        .onChange(of: picker) { _ in
            chargerPhotos()
        }
        .fullScreenCover(isPresented: $showCam) {
            PpCameraPicker { img in
                addImages([img])
            }
        }
        .confirmationDialog("Retirer cette photo ?",
                            isPresented: removeBinding,
                            titleVisibility: .visible,
                            presenting: toRemove) { idx in
            Button("Retirer", role: .destructive) { removePhoto(idx) }
        }
                            .sheet(isPresented: $showEdit) {
                                editSheet
                            }
                            .onAppear {
                                if let a = item?.resale_low {
                                    priceText = String(format: "%.0f", a)
                                }
                            }
    }
    
    private func content(_ item: PpItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            PpGallery(item: item)
            
            Text(item.name)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.ppPine)
            
            Text(resume(item))
                .font(.system(size: 13))
                .foregroundColor(.gray)
            
            Button("Modifier cette pièce") { showEdit = true }
                .buttonStyle(PpOutlineStyle())
            
            photoSection(item)
            
            actions(item)
            
            Button("Supprimer") { supprimer(item) }
                .buttonStyle(PpOutlineStyle(color: .red))
        }
        .padding(20)
    }
    
    @ViewBuilder
    private func actions(_ item: PpItem) -> some View {
        if item.id.hasPrefix("local-") {
            Text("En attente d'envoi : l'article sera ajouté au stock dès que la connexion reviendra. Tu pourras alors le marquer comme vendu.")
                .font(.system(size: 13))
                .foregroundColor(.orange)
        } else if item.status == "stock" {
            PpPriceRow(label: "Prix de vente", text: $priceText)
            Button("Marquer comme vendu") {
                var p = PpPatch()
                p.status = "vendu"
                p.sold = ppNum(priceText)
                p.sold_at = PpDate.now()
                queue(item.id, patch: p)
            }
            .buttonStyle(PpPrimaryStyle())
        } else {
            let profit: Double = (item.sold ?? 0) - (item.buy ?? 0)
            Text("Bénéfice réel : " + ppEur(profit))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.ppPine)
            Button("Remettre en vente") {
                var p = PpPatch()
                p.status = "stock"
                p.clearSold = true
                queue(item.id, patch: p)
            }
            .buttonStyle(PpOutlineStyle())
        }
    }
    
    private func photoSection(_ item: PpItem) -> some View {
        let urls = ppPhotoURLs(item)
        return VStack(alignment: .leading, spacing: 8) {
            Text("PHOTOS · \(urls.count)")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(.ppClay)
            if !urls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(urls.enumerated()), id: \.offset) { idx, u in
                            PpRemoteImage(url: u)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        toRemove = idx
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.black.opacity(0.5)))
                                    }
                                    .padding(3)
                                }
                        }
                    }
                }
            }
            if urls.count < 8 {
                HStack(spacing: 8) {
                    PhotosPicker(selection: $picker, maxSelectionCount: 8 - urls.count, matching: .images) {
                        Label("Ajouter des photos", systemImage: "photo.on.rectangle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.ppPine)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.ppPaper)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Button {
                        showCam = true
                    } label: {
                        Label("Photo", systemImage: "camera")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.ppPine)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.ppPaper)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            if photoBusy {
                ProgressView()
            }
            if !photoMsg.isEmpty {
                Text(photoMsg)
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }
        }
    }
    
    func addImages(_ imgs: [UIImage]) {
        guard let item = item else { return }
        var jpegs: [Data] = []
        for img in imgs {
            if let d = ppCompress(img) { jpegs.append(d) }
        }
        if jpegs.isEmpty { return }
        if item.id.hasPrefix("local-") {
            for j in jpegs { store.addPhotoPending(item.id, j) }
            return
        }
        photoBusy = true
        photoMsg = ""
        Task {
            var urls = ppPhotoURLs(item)
            do {
                for j in jpegs {
                    let u = try await PpAPI.uploadPhoto(j)
                    urls.append(u)
                }
                if let e = await store.setPhotos(itemId: item.id, urls: urls) {
                    photoMsg = e
                }
            } catch {
                if error is URLError {
                    photoMsg = "Pas de connexion : réessaie quand le réseau revient."
                } else {
                    photoMsg = error.localizedDescription
                }
            }
            photoBusy = false
        }
    }
    
    func removePhoto(_ idx: Int) {
        guard let item = item else { return }
        if item.id.hasPrefix("local-") {
            store.removePhotoPending(item.id, index: idx)
            return
        }
        var urls = ppPhotoURLs(item)
        guard idx < urls.count else { return }
        urls.remove(at: idx)
        photoBusy = true
        photoMsg = ""
        Task {
            if let e = await store.setPhotos(itemId: item.id, urls: urls) {
                photoMsg = e
            }
            photoBusy = false
        }
    }
    
    // Un article déjà enregistré va à la corbeille ; un article pas encore envoyé est effacé
    func supprimer(_ item: PpItem) {
        if item.id.hasPrefix("local-") {
            store.enqueue(itemId: item.id, delete: true)
        } else {
            var p = PpPatch()
            p.deleted_at = PpDate.now()
            store.enqueue(itemId: item.id, patch: p)
        }
        Task { await store.syncPending() }
        dismiss()
    }
    
    func queue(_ id: String, patch: PpPatch) {
        store.enqueue(itemId: id, patch: patch)
        Task { await store.syncPending() }
        dismiss()
    }
}

struct PpItemEditView: View {
    @EnvironmentObject var store: PpStore
    @Environment(\.dismiss) var dismiss
    let item: PpItem
    @State private var name = ""
    @State private var brand = ""
    @State private var size = ""
    @State private var cond = ""
    @State private var buy = ""
    @State private var low = ""
    @State private var high = ""
    @State private var loaded = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("MODIFIER LA PIÈCE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.ppClay)
                TextField("Nom de l'article", text: $name).ppField()
                TextField("Marque", text: $brand).ppField()
                TextField("Taille", text: $size).ppField()
                TextField("État", text: $cond).ppField()
                PpPriceRow(label: "Prix d'achat", text: $buy)
                PpPriceRow(label: "Revente estimée (bas)", text: $low)
                PpPriceRow(label: "Revente estimée (haut)", text: $high)
                Button("Enregistrer") { save() }
                    .buttonStyle(PpPrimaryStyle())
                Button("Annuler") { dismiss() }
                    .buttonStyle(PpOutlineStyle())
            }
            .padding(20)
        }
        .background(Color.ppCream.ignoresSafeArea())
        .onAppear {
            if !loaded {
                load()
                loaded = true
            }
        }
    }
    
    func fmt(_ v: Double?) -> String {
        guard let v = v else { return "" }
        return String(format: "%g", v)
    }
    
    func load() {
        name = item.name
        brand = item.brand ?? ""
        size = item.size ?? ""
        cond = item.condition ?? ""
        buy = fmt(item.buy)
        low = fmt(item.resale_low)
        high = fmt(item.resale_high)
    }
    
    func save() {
        let buyV = ppNum(buy)
        let lowV = ppNum(low)
        let highV = high.isEmpty ? lowV : ppNum(high)
        var p = PpPatch()
        p.name = name.isEmpty ? item.name : name
        if brand != (item.brand ?? "") { p.brand = brand }
        p.size = size
        p.condition = cond
        p.buy = buyV
        p.asked = buyV
        p.resale_low = lowV
        p.resale_high = highV
        p.score = ppScore(low: lowV, asked: buyV)
        store.enqueue(itemId: item.id, patch: p)
        Task { await store.syncPending() }
        dismiss()
    }
}

struct PpExtraPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Scanner

struct PpScannerTab: View {
    @EnvironmentObject var store: PpStore
    @Binding var tab: Int
    @State private var image: UIImage? = nil
    @State private var showCamera = false
    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var name = ""
    @State private var marque = ""
    @State private var typeArticle = ""
    @State private var couleur = ""
    @State private var size = ""
    @State private var cond = ""
    @State private var asked = ""
    @State private var low = ""
    @State private var high = ""
    @State private var busy = false
    @State private var msg = ""
    @State private var vintedBusy = false
    @State private var vintedResult: PpEstimation? = nil
    
    enum Champ: Hashable { case nom, marque, typeArt, couleur }
    @FocusState private var focus: Champ?
    // Dernières valeurs cohérentes entre elles (pour détecter ce qui a été modifié)
    @State private var syncNom = ""
    @State private var syncMarque = ""
    @State private var syncType = ""
    @State private var syncCouleur = ""
    @State private var reconEnCours = false
    @State private var extraImages: [PpExtraPhoto] = []
    @State private var extraPicker: [PhotosPickerItem] = []
    @State private var showCameraExtra = false
    
    var askedV: Double { ppNum(asked) }
    var lowV: Double { ppNum(low) }
    var highV: Double { high.isEmpty ? lowV : ppNum(high) }
    var score: Int { ppScore(low: lowV, asked: askedV) }
    var profit: Double { lowV - askedV - 2 }
    var maxPrice: Double { max(0, ((lowV - 2) * 0.45).rounded(.down)) }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("NOUVELLE PIÈCE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.ppClay)
                    Text("Un scan, une bonne affaire.")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.ppPine)
                    Text("Photographiez l'article. Gemini repère les détails et compare avec les annonces Vinted.")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    PpStatusBanner()
                    
                    photoArea
                    
                    Button {
                        showCamera = true
                    } label: {
                        Label("Prendre une photo", systemImage: "camera")
                    }
                    .buttonStyle(PpPrimaryStyle(color: .ppClay))
                    
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Choisir une photo", systemImage: "photo")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.ppPine)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.ppPaper)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.ppPine.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    if image != nil {
                        extraPhotosSection
                        
                        PpPriceRow(label: "Prix demandé", text: $asked)
                        
                        Button(busy ? "Analyse en cours…" : "Analyser avec Gemini") { analyze() }
                            .buttonStyle(PpPrimaryStyle())
                            .disabled(busy)
                        
                        TextField("Nom de l'article", text: $name)
                            .focused($focus, equals: .nom).ppField()
                        TextField("Marque", text: $marque)
                            .focused($focus, equals: .marque).ppField()
                        TextField("Type (ex : polaire, jean)", text: $typeArticle)
                            .focused($focus, equals: .typeArt).ppField()
                        TextField("Couleur", text: $couleur)
                            .focused($focus, equals: .couleur).ppField()
                        TextField("Taille", text: $size).ppField()
                        TextField("État", text: $cond).ppField()
                        PpPriceRow(label: "Revente estimée (bas)", text: $low)
                        PpPriceRow(label: "Revente estimée (haut)", text: $high)
                        
                        if lowV > 0 && askedV > 0 {
                            analysisCard
                        }
                        
                        if !name.isEmpty || !marque.isEmpty || !typeArticle.isEmpty {
                            Button(vintedBusy ? "Recherche sur Vinted…" : "Vérifier sur Vinted") { verifyVinted() }
                                .buttonStyle(PpOutlineStyle(color: .ppClay))
                                .disabled(vintedBusy || busy)
                            
                            if let e = vintedResult {
                                PpVintedResultView(est: e)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.ppPaper)
                                    .clipShape(RoundedRectangle(cornerRadius: 18))
                                
                                if e.fiable {
                                    Button("Appliquer les prix Vinted (décote 15 %)") {
                                        low = String(format: "%.0f", e.bas * PpVinted.decote)
                                        high = String(format: "%.0f", e.haut * PpVinted.decote)
                                    }
                                    .buttonStyle(PpPrimaryStyle())
                                }
                            }
                        }
                        
                        Button("Ajouter au stock · acheté \(ppEur(askedV))") { save() }
                            .buttonStyle(PpPrimaryStyle())
                            .disabled(busy)
                    }
                    
                    if !msg.isEmpty {
                        Text(msg)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(20)
            }
            .background(Color.ppCream.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showCamera) {
                PpCameraPicker { img in
                    image = img
                    msg = ""
                }
            }
            .onChange(of: focus) { _ in
                Task { await reconcilier() }
            }
            .onChange(of: extraPicker) { _ in
                Task {
                    for it in extraPicker {
                        if extraImages.count >= 4 { break }
                        if let data = try? await it.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            extraImages.append(PpExtraPhoto(image: img))
                        }
                    }
                    extraPicker = []
                }
            }
            .onChange(of: pickerItem) { _ in
                Task {
                    if let data = try? await pickerItem?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        image = img
                        msg = ""
                    }
                }
            }
        }
    }
    
    private var extraPhotosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !extraImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(extraImages) { ph in
                            Image(uiImage: ph.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        extraImages.removeAll { $0.id == ph.id }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.black.opacity(0.5)))
                                    }
                                    .padding(3)
                                }
                        }
                    }
                }
            }
            if extraImages.count < 4 {
                HStack(spacing: 8) {
                    PhotosPicker(selection: $extraPicker, maxSelectionCount: 4, matching: .images) {
                        Label("Autres photos", systemImage: "photo.on.rectangle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.ppPine)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.ppPaper)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    Button {
                        showCameraExtra = true
                    } label: {
                        Label("Photo", systemImage: "camera")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.ppPine)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.ppPaper)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCameraExtra) {
            PpCameraPicker { img in
                if extraImages.count < 4 { extraImages.append(PpExtraPhoto(image: img)) }
            }
        }
    }
    
    private var photoArea: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "camera")
                        .font(.system(size: 26))
                        .foregroundColor(.ppPine)
                        .frame(width: 64, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.ppPine.opacity(0.6), lineWidth: 1)
                        )
                    Text("Cadrez une seule pièce.")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.ppPine)
                    Text("Montrez le logo et l'étiquette si possible.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color.ppSage.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.ppPine.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }
    
    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(ppVerdict(score).0)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ppVerdict(score).1)
                Spacer()
                Text("\(score)/100")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ppVerdict(score).1)
            }
            Text("Prix max conseillé : \(ppEur(maxPrice))")
                .font(.system(size: 13))
                .foregroundColor(.ppPine)
            Text(profit > 0 ? "Bénéfice potentiel : ~\(ppEur(profit))" : "Aucun bénéfice estimé")
                .font(.system(size: 13))
                .foregroundColor(.ppPine)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppPaper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    func net(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    // Cherche un mot entier (sans tenir compte des majuscules) dans un texte
    func trouver(_ texte: String, _ mot: String) -> Range<String.Index>? {
        let m = net(mot)
        guard !m.isEmpty else { return nil }
        return texte.range(of: "\\b" + NSRegularExpression.escapedPattern(for: m) + "\\b",
                           options: [.regularExpression, .caseInsensitive])
    }
    
    static let couleursConnues = [
        "noir", "blanc", "gris", "bleu", "rouge", "vert", "jaune", "orange", "rose",
        "violet", "marron", "beige", "bordeaux", "kaki", "marine", "crème", "creme",
        "doré", "argenté", "turquoise", "multicolore"
    ]
    
    // Première couleur connue écrite dans le nom, telle que tu l'as écrite
    func couleurDansNom(_ texte: String) -> String? {
        var meilleure: (String, String.Index)? = nil
        for c in Self.couleursConnues {
            if let r = trouver(texte, c), meilleure == nil || r.lowerBound < meilleure!.1 {
                meilleure = (String(texte[r]), r.lowerBound)
            }
        }
        return meilleure?.0
    }
    
    // Garde le nom, la marque, le type et la couleur cohérents entre eux
    func reconcilier() async {
        if reconEnCours { return }
        reconEnCours = true
        defer { reconEnCours = false }
        
        let nomModifie = net(name) != net(syncNom)
        let marqueModif = net(marque) != net(syncMarque)
        let typeModif = net(typeArticle) != net(syncType)
        let couleurModif = net(couleur) != net(syncCouleur)
        guard nomModifie || marqueModif || typeModif || couleurModif else { return }
        
        var infos: [String] = []
        var echec = false
        
        // 1. Le nom a changé : on relit les champs que tu n'as pas touchés
        //    et dont l'ancienne valeur n'apparaît plus dans le nom
        if nomModifie && !net(name).isEmpty {
            // Couleur : lue directement dans le nom, sans appel à Gemini
            if !couleurModif, let c = couleurDansNom(name),
               c.caseInsensitiveCompare(net(couleur)) != .orderedSame {
                infos.append("couleur → \(c)")
                couleur = c
            }
            func aRevoir(_ valeur: String, _ modif: Bool) -> Bool {
                !modif && (net(valeur).isEmpty || trouver(name, valeur) == nil)
            }
            if aRevoir(marque, marqueModif) || aRevoir(typeArticle, typeModif) || aRevoir(couleur, couleurModif) {
                if let r = try? await PpGemini.extraireDuNom(name) {
                    func proposition(_ p: String?, _ actuel: String, _ modif: Bool) -> String? {
                        guard aRevoir(actuel, modif), let p = p else { return nil }
                        let v = PpVinted.nettoyer(p)
                        if v.isEmpty || v.caseInsensitiveCompare(net(actuel)) == .orderedSame { return nil }
                        return v
                    }
                    if let v = proposition(r.marque, marque, marqueModif) {
                        infos.append("marque → \(v)")
                        marque = v
                    }
                    if let v = proposition(r.type, typeArticle, typeModif) {
                        infos.append("type → \(v)")
                        typeArticle = v
                    }
                    if let v = proposition(r.couleur, couleur, couleurModif) {
                        infos.append("couleur → \(v)")
                        couleur = v
                    }
                } else {
                    echec = true
                    msg = "Relecture du nom par Gemini impossible (clé ou connexion) : marque et type non mis à jour."
                }
            }
        }
        
        // 2. Un champ a changé : on remplace l'ancienne valeur dans le nom
        func remplacer(_ ancien: String, _ nouveau: String) {
            let n = net(nouveau)
            guard !n.isEmpty, let r = trouver(name, ancien) else { return }
            let avant = String(name[r])
            name.replaceSubrange(r, with: n)
            infos.append("nom : \(avant) → \(n)")
        }
        if marqueModif { remplacer(syncMarque, marque) }
        if typeModif { remplacer(syncType, typeArticle) }
        if couleurModif { remplacer(syncCouleur, couleur) }
        
        syncMarque = marque
        syncType = typeArticle
        syncCouleur = couleur
        if !echec { syncNom = name }
        if !infos.isEmpty { msg = "Mis à jour : " + infos.joined(separator: " · ") }
    }
    
    func analyze() {
        guard let img = image, let jpeg = ppCompress(img) else {
            msg = "Prends d'abord une photo."
            return
        }
        busy = true
        vintedResult = nil
        msg = "Analyse en cours…"
        Task {
            do {
                let a = try await PpGemini.analyze(jpeg)
                name = a.nom ?? name
                marque = a.marque ?? marque
                typeArticle = a.type ?? typeArticle
                couleur = a.couleur ?? couleur
                size = a.taille ?? size
                cond = a.etat ?? cond
                syncNom = name
                syncMarque = marque
                syncType = typeArticle
                syncCouleur = couleur
                let n = a.nb_annonces ?? 0
                if a.source == "estimation" {
                    if let b = a.revente_bas { low = String(format: "%.0f", b) }
                    if let h = a.revente_haut { high = String(format: "%.0f", h) }
                    msg = "Recherche Google indisponible (\(a.commentaire ?? "")). Prix = estimation de Gemini, pas des annonces Vinted : appuie sur « Vérifier sur Vinted »."
                } else if n > 0 {
                    if let b = a.revente_bas { low = String(format: "%.0f", b) }
                    if let h = a.revente_haut { high = String(format: "%.0f", h) }
                    msg = "Prix de départ basés sur \(n) annonce\(n > 1 ? "s" : "") trouvée\(n > 1 ? "s" : "") par Gemini. Appuie sur « Vérifier sur Vinted » pour les confirmer. \(a.commentaire ?? "")"
                } else {
                    msg = "Aucune annonce comparable trouvée par Gemini : appuie sur « Vérifier sur Vinted » ou saisis la revente toi-même."
                }
            } catch {
                if error is URLError {
                    msg = "Pas de connexion : remplis les champs et les prix à la main, l'article sera envoyé dès que le réseau reviendra."
                } else {
                    msg = error.localizedDescription
                }
            }
            busy = false
        }
    }
    
    func verifyVinted() {
        vintedBusy = true
        vintedResult = nil
        Task {
            // On s'assure que nom, marque, type et couleur sont cohérents avant de chercher
            while reconEnCours { try? await Task.sleep(nanoseconds: 100_000_000) }
            await reconcilier()
            let m = marque, c = couleur, s = size
            // Si Gemini n'a donné ni marque ni type, on cherche avec le nom complet
            let t = (typeArticle.isEmpty && marque.isEmpty) ? name : typeArticle
            let e = await PpVinted.estimer(marque: m, type: t, couleur: c, taille: s)
            vintedResult = e
            vintedBusy = false
        }
    }
    
    func save() {
        guard let img = image, let jpeg = ppCompress(img), let team = store.team else {
            msg = "Prends d'abord une photo."
            return
        }
        busy = true
        msg = "Enregistrement…"
        Task {
            while reconEnCours { try? await Task.sleep(nanoseconds: 100_000_000) }
            await reconcilier()
            // L'article est d'abord gardé sur l'appareil, puis envoyé dès que le réseau le permet
            let jpegs = [jpeg] + extraImages.compactMap { ppCompress($0.image) }
            store.addPending(teamId: team.id, name: name.isEmpty ? "Article" : name,
                             brand: net(marque), size: size, condition: cond,
                             asked: askedV, low: lowV, high: highV, score: score,
                             jpegs: jpegs)
            image = nil
            extraImages = []
            name = ""; marque = ""; typeArticle = ""; couleur = ""
            syncNom = ""; syncMarque = ""; syncType = ""; syncCouleur = ""
            size = ""; cond = ""; asked = ""; low = ""; high = ""
            msg = ""
            vintedResult = nil
            tab = 0
            Task { await store.syncPending() }
            busy = false
        }
    }
}

// MARK: - Équipe

struct PpTeamTab: View {
    @EnvironmentObject var store: PpStore
    @AppStorage("gem_model") private var gemModel = "gemini-3.5-flash-lite"
    @AppStorage("who") private var who = ""
    @AppStorage("stale_days") private var staleDays = 30
    @State private var sharedKey = ""
    @State private var keyMsg = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("VOTRE ÉQUIPE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.ppClay)
                    Text("Un vestiaire à deux.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.ppPine)
                    
                    teamCard
                    accountCard
                    trashCard
                    staleSettings
                    settingsCard
                }
                .padding(20)
            }
            .background(Color.ppCream.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private var teamCard: some View {
        let code = store.team?.invite_code ?? ""
        return VStack(alignment: .leading, spacing: 10) {
            Text("ESPACE PARTAGÉ")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.7))
            Text(store.team?.name ?? "")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Divider().background(Color.white.opacity(0.3))
            Text("CODE D'INVITATION")
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.7))
            Text(code)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            ShareLink(item: "Rejoins mon espace PÉPITE : crée un compte dans l'appli, puis saisis ce code d'invitation : \(code)") {
                Label("Inviter mon binôme", systemImage: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.ppPine)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.ppPaper)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Text("\(store.members)/2 membres")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppPine)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Votre compte")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.ppPine)
            Text(store.email)
                .font(.system(size: 12))
                .foregroundColor(.gray)
            Divider()
            HStack(spacing: 6) {
                Image(systemName: "lock").font(.system(size: 11))
                Text("Stock privé, protégé par les règles d'accès de Supabase.")
                    .font(.system(size: 11))
            }
            .foregroundColor(.gray)
            Button("Se déconnecter") { store.signOut() }
                .buttonStyle(PpOutlineStyle(color: .red))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppPaper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private var settingsCard: some View {
        let hasShared = !(store.team?.gemini_key ?? "").isEmpty
        return VStack(alignment: .leading, spacing: 10) {
            Text("Analyse des photos (Gemini)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.ppPine)
            
            if hasShared {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("Clé partagée avec votre équipe : rien à saisir sur l'autre téléphone.")
                        .font(.system(size: 12))
                        .foregroundColor(.ppPine)
                }
            }
            
            SecureField(hasShared ? "Remplacer la clé partagée" : "Clé API Gemini de l'équipe", text: $sharedKey)
                .ppField()
            Button("Enregistrer pour l'équipe") { saveSharedKey() }
                .buttonStyle(PpPrimaryStyle())
            if !keyMsg.isEmpty {
                Text(keyMsg)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            Text("Réglages de l'appareil")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.ppPine)
            TextField("Ton prénom", text: $who).ppField()
            TextField("Modèle Gemini", text: $gemModel)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .ppField()
            Text("La clé partagée est lue par vous deux. Seuls les membres de l'espace y ont accès.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppPaper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private var trashCard: some View {
        NavigationLink {
            PpTrashView()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "trash")
                    .foregroundColor(.ppPine)
                Text("Corbeille")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.ppPine)
                Spacer()
                Text("\(store.trashItems.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.gray)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.ppPaper)
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }
    
    private var staleSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Alerte articles invendus")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.ppPine)
            Stepper("Après \(staleDays) jours en stock", value: $staleDays, in: 7...180, step: 7)
                .font(.system(size: 13))
                .foregroundColor(.ppPine)
            Text("Un badge apparaît sur l'onglet Stock et une carte « À relancer » en haut de la liste.")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppPaper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private func saveSharedKey() {
        let k = sharedKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty else {
            keyMsg = "Colle d'abord la clé."
            return
        }
        keyMsg = "Enregistrement…"
        Task {
            do {
                _ = try await PpAPI.rpc("set_team_gemini_key", ["new_key": k])
                sharedKey = ""
                await store.refreshAll()
                keyMsg = "Clé enregistrée pour l'équipe."
            } catch {
                keyMsg = error.localizedDescription
            }
        }
    }
}

// MARK: - Corbeille

struct PpTrashView: View {
    @EnvironmentObject var store: PpStore
    @State private var toPurge: PpItem? = nil
    @State private var confirmEmpty = false
    
    private var purgeBinding: Binding<Bool> {
        Binding(get: { toPurge != nil },
                set: { v in if !v { toPurge = nil } })
    }
    
    func joursDepuis(_ i: PpItem) -> Int {
        guard let d = PpDate.parse(i.deleted_at) else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: d, to: Date()).day ?? 0)
    }
    
    func restaurer(_ it: PpItem) {
        var p = PpPatch()
        p.clearDeleted = true
        store.enqueue(itemId: it.id, patch: p)
        Task { await store.syncPending() }
    }
    
    func supprimerPourDeBon(_ it: PpItem) {
        store.enqueue(itemId: it.id, delete: true)
        Task { await store.syncPending() }
    }
    
    func toutSupprimer() {
        for it in store.trashItems {
            store.enqueue(itemId: it.id, delete: true)
        }
        Task { await store.syncPending() }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("CORBEILLE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.ppClay)
                Text("Les articles supprimés restent ici 30 jours, puis disparaissent pour de bon.")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
                if store.trashItems.isEmpty {
                    Text("La corbeille est vide.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.ppPine)
                        .padding(.top, 8)
                } else {
                    ForEach(store.trashItems) { it in
                        row(it)
                    }
                    Button("Vider la corbeille") { confirmEmpty = true }
                        .buttonStyle(PpOutlineStyle(color: .red))
                }
            }
            .padding(20)
        }
        .background(Color.ppCream.ignoresSafeArea())
        .navigationTitle("Corbeille")
        .confirmationDialog("Supprimer définitivement ?",
                            isPresented: purgeBinding,
                            titleVisibility: .visible,
                            presenting: toPurge) { it in
            Button("Supprimer définitivement", role: .destructive) { supprimerPourDeBon(it) }
        }
                            .confirmationDialog("Vider la corbeille ?",
                                                isPresented: $confirmEmpty,
                                                titleVisibility: .visible) {
                                Button("Tout supprimer définitivement", role: .destructive) { toutSupprimer() }
                            }
    }
    
    private func row(_ it: PpItem) -> some View {
        let j: Int = joursDepuis(it)
        let reste: Int = max(0, 30 - j)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                PpRemoteImage(url: it.photo_url)
                    .frame(width: 52, height: 62)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(it.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.ppPine)
                        .lineLimit(2)
                    Text("Supprimé il y a \(j) j · encore \(reste) j")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                Button("Restaurer") { restaurer(it) }
                    .buttonStyle(PpPrimaryStyle())
                Button("Supprimer") { toPurge = it }
                    .buttonStyle(PpOutlineStyle(color: .red))
            }
        }
        .padding(12)
        .background(Color.ppPaper)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Copier le stock (à coller dans Excel, Numbers, Notes…)

enum PpCSV {
    // Colonnes séparées par des tabulations : coller dans un tableur remplit directement les cellules
    static func champ(_ s: String) -> String {
        s.replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
    }
    
    static func nombre(_ v: Double?) -> String {
        guard let v = v else { return "" }
        return String(format: "%g", v).replacingOccurrences(of: ".", with: ",")
    }
    
    static func date(_ s: String?) -> String {
        guard let d = PpDate.parse(s) else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "dd/MM/yyyy"
        return f.string(from: d)
    }
    
    static func texte(_ items: [PpItem]) -> String {
        let entete: String = "Nom\tMarque\tTaille\tÉtat\tStatut\tPrix d'achat\tRevente bas\tRevente haut\tPrix de vente\tBénéfice réel\tMarge potentielle\tScore\tAjouté par\tDate d'ajout\tDate de vente\tJours en stock"
        var lignes: [String] = [entete]
        for i in items {
            let vendu: Bool = (i.status == "vendu")
            let achat: Double = i.buy ?? 0
            
            var jours = ""
            let fin: Date? = vendu ? PpDate.parse(i.sold_at) : Date()
            if let c = PpDate.parse(i.created_at), let f = fin {
                let secondes: Double = f.timeIntervalSince(c)
                jours = String(max(0, Int(secondes / 86400)))
            }
            
            var statut = "En stock"
            var prixVente = ""
            var reel = ""
            var potentiel = ""
            if vendu {
                statut = "Vendu"
                prixVente = nombre(i.sold)
                reel = nombre((i.sold ?? 0) - achat)
            } else {
                potentiel = nombre((i.resale_low ?? 0) - achat)
            }
            
            var score = ""
            if let sc = i.score { score = String(sc) }
            
            var cols: [String] = []
            cols.append(champ(i.name))
            cols.append(champ(i.brand ?? ""))
            cols.append(champ(i.size ?? ""))
            cols.append(champ(i.condition ?? ""))
            cols.append(statut)
            cols.append(nombre(i.buy))
            cols.append(nombre(i.resale_low))
            cols.append(nombre(i.resale_high))
            cols.append(prixVente)
            cols.append(reel)
            cols.append(potentiel)
            cols.append(score)
            cols.append(champ(i.added_by ?? ""))
            cols.append(date(i.created_at))
            cols.append(date(i.sold_at))
            cols.append(jours)
            lignes.append(cols.joined(separator: "\t"))
        }
        return lignes.joined(separator: "\n")
    }
}

// MARK: - Alerte articles invendus

enum PpStale {
    static var days: Int {
        let d = UserDefaults.standard.integer(forKey: "stale_days")
        return d > 0 ? d : 30
    }
    
    // Nombre de jours depuis l'ajout au stock (nil pour un article pas encore envoyé)
    static func age(_ i: PpItem) -> Int? {
        guard let c = PpDate.parse(i.created_at) else { return nil }
        return max(0, Calendar.current.dateComponents([.day], from: c, to: Date()).day ?? 0)
    }
    
    static func list(_ items: [PpItem], days: Int) -> [PpItem] {
        items.filter { $0.status == "stock" && (age($0) ?? 0) >= days }
            .sorted { (age($0) ?? 0) > (age($1) ?? 0) }
    }
}

// MARK: - Statistiques

enum PpDate {
    // Lit une date Supabase (avec ou sans fractions de seconde)
    static func parse(_ s: String?) -> Date? {
        guard var t = s, !t.isEmpty else { return nil }
        if let r = t.range(of: "\\.\\d+", options: .regularExpression) {
            t.removeSubrange(r)
        }
        return ISO8601DateFormatter().date(from: t)
    }
    static func now() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}

struct PpStatLine: Identifiable {
    let id: String
    let label: String
    let profit: Double
    let count: Int
}

struct PpStatsView: View {
    @EnvironmentObject var store: PpStore
    
    var sold: [PpItem] { store.displayItems.filter { $0.status == "vendu" } }
    
    func profit(_ i: PpItem) -> Double { (i.sold ?? 0) - (i.buy ?? 0) }
    
    // Date de vente ; pour les anciennes ventes sans date, on prend la date d'ajout
    func saleDate(_ i: PpItem) -> Date? {
        PpDate.parse(i.sold_at) ?? PpDate.parse(i.created_at)
    }
    
    var totalProfit: Double { sold.reduce(0) { $0 + profit($1) } }
    var averageProfit: Double { sold.isEmpty ? 0 : totalProfit / Double(sold.count) }
    
    // Délai moyen entre l'ajout et la vente (uniquement les ventes qui ont une date de vente)
    var averageDelay: Double? {
        var jours: [Double] = []
        for i in sold {
            guard let s = PpDate.parse(i.sold_at), let c = PpDate.parse(i.created_at) else { continue }
            jours.append(max(0, s.timeIntervalSince(c) / 86400))
        }
        guard !jours.isEmpty else { return nil }
        return jours.reduce(0, +) / Double(jours.count)
    }
    
    var months: [PpStatLine] {
        let cal = Calendar.current
        var acc: [Date: (Double, Int)] = [:]
        for i in sold {
            guard let d = saleDate(i),
                  let m = cal.date(from: cal.dateComponents([.year, .month], from: d)) else { continue }
            let cur = acc[m] ?? (0, 0)
            acc[m] = (cur.0 + profit(i), cur.1 + 1)
        }
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "LLLL yyyy"
        return acc.keys.sorted(by: >).prefix(6).map { m in
            let v = acc[m] ?? (0, 0)
            let label = f.string(from: m).capitalized
            return PpStatLine(id: label, label: label, profit: v.0, count: v.1)
        }
    }
    
    var brands: [PpStatLine] {
        var acc: [String: (String, Double, Int)] = [:]
        for i in sold {
            let b = (i.brand ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let key = b.isEmpty ? "—" : b.lowercased()
            let label = b.isEmpty ? "Sans marque" : b
            let cur = acc[key] ?? (label, 0, 0)
            acc[key] = (cur.0, cur.1 + profit(i), cur.2 + 1)
        }
        return acc.map { PpStatLine(id: $0.key, label: $0.value.0, profit: $0.value.1, count: $0.value.2) }
            .sorted { $0.profit > $1.profit }
            .prefix(8)
            .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("VOS CHIFFRES")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.ppClay)
                    Text("Ce qui se vend vraiment.")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.ppPine)
                    
                    PpStatusBanner()
                    
                    if sold.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 20))
                                .foregroundColor(.ppPine)
                                .frame(width: 48, height: 48)
                                .background(Color.ppSage)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            Text("Pas encore de vente.")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.ppPine)
                            Text("Marquez une pièce comme vendue : les statistiques apparaissent ici.")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.ppPaper)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                    } else {
                        totalCard
                        HStack(spacing: 10) {
                            smallCard("VENDUS", "\(sold.count)")
                            smallCard("MOYENNE / PIÈCE", ppEur(averageProfit))
                            smallCard("DÉLAI MOYEN", averageDelay.map { String(format: "%.1f j", $0) } ?? "—")
                        }
                        if averageDelay == nil {
                            Text("Le délai moyen apparaîtra dès la prochaine vente enregistrée.")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        section("Bénéfice par mois", months)
                        section("Bénéfice par marque", brands)
                    }
                }
                .padding(20)
            }
            .refreshable {
                await store.refreshAll()
                await store.syncPending()
            }
            .background(Color.ppCream.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BÉNÉFICE RÉEL TOTAL")
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.7))
            Text(ppEur(totalProfit))
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppPine)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
    
    private func smallCard(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .tracking(1)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.ppPine)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppPaper)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func section(_ title: String, _ lines: [PpStatLine]) -> some View {
        let maxV = max(1, lines.map { abs($0.profit) }.max() ?? 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.ppPine)
            if lines.isEmpty {
                Text("Pas encore de données.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            ForEach(lines) { l in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(l.label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.ppPine)
                        Spacer()
                        Text("\(ppEur(l.profit)) · \(l.count) vendu\(l.count > 1 ? "s" : "")")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.ppSage)
                            Capsule()
                                .fill(l.profit >= 0 ? Color.ppPine : Color.red)
                                .frame(width: max(4, g.size.width * CGFloat(abs(l.profit) / maxV)))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ppPaper)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

