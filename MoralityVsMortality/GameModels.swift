import SwiftUI

// MARK: - Evidence Model
struct Evidence: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let actDiscovered: Int
    let isRealEvidence: Bool
    let evidenceType: EvidenceType
    let metadata: [String: String]

    init(name: String, description: String, actDiscovered: Int,
         isRealEvidence: Bool, evidenceType: EvidenceType,
         metadata: [String: String]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.actDiscovered = actDiscovered
        self.isRealEvidence = isRealEvidence
        self.evidenceType = evidenceType
        self.metadata = metadata
    }

    enum EvidenceType: String, Codable, CaseIterable {
        case physical = "Physical"
        case document = "Document"
        case timestamp = "Timestamp"
        case analysis = "Analysis"
        case connection = "Connection"
    }
}

// MARK: - Suspect Model
struct Suspect: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let suspicionLevel: Int
    var isUnlocked: Bool

    init(name: String, description: String,
         suspicionLevel: Int, isUnlocked: Bool = false) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.suspicionLevel = suspicionLevel
        self.isUnlocked = isUnlocked
    }
}

// MARK: - Dialogue System
struct DialogueNode: Identifiable, Codable {
    let id: UUID
    let questionText: String
    let responses: [DialogueResponse]
    let requiredEvidence: [String]
    var isUnlocked: Bool

    init(questionText: String, responses: [DialogueResponse],
         requiredEvidence: [String], isUnlocked: Bool = false) {
        self.id = UUID()
        self.questionText = questionText
        self.responses = responses
        self.requiredEvidence = requiredEvidence
        self.isUnlocked = isUnlocked
    }
}

struct DialogueResponse: Identifiable, Codable {
    let id: UUID
    let text: String
    let suspectReaction: String
    let revealsEvidence: String?
    let changesRelationship: Int

    init(text: String, suspectReaction: String,
         revealsEvidence: String? = nil, changesRelationship: Int = 0) {
        self.id = UUID()
        self.text = text
        self.suspectReaction = suspectReaction
        self.revealsEvidence = revealsEvidence
        self.changesRelationship = changesRelationship
    }
}

// MARK: - Evidence Connection
struct EvidenceConnection: Identifiable, Codable {
    let id: UUID
    let evidence1ID: UUID
    let evidence2ID: UUID
    let connectionType: ConnectionType
    let isCorrect: Bool

    init(evidence1ID: UUID, evidence2ID: UUID,
         connectionType: ConnectionType, isCorrect: Bool) {
        self.id = UUID()
        self.evidence1ID = evidence1ID
        self.evidence2ID = evidence2ID
        self.connectionType = connectionType
        self.isCorrect = isCorrect
    }

    enum ConnectionType: String, Codable, CaseIterable {
        case timeline = "Timeline"
        case location = "Location"
        case person = "Person"
        case method = "Method"
        case motive = "Motive"
    }
}

// MARK: - 4-Act Structure
enum GameAct: Int, CaseIterable {
    case investigation = 1
    case interrogation = 2
    case analysis = 3
    case confrontation = 4

    var title: String {
        switch self {
        case .investigation:  return "The Investigation"
        case .interrogation:  return "The Voices"
        case .analysis:       return "The Web"
        case .confrontation:  return "The Confrontation"
        }
    }

    var subtitle: String {
        switch self {
        case .investigation:  return "Search both scenes for evidence"
        case .interrogation:  return "Question the suspects"
        case .analysis:       return "Examine evidence with tools"
        case .confrontation:  return "Face Dr. Voss"
        }
    }

    var romanNumeral: String {
        switch self {
        case .investigation:  return "I"
        case .interrogation:  return "II"
        case .analysis:       return "III"
        case .confrontation:  return "IV"
        }
    }
}

// MARK: - Investigation
struct InvestigationArea: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let position: CGPoint
    let size: CGSize
    let imageName: String?
    let evidence: Evidence?
    let revealedImageName: String?
    var hasBeenSearched: Bool

    init(name: String, description: String, position: CGPoint,
         size: CGSize, imageName: String? = nil, evidence: Evidence? = nil,
         revealedImageName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.position = position
        self.size = size
        self.imageName = imageName
        self.evidence = evidence
        self.revealedImageName = revealedImageName
        self.hasBeenSearched = false
    }
}

enum InvestigationRoom: String, CaseIterable {
    case jailCell     = "Jail Cell"
    case hospitalRoom = "Hospital Room"

    var label: String {
        switch self {
        case .hospitalRoom: return "ROOM 342"
        case .jailCell:     return "CELL BLOCK D"
        }
    }

    var subtitle: String {
        switch self {
        case .hospitalRoom: return "HOSPITAL WING"
        case .jailCell:     return "JAIL CELL"
        }
    }

    var imageName: String {
        switch self {
        case .hospitalRoom: return "hospitalRoom"
        case .jailCell:     return "jailCell"
        }
    }
}

// MARK: - Analysis Tool
enum AnalysisTool: String, CaseIterable {
    case uv          = "UV Light"
    case dna         = "DNA Test"
    case blood       = "Blood Analysis"
    case fingerprint = "Fingerprint"
    case microscope  = "Microscope"

    var description: String {
        switch self {
        case .uv:          return "Reveals hidden markings and substances"
        case .dna:         return "Identifies genetic material"
        case .blood:       return "Determines blood type and origin"
        case .fingerprint: return "Analyzes fingerprint patterns"
        case .microscope:  return "Examines microscopic details"
        }
    }

    var icon: String {
        switch self {
        case .uv:          return "lightbulb.fill"
        case .dna:         return "staroflife.fill"
        case .blood:       return "drop.fill"
        case .fingerprint: return "hand.point.up.braille.fill"
        case .microscope:  return "eye.circle.fill"
        }
    }
}

// MARK: - Conversation
struct ConversationEntry: Identifiable {
    let id = UUID()
    let speaker: Speaker
    let text: String
    let timestamp: Date

    init(speaker: Speaker, text: String, timestamp: Date = Date()) {
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
    }

    enum Speaker { case investigator, suspect }
}

// MARK: - Accusation
struct AccusationOption: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let requiredEvidence: [String]
    let outcome: AccusationOutcome
    let response: String
}

enum AccusationOutcome {
    case fullTruth, partialTruth, falseAccusation, needMoreEvidence
}

// MARK: - Final Choice
enum ChoiceOutcome {
    case arrest, cooperation, weakArrest, continueInvestigation, closedCase
}

struct FinalChoice: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let outcome: ChoiceOutcome
    let requirements: String
    let consequences: String
}

// MARK: - Case Review
struct CaseReviewData {
    let totalScore: Int
    let evidenceCollected: Int
    let realEvidenceFound: Int
    let correctConnections: Int
    let suspectCooperation: Int
    let analysesPerformed: Int
    let actsCompleted: Int

    var grade: String {
        switch totalScore {
        case 90...: return "A+"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        default: return "D"
        }
    }
}

// MARK: - Ending
struct GameOutcome {
    let title: String
    let description: String
    let endingType: EndingType

    enum EndingType: String {
        case success        = "Success"
        case partialSuccess = "Partial Success"
        case neutral        = "Neutral"
        case failure        = "Failure"
    }
}
