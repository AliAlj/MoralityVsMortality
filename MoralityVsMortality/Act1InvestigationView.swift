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
    @Published var currentRoom: InvestigationRoom = .jailCell
    @Published var hospitalRoomAreas: [InvestigationArea] = []
    @Published var jailCellAreas: [InvestigationArea] = []
    @Published var showingEvidenceDetail: Evidence? = nil
    @Published var showingRevealedImage: String? = nil
    
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
                name: "Syringe",
                description: "A syringe found under the hospital bed",
                position: CGPoint(x: 300, y: 325),
                size: CGSize(width: 120, height: 80),
                imageName: "syringe",
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
                name: "Medical Cart",
                description: "Wheeled cart with medical instruments",
                position: CGPoint(x: 90, y: 330),
                size: CGSize(width: 80, height: 100),
                evidence: Evidence(
                    name: "Hospital ID Badge",
                    description: "Employee badge found under cart - Dr. Sarah Chen",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .document,
                    metadata: ["owner": "Dr. Sarah Chen", "department": "Surgery"]
                )
            )
        ]
    }
    
    private func setupJailCellAreas() {
        jailCellAreas = [
            InvestigationArea(
                name: "Personal Belongings Box",
                description: "Cardboard box with the victim's possessions, handed over by the officer",
                position: CGPoint(x: 600, y: 80),
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
                name: "Crumbled Paper",
                description: "A crumbled piece of paper tucked under the bed",
                position: CGPoint(x: 300, y: 380),
                size: CGSize(width: 40, height: 35),
                imageName: "crumbledPaper",
                evidence: Evidence(
                    name: "Love Letter",
                    description: "A heartfelt letter hidden under the pillow. 'I'll be waiting for you when you get out. We'll start over together. Love, Jen.'",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .document,
                    metadata: ["author": "Nurse Jennifer Walsh", "tone": "romantic"]
                ),
                revealedImageName: "loveLetter"
            ),
            InvestigationArea(
                name: "Under the Mattress",
                description: "A common hiding spot in prison cells",
                position: CGPoint(x: 350, y: 380),
                size: CGSize(width: 100, height: 60),
                evidence: Evidence(
                    name: "Commissary Receipts",
                    description: "Stack of receipts from the prison commissary. Nothing remarkable — snacks and toiletries.",
                    actDiscovered: 1,
                    isRealEvidence: false,
                    evidenceType: .physical,
                    metadata: ["items": "snacks, soap, stamps", "relevance": "none"]
                )
            )
        ]
    }
    
    func searchArea(_ area: InvestigationArea) {
        // Mark area as searched
        gameState.markAreaAsSearched(area.name)

        // Add evidence if present
        if let evidence = area.evidence {
            gameState.addEvidence(evidence)
            if let revealedImage = area.revealedImageName {
                showingRevealedImage = revealedImage
            } else {
                showingEvidenceDetail = evidence
            }
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
        .overlay {
            if let revealedImage = viewModel.showingRevealedImage {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .onTapGesture {
                            viewModel.showingRevealedImage = nil
                        }

                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                viewModel.showingRevealedImage = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .padding()
                        }

                        Image(revealedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 650, maxHeight: 550)
                            .cornerRadius(12)
                            .shadow(radius: 20)

                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - Room Background
struct RoomBackgroundView: View {
    let room: InvestigationRoom

    var body: some View {
        ZStack {
            // Room background image
            Image(room.imageName)
                .resizable()
                .scaledToFill()
                .clipped()

            // Darkened overlay for readability
            Color.black.opacity(0.3)

            // Room subtitle
            VStack {
                Spacer()

                HStack {
                    Spacer()
                    Text(room.subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
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
    @State private var isHovered = false

    private var hasImage: Bool { area.imageName != nil }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let imageName = area.imageName {
                    // Asset-based item
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .brightness(isHovered && !isSearched ? 0.2 : 0)

                    if isHovered && !isSearched {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
                            .shadow(color: .white.opacity(0.6), radius: 8)
                    }
                } else {
                    // Blue highlighted box for items without an asset
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSearched ? Color.green.opacity(0.2) : Color.blue.opacity(isHovered ? 0.3 : 0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSearched ? Color.green : Color.blue.opacity(isHovered ? 0.8 : 0.5), lineWidth: 2)
                        )
                        .overlay(
                            VStack {
                                Text(area.name)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)

                                if isSearched {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                            .padding(4)
                        )
                }

                // Checkmark for asset-based items
                if hasImage && isSearched {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                                .shadow(radius: 2)
                        }
                    }
                    .padding(4)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: area.size.width, height: area.size.height)
        .onHover { hovering in
            isHovered = hovering
        }
        .help(area.description)
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
        .frame(width: 800, height: 600)
}
