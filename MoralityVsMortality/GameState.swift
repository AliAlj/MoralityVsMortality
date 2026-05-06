import SwiftUI
import Combine

@MainActor
class GameState: ObservableObject {
    // Must match the total number of questions across all 4 interrogation stages
    // Kathy: 6, Receptionist: 3, Morgue: 4, Surgeon: 4 = 17
    private let totalInterrogationDialogueCount = 17
    private let totalInvestigationEvidenceCount = 6
    private let totalAnalysisResultCount = 5

    // Player (persisted via AppStorage in views, synced here)
    @Published var playerName: String = UserDefaults.standard.string(forKey: "playerName") ?? ""
    @Published var selectedDetective: String = UserDefaults.standard.string(forKey: "selectedDetective") ?? "detectiveOne"

    //  Published
    @Published var currentAct: GameAct = .interrogation
    @Published var collectedEvidence: [Evidence] = []
    @Published var unlockedDialogue: [DialogueNode] = []
    @Published var gameCompleted: Bool = false
    // Act-specific (searchedAreas is not @Published to reduce re-render cascades;
    // its changes are picked up when collectedEvidence triggers a re-render)
    var searchedAreas: Set<String> = []
    @Published var analysisResults: [String: String] = [:]

    // Act-specific progress tracking
    @Published var completedInterrogationStages: Set<Int> = []
    @Published var guardIntroCompleted: Bool = false
    @Published var act4PhaseIndex: Int = 0
    @Published var shouldReturnToStart: Bool = false

    //  Computed
    var realEvidenceCount: Int   { collectedEvidence.filter(\.isRealEvidence).count }
    var investigationEvidenceCount: Int {
        collectedEvidence.filter { $0.isRealEvidence && $0.actDiscovered == 2 }.count
    }
    var totalEvidenceFound: Int  { collectedEvidence.count }
    var interrogationCompletionTarget: Int { totalInterrogationDialogueCount }
    var investigationCompletionTarget: Int { totalInvestigationEvidenceCount }
    var analysisCompletionTarget: Int { totalAnalysisResultCount }

    var canProgressToNextAct: Bool {
        switch currentAct {
        case .interrogation:  return unlockedDialogue.count >= totalInterrogationDialogueCount
        case .investigation:  return investigationEvidenceCount >= totalInvestigationEvidenceCount
        case .analysis:       return analysisResults.count >= totalAnalysisResultCount
        case .confrontation:  return false  // ends game
        }
    }

    private static let saveKey = "gameSaveData"

    //  Init
    init() {
        loadGame()
    }

    //  Evidence
    func addEvidence(_ evidence: Evidence) {
        guard !collectedEvidence.contains(where: { $0.name == evidence.name }) else { return }
        collectedEvidence.append(evidence)
        saveGame()
    }

    func addMultipleEvidence(_ items: [Evidence]) {
        let new = items.filter { item in !collectedEvidence.contains(where: { $0.name == item.name }) }
        guard !new.isEmpty else { return }
        collectedEvidence.append(contentsOf: new)
        saveGame()
    }

    func collectEvidenceFromArea(_ evidence: Evidence, areaName: String) {
        searchedAreas.insert(areaName)
        guard !collectedEvidence.contains(where: { $0.name == evidence.name }) else { return }
        collectedEvidence.append(evidence)
        saveGame()
    }

    func hasEvidence(named name: String) -> Bool {
        collectedEvidence.contains { $0.name == name }
    }

    func getEvidence(by id: UUID) -> Evidence? {
        collectedEvidence.first { $0.id == id }
    }

    // Areas
    func markAreaAsSearched(_ name: String) {
        searchedAreas.insert(name)
        saveGame()
    }
    func isAreaSearched(_ name: String) -> Bool { searchedAreas.contains(name) }

    // Dialogue (Act 2)
    func unlockDialogueNode(_ node: DialogueNode) {
        guard !unlockedDialogue.contains(where: { $0.questionText == node.questionText }) else { return }
        unlockedDialogue.append(node)
        saveGame()
    }

    //  Analysis (Act 3)
    func performAnalysis(evidenceID: UUID, tool: AnalysisTool) -> String? {
        guard let evidence = getEvidence(by: evidenceID) else { return nil }
        let result = getAnalysisResult(evidence: evidence, tool: tool)
        guard !result.isEmpty else { return nil }
        analysisResults[evidenceID.uuidString] = result
        saveGame()
        return result
    }

    // Progression
    func progressToNextAct() {
        guard canProgressToNextAct else { return }
        if let next = GameAct(rawValue: currentAct.rawValue + 1) {
            currentAct = next
            saveGame()
        }
    }

    func completeGame() {
        gameCompleted = true
        saveGame()
    }

    func resetGame() {
        currentAct = .interrogation
        collectedEvidence.removeAll()
        searchedAreas.removeAll()
        unlockedDialogue.removeAll()
        analysisResults.removeAll()
        completedInterrogationStages.removeAll()
        guardIntroCompleted = false
        act4PhaseIndex = 0
        gameCompleted = false
        saveGame()
    }

    // MARK: - Persistence

    func saveGame() {
        let save = GameSaveData(
            currentActRaw: currentAct.rawValue,
            collectedEvidence: collectedEvidence,
            unlockedDialogue: unlockedDialogue,
            gameCompleted: gameCompleted,
            searchedAreas: Array(searchedAreas),
            analysisResults: analysisResults,
            completedInterrogationStages: Array(completedInterrogationStages),
            guardIntroCompleted: guardIntroCompleted,
            act4PhaseIndex: act4PhaseIndex
        )
        if let data = try? JSONEncoder().encode(save) {
            UserDefaults.standard.set(data, forKey: Self.saveKey)
        }
    }

    private func loadGame() {
        guard let data = UserDefaults.standard.data(forKey: Self.saveKey),
              let save = try? JSONDecoder().decode(GameSaveData.self, from: data) else { return }

        currentAct = GameAct(rawValue: save.currentActRaw) ?? .interrogation
        collectedEvidence = save.collectedEvidence
        unlockedDialogue = save.unlockedDialogue
        gameCompleted = save.gameCompleted
        searchedAreas = Set(save.searchedAreas)
        analysisResults = save.analysisResults
        completedInterrogationStages = Set(save.completedInterrogationStages)
        guardIntroCompleted = save.guardIntroCompleted
        act4PhaseIndex = save.act4PhaseIndex
    }

    // Private
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
                .timeline: "2:00 AM — Dr. Victor Smith entered Wayne's room. No scheduled reason. 2:14 AM — Hilarie Jones badged in. 3:00 AM — Kathy Williams badged in, found Wayne unresponsive. 3:10 AM — Dr. Smith returned and pronounced death.",
                .contextLink: "Dr. Smith was in the room at 2:00 AM with no scheduled reason. The syringe was found near the bed. Someone administered a sedative between 2:00 AM and 3:00 AM — and the only person in the room during that window was the surgeon."
            ],
            "Vital Monitor Printout": [
                .timeline: "Heart rate and oxygen levels were present at 3:00 AM. Wayne was alive when Kathy found him. He was pronounced dead only after the surgeon arrived at 3:10 AM."
            ],
            // Medical Analysis Tool results
            "Syringe": [
                .medical: "Traces of elevated sedative compounds detected. Dosage far exceeds standard preoperative levels. This was not accidental.",
                .contextLink: "The syringe was found near Wayne's bed. The Time Log shows Dr. Smith was the only person in the room between 2:00 AM and 2:14 AM — the window when the sedative was likely administered."
            ],
            "Sedation Chart": [
                .medical: "Prescribed dosage is significantly higher than normal for a routine procedure. Sedation levels were intentionally increased."
            ],
            // Context Link Tool results
            "Love Letter": [
                .contextLink: "Written by Wayne to Kathy Williams. Confirms a personal relationship between them. Explains why she visited him at 3:00 AM — this was personal, not protocol."
            ]
        ]
        return combinations[evidence.name]?[tool] ?? ""
    }
}

// Codable save data
struct GameSaveData: Codable {
    let currentActRaw: Int
    let collectedEvidence: [Evidence]
    let unlockedDialogue: [DialogueNode]
    let gameCompleted: Bool
    let searchedAreas: [String]
    let analysisResults: [String: String]
    let completedInterrogationStages: [Int]
    let guardIntroCompleted: Bool
    let act4PhaseIndex: Int
}
