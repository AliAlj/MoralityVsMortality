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
        case .interrogation:  return unlockedDialogue.count >= 2
        case .investigation:  return realEvidenceCount >= 6
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
        guard !collectedEvidence.contains(where: { $0.name == evidence.name }) else { return }
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
        currentAct = .interrogation
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
            Suspect(name: "Dr. Viktor Kazimir",
                    description: "Head surgeon. Declared Wayne dead. Performed the scheduled surgery.",
                    suspicionLevel: 6, isUnlocked: true,
                    portraitImage: "prisonSurgeon"),
            Suspect(name: "Kathy Alvarez",
                    description: "Nurse on duty. Found Wayne unresponsive at 2:00 AM.",
                    suspicionLevel: 5, isUnlocked: true,
                    portraitImage: "prisonNurse"),
            Suspect(name: "Receptionist",
                    description: "Front desk staff. Manages room access logs.",
                    suspicionLevel: 2, isUnlocked: false,
                    portraitImage: "prisonReceptionist"),
            Suspect(name: "Peter Simmons",
                    description: "Morgue worker. Handled Wayne's body after death.",
                    suspicionLevel: 4, isUnlocked: false,
                    portraitImage: "prisonMorgueWorker")
        ]
    }

    private func checkForUnlockedDialogue() {
        // Unlock Receptionist when Sedation Chart is found
        if hasEvidence(named: "Sedation Chart"),
           let i = suspects.firstIndex(where: { $0.name == "Receptionist" }) {
            suspects[i].isUnlocked = true
        }
        // Unlock Peter Simmons when Vital Monitor Printout is found
        if hasEvidence(named: "Vital Monitor Printout"),
           let i = suspects.firstIndex(where: { $0.name == "Peter Simmons" }) {
            suspects[i].isUnlocked = true
        }
    }

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
                .timeline: "Kathy Alvarez badged in at 2:00 AM. Dr. Kazimir entered shortly after. Wayne's vitals were still active at that time."
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
            ],
            "Room Access Log": [
                .contextLink: "Cross-referencing the access log with Kathy's Love Letter confirms she visited Wayne personally, not on duty."
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
