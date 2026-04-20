import SwiftUI
import Combine

// MARK: - Act 1: Wrapper View
struct Act1InvestigationView: View {
    var body: some View {
        Act1SceneInvestigationView()
    }
}

// MARK: - Act 1: Scene Investigation View Model
@MainActor
class Act1ViewModel: ObservableObject {
    @Published var currentRoom: InvestigationRoom = .hospitalRoom
    @Published var hospitalRoomAreas: [InvestigationArea] = []
    @Published var jailCellAreas: [InvestigationArea] = []
    @Published var showingEvidenceDetail: Evidence? = nil
    
    var investigationAreas: [InvestigationArea] {
        switch currentRoom {
        case .hospitalRoom: return hospitalRoomAreas
        case .jailCell: return jailCellAreas
        }
    }
    
    var gameState: GameState
    
    init(gameState: GameState) {
        self.gameState = gameState
        setupHospitalRoomAreas()
        setupJailCellAreas()
    }
    
    private func setupHospitalRoomAreas() {
        hospitalRoomAreas = [
            InvestigationArea(
                name: "Hospital Bed",
                description: "The victim's bed shows signs of struggle",
                position: CGPoint(x: 300, y: 200),
                size: CGSize(width: 120, height: 80),
                evidence: Evidence(
                    name: "Bloody Pillow",
                    description: "Pillow with blood stains, suggests head trauma",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .physical,
                    metadata: ["location": "bed", "appearance": "dried stains"]
                )
            ),
            InvestigationArea(
                name: "Bedside Table",
                description: "Small table with medical supplies",
                position: CGPoint(x: 450, y: 180),
                size: CGSize(width: 80, height: 60),
                evidence: Evidence(
                    name: "Syringe",
                    description: "Empty syringe with traces of unknown substance",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .physical,
                    metadata: ["substance": "unknown residue", "fingerprints": "visible smudges"]
                )
            ),
            InvestigationArea(
                name: "Window",
                description: "Large window overlooking the parking lot",
                position: CGPoint(x: 600, y: 100),
                size: CGSize(width: 100, height: 120),
                evidence: Evidence(
                    name: "Scuff Marks",
                    description: "Fresh scuff marks on the window frame",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .physical,
                    metadata: ["height": "6 feet", "direction": "entering"]
                )
            ),
            InvestigationArea(
                name: "Floor Area",
                description: "Tiled floor near the door",
                position: CGPoint(x: 200, y: 350),
                size: CGSize(width: 150, height: 100),
                evidence: Evidence(
                    name: "Bloody Glove",
                    description: "Latex glove with blood evidence, partially hidden",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .physical,
                    metadata: ["appearance": "dark stains visible", "size": "large"]
                )
            ),
            InvestigationArea(
                name: "Waste Basket",
                description: "Small medical waste container",
                position: CGPoint(x: 100, y: 300),
                size: CGSize(width: 60, height: 80),
                evidence: Evidence(
                    name: "Empty Candy Wrapper",
                    description: "Chocolate bar wrapper - not relevant to case",
                    actDiscovered: 1,
                    isRealEvidence: false,
                    evidenceType: .physical,
                    metadata: ["brand": "SweetTooth", "relevance": "none"]
                )
            ),
            InvestigationArea(
                name: "Medical Cart",
                description: "Wheeled cart with medical instruments",
                position: CGPoint(x: 500, y: 350),
                size: CGSize(width: 80, height: 100),
                evidence: Evidence(
                    name: "Hospital ID Badge",
                    description: "Employee badge found under cart - Dr. Sarah Chen",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .document,
                    metadata: ["owner": "Dr. Sarah Chen", "department": "Surgery"]
                )
            ),
            InvestigationArea(
                name: "Air Vent",
                description: "Ceiling air vent above the bed",
                position: CGPoint(x: 350, y: 50),
                size: CGSize(width: 60, height: 40),
                evidence: Evidence(
                    name: "Dust Patterns",
                    description: "Disturbed dust suggesting recent access",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .physical,
                    metadata: ["disturbance": "recent", "access": "possible"]
                )
            ),
            InvestigationArea(
                name: "Bathroom Door",
                description: "Partially open bathroom door",
                position: CGPoint(x: 50, y: 150),
                size: CGSize(width: 80, height: 120),
                evidence: Evidence(
                    name: "Tissue Paper",
                    description: "Used tissue with lipstick - likely unrelated",
                    actDiscovered: 1,
                    isRealEvidence: false,
                    evidenceType: .physical,
                    metadata: ["color": "red", "relevance": "low"]
                )
            )
        ]
    }
    
    private func setupJailCellAreas() {
        jailCellAreas = [
            InvestigationArea(
                name: "Officer's Desk",
                description: "The intake officer's desk with paperwork and files",
                position: CGPoint(x: 100, y: 180),
                size: CGSize(width: 90, height: 70),
                evidence: Evidence(
                    name: "Original License Photo",
                    description: "A photocopy of the victim's original license from intake paperwork. The organ donor field clearly reads NO.",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .document,
                    metadata: ["organ_donor": "no", "document_type": "intake photocopy"]
                )
            ),
            InvestigationArea(
                name: "Personal Belongings Box",
                description: "Cardboard box with the victim's possessions, handed over by the officer",
                position: CGPoint(x: 500, y: 180),
                size: CGSize(width: 100, height: 80),
                evidence: Evidence(
                    name: "Victim's Prison License",
                    description: "The victim's official ID from prison records. Shows organ donor status as YES, but something about the donor field looks off.",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .document,
                    metadata: ["organ_donor": "yes", "condition": "suspected alteration on donor field"]
                )
            ),
            InvestigationArea(
                name: "Victim's Bunk",
                description: "The victim's prison bed, neatly made",
                position: CGPoint(x: 300, y: 200),
                size: CGSize(width: 120, height: 80),
                evidence: Evidence(
                    name: "Love Letter",
                    description: "A heartfelt letter hidden under the pillow. 'I'll be waiting for you when you get out. We'll start over together. Love, Jen.'",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .document,
                    metadata: ["author": "Nurse Jennifer Walsh", "tone": "romantic"]
                )
            ),
            InvestigationArea(
                name: "Bookshelf",
                description: "Small shelf with a few worn paperbacks",
                position: CGPoint(x: 150, y: 350),
                size: CGSize(width: 80, height: 70),
                evidence: Evidence(
                    name: "Legal Documents",
                    description: "The victim's release paperwork. Confirms he was scheduled for release in 3 days. The operation that brought him to the hospital was for a minor condition.",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .document,
                    metadata: ["release_date": "3 days from incident", "operation": "minor condition"]
                )
            ),
            InvestigationArea(
                name: "Cell Wall",
                description: "Concrete wall with scratch marks and faded graffiti",
                position: CGPoint(x: 600, y: 120),
                size: CGSize(width: 80, height: 100),
                evidence: Evidence(
                    name: "Tally Marks",
                    description: "Days counted on the wall. The victim was counting down to release — only 3 days remained.",
                    actDiscovered: 1,
                    isRealEvidence: false,
                    evidenceType: .physical,
                    metadata: ["days_remaining": "3", "relevance": "atmosphere"]
                )
            ),
            InvestigationArea(
                name: "Under the Mattress",
                description: "A common hiding spot in prison cells",
                position: CGPoint(x: 350, y: 320),
                size: CGSize(width: 100, height: 60),
                evidence: Evidence(
                    name: "Commissary Receipts",
                    description: "Stack of receipts from the prison commissary. Nothing remarkable — snacks and toiletries.",
                    actDiscovered: 1,
                    isRealEvidence: false,
                    evidenceType: .physical,
                    metadata: ["items": "snacks, soap, stamps", "relevance": "none"]
                )
            ),
            InvestigationArea(
                name: "Toilet Area",
                description: "Standard prison cell fixture",
                position: CGPoint(x: 550, y: 350),
                size: CGSize(width: 70, height: 70),
                evidence: nil
            )
        ]
    }
    
    func searchArea(_ area: InvestigationArea) {
        // Mark area as searched
        gameState.markAreaAsSearched(area.name)
        
        // Add evidence if present
        if let evidence = area.evidence {
            gameState.addEvidence(evidence)
            showingEvidenceDetail = evidence
        }
        
        // Update the area in the correct room's array
        switch currentRoom {
        case .hospitalRoom:
            if let index = hospitalRoomAreas.firstIndex(where: { $0.id == area.id }) {
                hospitalRoomAreas[index].hasBeenSearched = true
            }
        case .jailCell:
            if let index = jailCellAreas.firstIndex(where: { $0.id == area.id }) {
                jailCellAreas[index].hasBeenSearched = true
            }
        }
    }
    
    func isAreaSearched(_ area: InvestigationArea) -> Bool {
        gameState.isAreaSearched(area.name)
    }
}

// MARK: - Act 1: Scene Investigation View
struct Act1SceneInvestigationView: View {
    @EnvironmentObject private var gameState: GameState
    @StateObject private var viewModel = Act1ViewModel(gameState: GameState())
    
    var body: some View {
        VStack {
            // Instructions
            HStack {
                Text("🔍 **Investigation Mode**")
                    .font(.headline)
                
                Spacer()
                
                Text("Tap areas to search for evidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Room switcher
            Picker("Location", selection: $viewModel.currentRoom) {
                ForEach(InvestigationRoom.allCases, id: \.self) { room in
                    Text(room.rawValue).tag(room)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Main investigation area
            GeometryReader { geometry in
                ZStack {
                    // Room background
                    RoomBackgroundView(room: viewModel.currentRoom)
                    
                    // Interactive areas - positions scale to available space
                    ForEach(viewModel.investigationAreas) { area in
                        InvestigationAreaView(
                            area: area,
                            isSearched: viewModel.isAreaSearched(area),
                            onTap: {
                                viewModel.searchArea(area)
                            }
                        )
                        .position(
                            x: (area.position.x / 700) * geometry.size.width,
                            y: (area.position.y / 450) * geometry.size.height
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Evidence summary
            EvidenceSummaryView()
        }
        .onAppear {
            // Reinitialize viewModel with actual gameState
            viewModel.gameState = gameState
        }
        .sheet(item: $viewModel.showingEvidenceDetail) { evidence in
            EvidenceDetailSheet(evidence: evidence)
        }
    }
}

// MARK: - Room Background
struct RoomBackgroundView: View {
    let room: InvestigationRoom
    
    var body: some View {
        ZStack {
            // Room outline
            Rectangle()
                .stroke(Color.primary, lineWidth: 3)
                .background(Color(NSColor.controlBackgroundColor))
            
            // Room features
            VStack {
                HStack {
                    Text(room.label)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(4)
                        .background(accentColor.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Text(room.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    private var accentColor: Color {
        switch room {
        case .hospitalRoom: return .blue
        case .jailCell: return .orange
        }
    }
}

// MARK: - Investigation Area View
struct InvestigationAreaView: View {
    let area: InvestigationArea
    let isSearched: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .stroke(borderColor, lineWidth: 2)
                .overlay(
                    VStack {
                        Text(area.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                        
                        if isSearched {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else if area.evidence != nil {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    .padding(4)
                )
        }
        .buttonStyle(.plain)
        .frame(width: area.size.width, height: area.size.height)
        .help(area.description)
    }
    
    private var backgroundColor: Color {
        if isSearched {
            return .green.opacity(0.2)
        } else {
            return .blue.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        if isSearched {
            return .green
        } else {
            return .blue.opacity(0.5)
        }
    }
}

// MARK: - Evidence Summary
struct EvidenceSummaryView: View {
    @EnvironmentObject private var gameState: GameState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Evidence Found: \(gameState.totalEvidenceFound)")
                    .font(.headline)
                
                Text("Real Evidence: \(gameState.realEvidenceCount)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            if gameState.canProgressToNextAct {
                VStack(alignment: .trailing) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    Text("Ready to Continue")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } else {
                VStack(alignment: .trailing) {
                    Text("Need \(max(0, 3 - gameState.realEvidenceCount)) more")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("real evidence pieces")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Evidence Detail Sheet
struct EvidenceDetailSheet: View {
    let evidence: Evidence
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(evidence.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("✕") {
                    dismiss()
                }
                .font(.title2)
                .foregroundColor(.secondary)
            }
            
            HStack {
                Text(evidence.evidenceType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(evidence.isRealEvidence ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
            }
            
            Text(evidence.description)
                .font(.body)
            
            if !evidence.metadata.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Details:")
                        .font(.headline)
                    
                    ForEach(Array(evidence.metadata.keys.sorted()), id: \.self) { key in
                        if let value = evidence.metadata[key] {
                            HStack {
                                Text("\(key.capitalized):")
                                    .fontWeight(.medium)
                                Text(value)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Dismiss button
            HStack {
                Spacer()
                Button("Got It") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    Act1SceneInvestigationView()
        .environmentObject(GameState())
}
