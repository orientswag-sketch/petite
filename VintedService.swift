import SwiftUI

struct AnnonceVinted: Identifiable {
    let id: String
    let titre: String
    let marque: String
    let etat: String
    let taille: String
    let prix: Double
    let lien: String
}

struct EstimationVinted {
    var annonces: [AnnonceVinted] = []
    var nbLues = 0
    var bas = 0.0
    var mediane = 0.0
    var haut = 0.0
    var venteProbable = 0.0
    var requete = ""
    var fiable = false
    var message = ""
}

enum VintedService {
    static let agent = "Mozilla/5.0 (iPad; CPU OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    
    static func estimer(marque: String, type: String, couleur: String, taille: String) async -> EstimationVinted {
        let m = nettoyer(marque)
        var requetes: [String] = []
        for mots in [[m, nettoyer(type), nettoyer(couleur)], [m, nettoyer(type)]] {
            let q = mots.filter { !$0.isEmpty }.joined(separator: " ")
            if !q.isEmpty && !requetes.contains(q) { requetes.append(q) }
        }
        if requetes.isEmpty { return EstimationVinted(message: "Pas assez d'infos pour chercher.") }
        
        var repondu = false
        var meilleur = EstimationVinted()
        for q in requetes {
            guard let brutes = await recuperer(requete: q) else { continue }
            repondu = true
            var liste = brutes
            if !m.isEmpty { liste = liste.filter { $0.marque.localizedCaseInsensitiveContains(m) } }
            let t = taille.trimmingCharacters(in: .whitespaces)
            if !t.isEmpty {
                let memeTaille = liste.filter { $0.taille.caseInsensitiveCompare(t) == .orderedSame }
                if memeTaille.count >= 5 { liste = memeTaille }
            }
            var est = calculer(liste)
            est.requete = q
            est.nbLues = brutes.count
            if est.fiable { return est }
            meilleur = est
        }
        if !repondu { return EstimationVinted(message: "Vinted n'a pas répondu : estimation non fiable.") }
        return meilleur
    }
    
    static func nettoyer(_ s: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        let vides = ["—", "-", "?", "inconnu", "inconnue", "n/a", "aucune", "sans marque"]
        return vides.contains(t.lowercased()) ? "" : t
    }
    
    static func calculer(_ liste: [AnnonceVinted]) -> EstimationVinted {
        var e = EstimationVinted()
        e.annonces = liste
        guard liste.count >= 5 else {
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
        e.venteProbable = e.mediane * 0.85
        e.fiable = true
        return e
    }
    
    static func recuperer(requete: String) async -> [AnnonceVinted]? {
        var comps = URLComponents(string: "https://www.vinted.fr/catalog")!
        comps.queryItems = [URLQueryItem(name: "search_text", value: requete)]
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
    
    static func lire(_ html: String) -> [AnnonceVinted] {
        let motifLien = #"href="/items/(\d+)-([^"?]*)\?referrer=catalog"[^>]*?title="([^"]*)""#
        let motifTitre = #"^(.*?)(?:, Marque: (.*?))?(?:, État: (.*?))?(?:, Taille: (.*?))?, (\d+(?:[.,]\d+)?) €(?:, (\d+(?:[.,]\d+)?) €)?$"#
        guard let reLien = try? NSRegularExpression(pattern: motifLien),
              let reTitre = try? NSRegularExpression(pattern: motifTitre) else { return [] }
        let ns = html as NSString
        var vues = Set<String>()
        var sortie: [AnnonceVinted] = []
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
            sortie.append(AnnonceVinted(id: id, titre: champ(1), marque: champ(2), etat: champ(3),
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

struct VintedResultatView: View {
    let est: EstimationVinted
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if est.fiable {
                Text("Vente probable : ~\(Int(est.venteProbable.rounded())) €")
                    .font(.headline)
                Text(String(format: "Annonces comparables : %.0f – %.0f € (médiane %.0f €)", est.bas, est.haut, est.mediane))
                    .font(.subheadline)
                Text("\(est.annonces.count) annonces retenues · recherche « \(est.requete) »")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(est.annonces.prefix(5)) { a in
                    if let url = URL(string: a.lien) {
                        Link("\(Int(a.prix)) € · \(a.titre)", destination: url)
                            .font(.caption).lineLimit(1)
                    }
                }
            } else {
                Text(est.message).font(.subheadline).foregroundStyle(.orange)
            }
        }
    }
}


