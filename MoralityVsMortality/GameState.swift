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
    @Published var gameCompleted: Bool = false
    // Act-specific (searchedAreas is not @Published to reduce re-render cascades;
    // its changes are picked up when collectedEvidence triggers a re-render)
    var searchedAreas: Set<String> = []
    @Published var analysisResults: [String: String] = [:]

    // MARK: - Computed
    var realEvidenceCount: Int   { collectedEvidence.filter(\.isRealEvidence).count }
    var totalEvidenceFound: Int  { collectedEvidence.count }

    var canProgressToNextAct: Bool {
        switch currentAct {
        case .interrogation:  return unlockedDialogue.count >= 2
        case .investigation:  return realEvidenceCount >= 6
        case .analysis:       return analysisResults.count >= 3
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

    func addMultipleEvidence(_ items: [Evidence]) {
        let new = items.filter { item in !collectedEvidence.contains(where: { $0.name == item.name }) }
        guard !new.isEmpty else { return }
        collectedEvidence.append(contentsOf: new)
    }

    func collectEvidenceFromArea(_ evidence: Evidence, areaName: String) {
        searchedAreas.insert(areaName)
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
            "Time Log": [
                .timeline: "Dr. Victor Smith entered unauthorized at 2:00 AM. Hilarie Jones entered at 2:14 AM and saw him near the IV. Kathy Williams badged in at 3:00 AM and found Wayne unresponsive. Dr. Smith returned at 3:10 AM and pronounced death.",
                .contextLink: "The Time Log shows Dr. Smith was in the room at 2:00 AM — the same time the Syringe was likely used. Hilarie Jones witnessed him near Wayne's IV and saw a syringe cap drop. This links the unauthorized entry to the sedation."
            ],
            "Vital Monitor Printout": [
                .timeline: "Heart rate and oxygen levels were present at 3:00 AM. Wayne was alive when Kathy found him. He was pronounced dead after the surgeon arrived."
            ],
            // Medical Analysis Tool results
            "Syringe": [
                .medical: "Traces of elevated sedative compounds detected. Dosage far exceeds standard preoperative levels. This was not accidental.",
                .contextLink: "The Syringe matches the receptionist's account of Dr. Smith injecting something into Wayne's IV at 2:00 AM. The Time Log confirms he was in the room at that time."
            ],
            "Sedation Chart": [
                .medical: "Prescribed dosage is significantly higher than normal for a routine procedure. Sedation levels were intentionally increased."
            ],
            // Context Link Tool results
            "Love Letter": [
                .contextLink: "Written by Kathy Williams. She visited Wayne intentionally at 3:00 AM. This was personal, not protocol."
            ]
        ]
        return combinations[evidence.name]?[tool] ?? ""
    }
}
