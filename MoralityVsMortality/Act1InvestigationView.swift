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

    // Guard dialogue
    @Published var guardDialogueIndex = 0
    @Published var showingGuard = true
    @Published var guardItemsGiven = false
    @Published var showingBelongingsReveal = false
    @Published var showingFormReveal = false
    @Published var showingItemPopup: (imageName: String?, evidenceName: String)? = nil

    let guardDialogue: [String] = [
        "You must be the investigator. I'm Jason Perry — I'll be escorting you through the facility.",
        "An inmate named Wayne Michaels died last night. Officially, it was a heart attack. You're here to confirm that.",
        "You can search two locations: his jail cell and the hospital room where he was found.",
        "Look around carefully. Hover over anything that catches your eye and click to collect it as evidence.",
        "Oh — before I forget. Here, take these. The victim's personal belongings and his prison intake form."
    ]

    var investigationAreas: [InvestigationArea] {
        switch currentRoom {
        case .hospitalRoom: return hospitalRoomAreas
        case .jailCell: return jailCellAreas
        }
    }

    var gameState: GameState
    private var hasSetRealGameState = false

    init(gameState: GameState) {
        self.gameState = gameState
        setupHospitalRoomAreas()
        setupJailCellAreas()
    }

    func setGameState(_ state: GameState) {
        guard !hasSetRealGameState else { return }
        hasSetRealGameState = true
        gameState = state
    }

    func advanceGuardDialogue() {
        if guardDialogueIndex < guardDialogue.count - 1 {
            guardDialogueIndex += 1
        } else {
            // Last line — show the belongings pop-up
            if !guardItemsGiven {
                guardItemsGiven = true
                showingGuard = false
                showingBelongingsReveal = true
            } else {
                showingGuard = false
            }
        }
    }

    func dismissBelongingsReveal() {
        showingBelongingsReveal = false
        showingFormReveal = true

        // Add belongings as sealed evidence
        let belongings = Evidence(
            name: "Wayne's Belongings",
            description: "A sealed bag containing Wayne's personal items including his wallet and license. You'll need to examine this more closely later.",
            actDiscovered: 2,
            isRealEvidence: true,
            evidenceType: .physical,
            metadata: ["status": "sealed", "contents": "wallet, license, personal items"]
        )
        gameState.addEvidence(belongings)
    }

    func dismissFormReveal() {
        showingFormReveal = false

        // Add intake form evidence
        let intakeForm = Evidence(
            name: "Prison Intake Form",
            description: "Wayne's prison intake form. You'll need to examine it more closely later.",
            actDiscovered: 2,
            isRealEvidence: true,
            evidenceType: .document,
            metadata: ["status": "collected"]
        )
        gameState.addEvidence(intakeForm)
    }

    private func setupHospitalRoomAreas() {
        hospitalRoomAreas = [
            InvestigationArea(
                name: "Syringe",
                description: "A syringe found near the hospital bed",
                position: CGPoint(x: 300, y: 325),
                size: CGSize(width: 80, height: 70),
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
        guard !gameState.isAreaSearched(area.name) else { return }

        // Mark area as searched
        gameState.markAreaAsSearched(area.name)

        // Add evidence to inventory
        if let evidence = area.evidence {
            gameState.addEvidence(evidence)
            // Show pop-up for every item
            showingItemPopup = (imageName: area.imageName, evidenceName: evidence.name)
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
                        .allowsHitTesting(false)
                    
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
            viewModel.setGameState(gameState)
        }
        .sheet(item: $viewModel.showingEvidenceDetail) { evidence in
            EvidenceDetailSheet(evidence: evidence)
        }
        // Guard dialogue — bottom right, doesn't block room
        .overlay(alignment: .bottomTrailing) {
            if viewModel.showingGuard {
                GuardDialogueView(viewModel: viewModel)
                    .padding()
                    .transition(.move(edge: .trailing))
            }
        }
        // Full-screen popups — only one shows at a time
        .overlay {
            if viewModel.showingBelongingsReveal {
                EvidencePopupOverlay(
                    title: "Wayne's Personal Belongings",
                    imageName: "waynesBelongings",
                    subtitle: "Added to evidence.",
                    buttonText: "Continue"
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.dismissBelongingsReveal()
                    }
                }
            } else if viewModel.showingFormReveal {
                EvidencePopupOverlay(
                    title: "Prison Intake Form",
                    imageName: "waynesForm",
                    subtitle: "Wayne's Belongings and Prison Intake Form added to evidence.",
                    buttonText: "Continue"
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.dismissFormReveal()
                    }
                }
            } else if let item = viewModel.showingItemPopup {
                ZStack {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.showingItemPopup = nil
                            }
                        }

                    VStack(spacing: 16) {
                        Text(item.evidenceName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        if let imageName = item.imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 500, maxHeight: 400)
                                .cornerRadius(12)
                                .shadow(radius: 20)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Added to evidence.")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }

                        Text("Click anywhere to continue")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.showingItemPopup = nil
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Evidence Popup Overlay
struct EvidencePopupOverlay: View {
    let title: String
    let imageName: String
    var subtitle: String = ""
    var buttonText: String = "Continue"
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 500, maxHeight: 400)
                    .cornerRadius(12)
                    .shadow(radius: 20)

                if !subtitle.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }

                Text("Click anywhere to continue")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .onTapGesture { onDismiss() }
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
                    Text("Need \(max(0, 6 - gameState.realEvidenceCount)) more")
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
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Jason Perry")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.7))

                Text(viewModel.guardDialogue[viewModel.guardDialogueIndex])
                    .font(.body)
                    .foregroundColor(.white)
                    .lineSpacing(6)

                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.advanceGuardDialogue()
                        }
                    } label: {
                        Text(viewModel.guardDialogueIndex < viewModel.guardDialogue.count - 1 ? "Continue" : "Got it")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .frame(maxWidth: 480)
            .background(Color.black.opacity(0.85))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

            Image("prisonGuard")
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
        }
    }
}

#Preview {
    Act1SceneInvestigationView()
        .environmentObject(GameState())
        .frame(width: 800, height: 600)
}
