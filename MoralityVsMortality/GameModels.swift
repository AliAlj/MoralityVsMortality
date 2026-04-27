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
    }
}

// MARK: - Dialogue System
struct DialogueNode: Identifiable, Codable {
    let id: UUID
    let questionText: String
    let responses: [DialogueResponse]

    init(questionText: String, responses: [DialogueResponse]) {
        self.id = UUID()
        self.questionText = questionText
        self.responses = responses
    }
}

struct DialogueResponse: Identifiable, Codable {
    let id: UUID
    let text: String

    init(text: String) {
        self.id = UUID()
        self.text = text
    }
}

// MARK: - 4-Act Structure
enum GameAct: Int, CaseIterable {
    case interrogation = 1
    case investigation = 2
    case analysis = 3
    case confrontation = 4

    var title: String {
        switch self {
        case .interrogation:  return "The Voices"
        case .investigation:  return "The Investigation"
        case .analysis:       return "The Web"
        case .confrontation:  return "The Confrontation"
        }
    }

    var subtitle: String {
        switch self {
        case .interrogation:  return "Question the suspects"
        case .investigation:  return "Search both scenes for evidence"
        case .analysis:       return "Examine evidence with tools"
        case .confrontation:  return "Face the truth"
        }
    }

    var romanNumeral: String {
        switch self {
        case .interrogation:  return "I"
        case .investigation:  return "II"
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

    init(name: String, description: String, position: CGPoint,
         size: CGSize, imageName: String? = nil, evidence: Evidence? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.position = position
        self.size = size
        self.imageName = imageName
        self.evidence = evidence
    }
}

enum InvestigationRoom: String, CaseIterable {
    case jailCell     = "Jail Cell"
    case hospitalRoom = "Hospital Room"

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
    case comparison  = "Comparison"
    case timeline    = "Timeline"
    case medical     = "Medical Analysis"
    case contextLink = "Context Link"

    var description: String {
        switch self {
        case .comparison:  return "Compare two documents for discrepancies"
        case .timeline:    return "Reconstruct the sequence of events"
        case .medical:     return "Analyze medical data and substances"
        case .contextLink: return "Link evidence to reveal hidden connections"
        }
    }

    var icon: String {
        switch self {
        case .comparison:  return "doc.on.doc"
        case .timeline:    return "clock.arrow.circlepath"
        case .medical:     return "cross.vial"
        case .contextLink: return "link"
        }
    }
}

// MARK: - Conversation
struct ConversationEntry: Identifiable {
    let id = UUID()
    let speaker: Speaker
    let text: String

    enum Speaker { case investigator, suspect }
}
