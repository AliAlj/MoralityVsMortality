import SwiftUI
import Combine


struct Act2InvestigationView: View {
    @StateObject private var viewModel = Act2InvestigationViewModel()

    var body: some View {
        Act2SceneInvestigationView(viewModel: viewModel)
    }
}


@MainActor
class Act2InvestigationViewModel: ObservableObject {
    @Published var currentRoom: InvestigationRoom = .jailCell
    @Published var hospitalRoomAreas: [InvestigationArea] = []
    @Published var jailCellAreas: [InvestigationArea] = []

    // Guard dialogue
    @Published var guardDialogueIndex = 0
    @Published var showingGuard = true
    @Published var guardItemsGiven = false
    @Published var showingBelongingsReveal = false
    @Published var showingFormReveal = false

    let guardDialogue: [String] = [
        "You must be the investigator. I'm Jason Perry. I'll be escorting you through the facility.",
        "An inmate named Wayne Michaels died earlier this morning. Officially, it was cardiac arrest. You're here to confirm that.",
        "You can search two locations: his jail cell and the hospital room where he was found.",
        "Look around carefully. Hover over anything that catches your eye and click to collect it as evidence.",
        "Oh, before I forget. Here, take these. The victim's personal belongings and his prison intake form."
    ]

    var investigationAreas: [InvestigationArea] {
        switch currentRoom {
        case .hospitalRoom: return hospitalRoomAreas
        case .jailCell: return jailCellAreas
        }
    }

    init() {
        setupHospitalRoomAreas()
        setupJailCellAreas()
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
        // Evidence deferred until all guard popups are done
    }

    func dismissFormReveal() {
        showingFormReveal = false
    }

    func commitGuardEvidence(in gameState: GameState) {
        let belongings = Evidence(
            name: "Wayne's Belongings",
            description: "A sealed bag containing Wayne's personal items including his wallet and license. You'll need to examine this more closely later.",
            actDiscovered: 2,
            isRealEvidence: true,
            evidenceType: .physical,
            metadata: ["status": "sealed", "contents": "wallet, license, personal items"]
        )
        let intakeForm = Evidence(
            name: "Prison Intake Form",
            description: "Wayne's prison intake form. You'll need to examine it more closely later.",
            actDiscovered: 2,
            isRealEvidence: true,
            evidenceType: .document,
            metadata: ["status": "collected"]
        )
        gameState.addMultipleEvidence([belongings, intakeForm])
    }

    private func setupHospitalRoomAreas() {
        hospitalRoomAreas = [
            InvestigationArea(
                name: "Syringe",
                description: "A syringe found near the hospital bed",
                position: CGPoint(x: 290, y: 350),
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
                position: CGPoint(x: 512, y: 252),
                size: CGSize(width: 80, height: 60),
                imageName: "sedationClipboard",
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
                position: CGPoint(x: 90, y: 205),
                size: CGSize(width: 160, height: 160),
                imageName: "healthMonitor",
                evidence: Evidence(
                    name: "Vital Monitor Printout",
                    description: "A printout from the vital signs monitor. It shows Wayne still had a heart rate and oxygen levels at 3:00 AM. He was alive when found.",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .physical,
                    metadata: ["time": "3:00 AM", "status": "vitals present", "implication": "alive when found"]
                )
            )
        ]
    }

    private func setupJailCellAreas() {
        jailCellAreas = [
            InvestigationArea(
                name: "Crumbled Paper",
                description: "A crumbled piece of paper tucked under the bed",
                position: CGPoint(x: 300, y: 320),
                size: CGSize(width: 40, height: 35),
                imageName: "crumbledPaper",
                evidence: Evidence(
                    name: "Love Letter",
                    description: "A crumpled letter hidden under the bed. 'When I get out of here, I'm coming straight to you. You're the only good thing in this place.' Signed W.",
                    actDiscovered: 1,
                    isRealEvidence: true,
                    evidenceType: .document,
                    metadata: ["author": "Wayne Michaels", "recipient": "Kathy Williams", "tone": "romantic, personal"]
                )
            )
        ]
    }
    
    func searchArea(_ area: InvestigationArea, in gameState: GameState) {
        guard !gameState.isAreaSearched(area.name) else { return }

        Task { @MainActor in
            await Task.yield()

            if let evidence = area.evidence {
                gameState.collectEvidenceFromArea(evidence, areaName: area.name)
            } else {
                gameState.markAreaAsSearched(area.name)
            }
        }
    }
}

// scene investigation view
struct Act2SceneInvestigationView: View {
    @ObservedObject var viewModel: Act2InvestigationViewModel
    @EnvironmentObject private var gameState: GameState

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Room background
                RoomBackgroundView(room: viewModel.currentRoom)
                    .allowsHitTesting(false)

                // Interactive areas - positions scale to available space
                ForEach(viewModel.investigationAreas) { area in
                    InvestigationAreaView(
                        area: area,
                        isSearched: gameState.isAreaSearched(area.name),
                        onTap: {
                            viewModel.searchArea(area, in: gameState)
                        }
                    )
                    .position(
                        x: (area.position.x / 700) * geometry.size.width,
                        y: (area.position.y / 450) * geometry.size.height
                    )
                }

                VStack(spacing: 12) {
                    Picker("Location", selection: $viewModel.currentRoom) {
                        ForEach(InvestigationRoom.allCases, id: \.self) { room in
                            Text(room.rawValue).tag(room)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorScheme(.dark)
                }
                .padding(16)
                .background(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
                .cornerRadius(14)
                .padding()
                .frame(maxHeight: .infinity, alignment: .top)

                if viewModel.showingGuard {
                    GuardDialogueView(viewModel: viewModel)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .transition(.move(edge: .trailing))
                }

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
                        viewModel.dismissFormReveal()

                        Task { @MainActor in
                            await Task.yield()
                            viewModel.commitGuardEvidence(in: gameState)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
    }
}

// evidence pop up overlay
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

            VStack(spacing: 16) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Image(imageName)
                    .resizable()
                    .interpolation(.medium)
                    .scaledToFit()
                    .frame(width: 420, height: 320)
                    .clipped()
                    .cornerRadius(12)
                    .shadow(radius: 8)

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

// this is for the room background
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

}

// investigation area view
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

// evidence summary
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

// prison guard dialogue
struct GuardDialogueView: View {
    @ObservedObject var viewModel: Act2InvestigationViewModel

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Jason Perry")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.7))

                Text(viewModel.guardDialogue[viewModel.guardDialogueIndex])
                    .font(.title3)
                    .foregroundColor(.white)
                    .lineSpacing(8)

                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.advanceGuardDialogue()
                        }
                    } label: {
                        Text(viewModel.guardDialogueIndex < viewModel.guardDialogue.count - 1 ? "Continue" : "Got it")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .frame(maxWidth: 580)
            .background(Color.black.opacity(0.85))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

            Image("prisonGuard")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
        }
    }
}

#Preview {
    Act2InvestigationView()
        .environmentObject(GameState())
        //.frame(width: 800, height: 600)
}
