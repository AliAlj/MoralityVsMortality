import SwiftUI
import Combine

@MainActor
class GameState: ObservableObject {

    // MARK: - Player (persisted via AppStorage in views, synced here)
    @Published var playerName: String = UserDefaults.standard.string(forKey: "playerName") ?? ""
    @Published var selectedDetective: String = UserDefaults.standard.string(forKey: "selectedDetective") ?? "detectiveOne"

    // MARK: - Published
    @Published var currentAct: GameAct = .interrogation
    @Published var collectedEvidence: [Evidence] = []
    @Published var unlockedDialogue: [DialogueNode] = []
    @Published var evidenceConnections: [EvidenceConnection] = []
    @Published var gameCompleted: Bool = false
    // Act-specific
    @Published var searchedAreas: Set<String> = []
    @Published var analysisResults: [String: String] = [:]

    // MARK: - Computed
    var realEvidenceCount: Int   { collectedEvidence.filter(\.isRealEvidence).count }
    var totalEvidenceFound: Int  { collectedEvidence.count }
    var correctConnectionsCount: Int { evidenceConnections.filter(\.isCorrect).count }

    var canProgressToNextAct: Bool {
        switch currentAct {
        case .interrogation:  return unlockedDialogue.count >= 2
        case .investigation:  return realEvidenceCount >= 6
        case .analysis:       return correctConnectionsCount >= 2
        case .confrontation:  return false  // ends game
        }
    }

    // MARK: - Init
    init() { }

    // MARK: - Evidence
    func addEvidence(_ evidence: Evidence) {
        guard !collectedEvidence.contains(where: { $0.name == evidence.name }) else { return }
        collectedEvidence.append(evidence)
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

    // MARK: - Analysis (Act 3)
    func performAnalysis(evidenceID: UUID, tool: AnalysisTool) -> String? {
        guard let evidence = getEvidence(by: evidenceID) else { return nil }
        let result = getAnalysisResult(evidence: evidence, tool: tool)
        guard !result.isEmpty else { return nil }
        analysisResults[evidenceID.uuidString] = result
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
        gameCompleted = true
    }

    func resetGame() {
        currentAct = .interrogation
        collectedEvidence.removeAll()
        searchedAreas.removeAll()
        unlockedDialogue.removeAll()
        evidenceConnections.removeAll()
        analysisResults.removeAll()
        gameCompleted = false
    }

    // MARK: - Private
    private func getAnalysisResult(evidence: Evidence, tool: AnalysisTool) -> String {
        let combinations: [String: [AnalysisTool: String]] = [
            // Comparison Tool results
            "Wayne's License": [
                .comparison: "Organ Donor field reads NO. But the Prison Intake Form has a screenshot of his license showing YES. The screenshot was doctored."
            ],
            "Prison Intake Form": [
                .comparison: "The license screenshot on this form shows Organ Donor as YES. But Wayne's real license says NO. Someone altered the image."
            ],
            // Timeline Tool results
            "Room Access Log": [
                .timeline: "Kathy Alvarez badged in at 2:00 AM. Dr. Kazimir entered shortly after. Wayne's vitals were still active at that time.",
                .contextLink: "Cross-referencing the access log with Kathy's Love Letter confirms she visited Wayne personally, not on duty."
            ],
            "Vital Monitor Printout": [
                .timeline: "Heart rate and oxygen levels were present at 2:00 AM. Wayne was alive when Kathy found him. He was pronounced dead after the surgeon arrived."
            ],
            // Medical Analysis Tool results
            "Syringe": [
                .medical: "Traces of elevated sedative compounds detected. Dosage far exceeds standard pre-operative levels. This was not accidental."
            ],
            "Sedation Chart": [
                .medical: "Prescribed dosage is significantly higher than normal for a routine procedure. Sedation levels were intentionally increased."
            ],
            // Context Link Tool results
            "Love Letter": [
                .contextLink: "Written by Kathy Alvarez. She visited Wayne intentionally at 2:00 AM — this was personal, not protocol."
            ]
        ]
        return combinations[evidence.name]?[tool] ?? ""
    }

    private func validateConnection(e1: UUID, e2: UUID,
                                    type: EvidenceConnection.ConnectionType) -> Bool {
        guard let ev1 = getEvidence(by: e1),
              let ev2 = getEvidence(by: e2) else { return false }

        let correct: [(String, String, EvidenceConnection.ConnectionType)] = [
            ("Wayne's License", "Prison Intake Form", .method),
            ("Room Access Log", "Vital Monitor Printout", .timeline),
            ("Syringe", "Sedation Chart", .method),
            ("Love Letter", "Room Access Log", .person),
            ("Vital Monitor Printout", "Syringe", .timeline),
            ("Sedation Chart", "Prison Intake Form", .motive)
        ]

        return correct.contains { c in
            (c.0 == ev1.name && c.1 == ev2.name && c.2 == type) ||
            (c.0 == ev2.name && c.1 == ev1.name && c.2 == type)
        }
    }
}
