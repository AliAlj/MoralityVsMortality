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
    @Published var guardDialogueIndex = 0
    @Published var showingGuard = true
    @Published var guardItemsGiven = false

    var investigationAreas: [InvestigationArea] {
        switch currentRoom {
        case .hospitalRoom: return hospitalRoomAreas
        case .jailCell: return jailCellAreas
        }
    }

    var gameState: GameState

    let guardDialogue: [String] = [
        "You must be the investigator. I'm Jason Perry — I'll be escorting you through the facility.",
        "An inmate named Wayne Michaels died last night. Officially, it was a heart attack. You're here to confirm that.",
        "Here are his personal belongings and his prison intake form. Standard procedure — you'll need these for reference.",
        "You can search two locations: his jail cell and the hospital room where he was found. Look around carefully. Tap anything that catches your eye.",
        "I'll be here if you need me. Good luck."
    ]

    init(gameState: GameState) {
        self.gameState = gameState
        setupHospitalRoomAreas()
        setupJailCellAreas()
    }

    func advanceGuardDialogue() {
        if guardDialogueIndex == 2 && !guardItemsGiven {
            giveGuardItems()
            guardItemsGiven = true
        }

        if guardDialogueIndex < guardDialogue.count - 1 {
            guardDialogueIndex += 1
        } else {
            showingGuard = false
        }
    }

    private func giveGuardItems() {
        let license = Evidence(
            name: "Wayne's License",
            description: "Wayne's real license from his belongings bag. Organ Donor status clearly reads NO.",
            actDiscovered: 1,
            isRealEvidence: true,
            evidenceType: .document,
            metadata: ["organ_donor": "NO", "document_type": "original license"]
        )
        let intakeForm = Evidence(
            name: "Prison Intake Form",
            description: "Wayne's prison intake form. It includes a screenshot of his license showing Organ Donor status as YES.",
            actDiscovered: 1,
            isRealEvidence: true,
            evidenceType: .document,
            metadata: ["organ_donor": "YES", "detail": "license screenshot on file"]
        )
        gameState.addEvidence(license)
        gameState.addEvidence(intakeForm)
    }

    private func setupHospitalRoomAreas() {
        hospitalRoomAreas = [
            InvestigationArea(
                name: "Syringe",
                description: "A syringe found near the hospital bed",
                position: CGPoint(x: 300, y: 325),
                size: CGSize(width: 60, height: 50),
                imageName: "syringe",
                evidence: Evidence(
                    name: "Syringe",
                    description: "A used syringe with multiple injection marks. Suggests excessive sedation beyond what a routine procedure would require.",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .physical,
                    metadata: ["usage": "multiple injections", "concern": "excessive sedation"]
                )
            ),
            InvestigationArea(
                name: "Sedation Chart",
                description: "A chart clipped to the bed frame",
                position: CGPoint(x: 515, y: 320),
                size: CGSize(width: 80, height: 60),
                evidence: Evidence(
                    name: "Sedation Chart",
                    description: "Wayne's sedation dosage log. The prescribed amounts are significantly higher than standard levels for a routine procedure.",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .document,
                    metadata: ["dosage": "above normal", "procedure": "routine surgery"]
                )
            ),
            InvestigationArea(
                name: "Vital Monitor",
                description: "The bedside vital signs monitor with a printout",
                position: CGPoint(x: 90, y: 280),
                size: CGSize(width: 80, height: 80),
                evidence: Evidence(
                    name: "Vital Monitor Printout",
                    description: "A printout from the vital signs monitor. It shows Wayne still had a heart rate and oxygen levels at 2:00 AM — he was alive when found.",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .physical,
                    metadata: ["time": "2:00 AM", "status": "vitals present", "implication": "alive when found"]
                )
            )
        ]
    }

    private func setupJailCellAreas() {
        jailCellAreas = [
            InvestigationArea(
                name: "Crumbled Paper",
                description: "A crumbled piece of paper tucked under the bed",
                position: CGPoint(x: 300, y: 380),
                size: CGSize(width: 40, height: 35),
                imageName: "crumbledPaper",
                evidence: Evidence(
                    name: "Love Letter",
                    description: "A crumpled letter hidden under the bed. 'I'll be there when you wake up. We'll figure this out together. — K'",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .document,
                    metadata: ["author": "Kathy Alvarez", "tone": "romantic, personal"]
                ),
                revealedImageName: "loveLetter"
            )
        ]
    }
    
    func searchArea(_ area: InvestigationArea) {
        // Mark area as searched
        gameState.markAreaAsSearched(area.name)

        // Add evidence to inventory (no detail popup — just collect it)
        if let evidence = area.evidence {
            gameState.addEvidence(evidence)
            // Crumbled paper reveal is deferred to Act 3
            if area.revealedImageName != nil && area.name != "Crumbled Paper" {
                showingRevealedImage = area.revealedImageName
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
            viewModel.gameState = gameState
        }
        .sheet(item: $viewModel.showingEvidenceDetail) { evidence in
            EvidenceDetailSheet(evidence: evidence)
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.showingGuard {
                GuardDialogueView(viewModel: viewModel)
                    .padding()
                    .transition(.move(edge: .trailing))
            }
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
        .contentShape(Rectangle())
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

// MARK: - Prison Guard Dialogue
struct GuardDialogueView: View {
    @ObservedObject var viewModel: Act1ViewModel

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Dialogue bubble
            VStack(alignment: .leading, spacing: 8) {
                Text("Jason Perry")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.7))

                Text(viewModel.guardDialogue[viewModel.guardDialogueIndex])
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineSpacing(4)

                // Item notification
                if viewModel.guardDialogueIndex == 2 && viewModel.guardItemsGiven {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Wayne's License and Prison Intake Form added to evidence.")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 4)
                }

                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.advanceGuardDialogue()
                        }
                    } label: {
                        Text(viewModel.guardDialogueIndex < viewModel.guardDialogue.count - 1 ? "Continue" : "Got it")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .frame(maxWidth: 380)
            .background(Color.black.opacity(0.85))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

            // Guard portrait
            Image("prisonGuard")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
        }
    }
}

#Preview {
    Act1SceneInvestigationView()
        .environmentObject(GameState())
        .frame(width: 800, height: 600)
}
