import SwiftUI
import Combine

@MainActor
class GameState: ObservableObject {

    // MARK: - Player
    @Published var playerName: String = ""
    @Published var selectedDetective: String = "detectiveOne"

    // MARK: - Published
    @Published var currentAct: GameAct = .investigation
    @Published var collectedEvidence: [Evidence] = []
    @Published var suspects: [Suspect] = []
    @Published var unlockedDialogue: [DialogueNode] = []
    @Published var evidenceConnections: [EvidenceConnection] = []
    @Published var gameCompleted: Bool = false
    @Published var caseScore: Int = 0
    @Published var reportChoices: [String: Bool] = [:]  // active omission mechanic

    // Act-specific
    @Published var searchedAreas: Set<String> = []
    @Published var suspectCooperationLevel: Int = 5
    @Published var analysisResults: [String: String] = [:]

    // MARK: - Computed
    var realEvidenceCount: Int   { collectedEvidence.filter(\.isRealEvidence).count }
    var totalEvidenceFound: Int  { collectedEvidence.count }
    var correctConnectionsCount: Int { evidenceConnections.filter(\.isCorrect).count }

    var canProgressToNextAct: Bool {
        switch currentAct {
        case .investigation:  return realEvidenceCount >= 3
        case .interrogation:  return unlockedDialogue.count >= 2
        case .analysis:       return analysisResults.count >= 2 && correctConnectionsCount >= 2
        case .confrontation:  return false  // ends game
        }
    }

    // MARK: - Init
    init() {
        setupSuspects()
    }

    // MARK: - Evidence
    func addEvidence(_ evidence: Evidence) {
        guard !collectedEvidence.contains(where: { $0.id == evidence.id }) else { return }
        collectedEvidence.append(evidence)
        checkForUnlockedDialogue()
        calculateScore()
    }

    func hasEvidence(named name: String) -> Bool {
        collectedEvidence.contains { $0.name == name }
    }

    func getEvidence(by id: UUID) -> Evidence? {
        collectedEvidence.first { $0.id == id }
    }

    // MARK: - Areas (Act 1)
    func markAreaAsSearched(_ name: String) { searchedAreas.insert(name) }
    func isAreaSearched(_ name: String) -> Bool { searchedAreas.contains(name) }

    // MARK: - Dialogue (Act 2)
    func unlockDialogueNode(_ node: DialogueNode) {
        guard !unlockedDialogue.contains(where: { $0.id == node.id }) else { return }
        unlockedDialogue.append(node)
    }

    func updateSuspectCooperation(by change: Int) {
        suspectCooperationLevel = max(1, min(10, suspectCooperationLevel + change))
    }

    // MARK: - Analysis (Act 3)
    func performAnalysis(evidenceID: UUID, tool: AnalysisTool) -> String? {
        guard let evidence = getEvidence(by: evidenceID) else { return nil }
        let result = getAnalysisResult(evidence: evidence, tool: tool)
        guard !result.isEmpty else { return nil }
        analysisResults[evidenceID.uuidString] = result
        calculateScore()
        return result
    }

    // MARK: - Connections (Act 3)
    func createConnection(evidence1ID: UUID, evidence2ID: UUID,
                          type: EvidenceConnection.ConnectionType) {
        let correct = validateConnection(e1: evidence1ID, e2: evidence2ID, type: type)
        evidenceConnections.append(
            EvidenceConnection(evidence1ID: evidence1ID, evidence2ID: evidence2ID,
                               connectionType: type, isCorrect: correct)
        )
        calculateScore()
    }

    func removeConnection(_ connection: EvidenceConnection) {
        evidenceConnections.removeAll { $0.id == connection.id }
        calculateScore()
    }

    // MARK: - Report (Act 4) — active omission
    func setReportInclusion(evidenceName: String, included: Bool) {
        reportChoices[evidenceName] = included
    }

    func isIncludedInReport(_ evidenceName: String) -> Bool {
        reportChoices[evidenceName] ?? true
    }

    // MARK: - Progression
    func progressToNextAct() {
        guard canProgressToNextAct else { return }
        if let next = GameAct(rawValue: currentAct.rawValue + 1) {
            currentAct = next
        }
    }

    func jumpToAct(_ act: GameAct) { currentAct = act }

    func completeGame() {
        calculateFinalScore()
        gameCompleted = true
    }

    func resetGame() {
        currentAct = .investigation
        collectedEvidence.removeAll()
        searchedAreas.removeAll()
        unlockedDialogue.removeAll()
        evidenceConnections.removeAll()
        analysisResults.removeAll()
        reportChoices.removeAll()
        suspectCooperationLevel = 5
        gameCompleted = false
        caseScore = 0
        setupSuspects()
    }

    // MARK: - Private
    private func setupSuspects() {
        suspects = [
            Suspect(name: "Dr. Victor Kazmir",
                    description: "Head surgeon. Performed Wayne's surgery. Pronounced him dead.",
                    suspicionLevel: 6, isUnlocked: true,
                    portraitImage: "prisonSurgeon"),
            Suspect(name: "Kathy Williams",
                    description: "Wayne's nurse. Found him unconscious before surgery.",
                    suspicionLevel: 5, isUnlocked: false,
                    portraitImage: "prisonNurse"),
            Suspect(name: "Jason Perry",
                    description: "Prison security. On duty that night. Evasive about the footage.",
                    suspicionLevel: 7, isUnlocked: false,
                    portraitImage: "prisonGuard"),
            Suspect(name: "Peter Simmons",
                    description: "Morgue worker. Handled Wayne's body after death.",
                    suspicionLevel: 4, isUnlocked: false,
                    portraitImage: "prisonMorgueWorker")
        ]
    }

    private func checkForUnlockedDialogue() {
        // Unlock Katya when Love Letter is found
        if hasEvidence(named: "Love Letter"),
           let i = suspects.firstIndex(where: { $0.name == "Kathy Williams" }) {
            suspects[i].isUnlocked = true
        }
        // Unlock Doyle when Legal Documents found
        if hasEvidence(named: "Legal Documents"),
           let i = suspects.firstIndex(where: { $0.name == "Peter Simmons" }) {
            suspects[i].isUnlocked = true
        }
        // Unlock Jenkins when any footage/security evidence found
        if hasEvidence(named: "Hospital ID Badge"),
           let i = suspects.firstIndex(where: { $0.name == "Jason Perry" }) {
            suspects[i].isUnlocked = true
        }
    }

    private func getAnalysisResult(evidence: Evidence, tool: AnalysisTool) -> String {
        let combinations: [String: [AnalysisTool: String]] = [
            "Bloody Glove": [
                .blood: "Type O-negative blood — matches victim's records.",
                .dna: "Unknown secondary DNA profile detected on inner surface.",
                .uv: "No additional markings visible under UV."
            ],
            "Hospital ID Badge": [
                .uv: "Photo layer shows tampering — original photo was replaced.",
                .fingerprint: "Multiple overlapping fingerprints detected."
            ],
            "Syringe": [
                .dna: "Traces of a paralytic agent confirmed. Consistent with surgical sedation.",
                .fingerprint: "Partial print on barrel — insufficient for ID alone."
            ],
            "Victim's Prison License": [
                .uv: "UV reveals erasure marks on the organ donor field — original text was scraped and rewritten.",
                .microscope: "Ink on the donor field is visibly different from the rest of the document.",
                .fingerprint: "Fingerprints on the card do not match the victim."
            ],
            "Original License Photo": [
                .microscope: "Consistent with standard intake processing — no signs of alteration.",
                .uv: "No hidden markings — appears authentic."
            ],
            "Love Letter": [
                .fingerprint: "Fingerprints match Kathy Williams from staff records.",
                .uv: "Faint tear stains visible — the letter was emotionally significant."
            ],
            "Legal Documents": [
                .microscope: "All signatures and stamps appear authentic.",
                .uv: "Standard government watermarks confirmed."
            ]
        ]
        return combinations[evidence.name]?[tool] ?? ""
    }

    private func validateConnection(e1: UUID, e2: UUID,
                                    type: EvidenceConnection.ConnectionType) -> Bool {
        guard let ev1 = getEvidence(by: e1),
              let ev2 = getEvidence(by: e2) else { return false }

        let correct: [(String, String, EvidenceConnection.ConnectionType)] = [
            ("Bloody Glove", "Syringe", .person),
            ("Hospital ID Badge", "Victim's Prison License", .method),
            ("Victim's Prison License", "Original License Photo", .method),
            ("Legal Documents", "Victim's Prison License", .motive),
            ("Love Letter", "Kathy Williams", .person),
            ("Victim's Prison License", "Legal Documents", .motive)
        ]

        return correct.contains { c in
            (c.0 == ev1.name && c.1 == ev2.name && c.2 == type) ||
            (c.0 == ev2.name && c.1 == ev1.name && c.2 == type)
        }
    }

    private func calculateScore() {
        var score = 0
        score += min(40, realEvidenceCount * 8)
        score += min(30, correctConnectionsCount * 10)
        score += min(20, suspectCooperationLevel * 2)
        score += min(10, analysisResults.count * 2)
        caseScore = score
    }

    private func calculateFinalScore() {
        calculateScore()
        caseScore = min(100, caseScore)
    }
}
