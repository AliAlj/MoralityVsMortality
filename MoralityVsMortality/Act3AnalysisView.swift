import SwiftUI

// act 3 wrapper view
struct Act3AnalysisView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var lightsOn = false
    @State private var showBoard = false
    @State private var switchHovered = false
    @State private var showingRoomGuard = true
    @State private var roomGuardText = "Look around carefully. Hover over anything that catches your eyes and click to investigate."
    @State private var hasStartedRoomSound = false

    var body: some View {
        ZStack {
            // Room background
            Image(lightsOn ? "officeLightOn" : "officeLightOff")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            Color.black.opacity(lightsOn ? 0.1 : 0.5)
                .allowsHitTesting(false)

            // Light switch and bulletin (when not on board)
            if !showBoard {
                GeometryReader { geo in
                    // Light switch — top left area
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            lightsOn.toggle()
                        }
                    } label: {
                        Image(lightsOn ? "lightOn" : "lightOff")
                            .resizable()
                            .scaledToFit()
                            .frame(height: geo.size.height * 0.1)
                            .brightness(switchHovered ? 0.15 : -0.3)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in switchHovered = hovering }
                    .position(
                        x: geo.size.width * 0.05,
                        y: geo.size.height * 0.35
                    )

                    // Bulletin board — scales with window
                    OfficeBulletinButton {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showBoard = true
                        }
                    }
                    .frame(
                        width: geo.size.width * 0.448,
                        height: geo.size.height * 0.38
                    )
                    .position(
                        x: geo.size.width * 0.55,
                        y: geo.size.height * 0.30
                    )
                }
            }

            // Board overlay
            if showBoard {
                CaseBoardView(showBoard: $showBoard)
                    .environmentObject(gameState)
                    .transition(.opacity)
            }
            if showingRoomGuard {
                AnalysisGuardHintView(
                    hintText: roomGuardText,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showingRoomGuard = false
                        }
                    }
                )
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

        }
        
        .clipped()
        .task {
            guard !hasStartedRoomSound else { return }

            try? await Task.sleep(nanoseconds: 5_500_000_000)

            guard !hasStartedRoomSound else { return }
            hasStartedRoomSound = true
            AudioManager.shared.playDetectiveRoomSound()
        }
        .onDisappear {
            AudioManager.shared.stopDetectiveRoomSound()
        }
    }
}

// case board view
struct CaseBoardView: View {
    @EnvironmentObject private var gameState: GameState
    @Binding var showBoard: Bool

    @State private var selectedEvidence: [Evidence] = []
    @State private var selectedTool: AnalysisTool? = nil
    @State private var analysisResult: String = ""
    @State private var completedAnalyses: [AnalysisResult] = []
    @State private var magnifyingEvidence: Evidence? = nil
    @State private var belongingsStep: BelongingsStep? = nil
    @State private var showingGuardHint = false
    @State private var currentGuardHint = ""
    @State private var didShowInitialGuardHint = false
    @State private var didShowLicenseGuardHint = false

    enum BelongingsStep {
        case bag, wallet, license
    }

    var body: some View {
        ZStack {
            // Board background
            Image("officeBoard")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            Color.black.opacity(0.3)
                .allowsHitTesting(false)

            HStack(spacing: 0) {
                // Left side: Evidence on the board
                ScrollView {
                    VStack(spacing: 8) {
                        //Spacer()
                        Text("EVIDENCE")
                            .font(.custom("Times New Roman", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(2)
                            .padding(.top, 25)

                        ForEach(displayedEvidence) { evidence in
                            EvidenceBoardItem(
                                evidence: evidence,
                                isSelected: selectedEvidence.contains(where: { $0.id == evidence.id }),
                                onTap: {
                                    toggleEvidence(evidence)
                                },
                                onReveal: evidenceRevealAction(for: evidence),
                                revealButtonTitle: revealButtonTitle(for: evidence)
                            )
                        }
                    }
                    .padding(.top, 25)
                    .padding(.leading, 18)
                }
                .frame(width: 210)
                .background(Color.black.opacity(0.5))

                // Center: Results area
                VStack {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showBoard = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .buttonStyle(.plain)
                        .padding()
                    }
                    if !completedAnalyses.isEmpty {
                        StickyNotesBoardView(results: completedAnalyses, gameState: gameState)
                            .padding(.top, 10)
                    }

                    Spacer()

                    // Selected evidence display as image cards
                    if !selectedEvidence.isEmpty {
                        VStack(spacing: 12) {
                            HStack(spacing: 0) {
                                ForEach(Array(selectedEvidence.enumerated()), id: \.element.id) { index, ev in
                                    if index > 0 {
                                        // Connection indicator between cards
                                        VStack(spacing: 4) {
                                            if let tool = selectedTool {
                                                Image(systemName: tool.icon)
                                                    .font(.title3)
                                                    .foregroundColor(.blue)
                                            }
                                            Rectangle()
                                                .fill(Color.blue.opacity(0.5))
                                                .frame(width: 40, height: 2)
                                        }
                                        .padding(.horizontal, 8)
                                    }

                                    // Evidence card
                                    VStack(spacing: 6) {
                                        if let imageName = evidenceImageMap[ev.name] {
                                            Image(imageName)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 80)
                                                .clipped()
                                                .cornerRadius(8)
                                        }
                                        Text(ev.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    .padding(8)
                                    .background(Color.blue.opacity(0.25))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue.opacity(0.6), lineWidth: 1)
                                    )
                                }
                            }

                            if selectedTool != nil {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        performAnalysis()
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "wand.and.stars")
                                        Text("Analyze")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(14)
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Result
                    if !analysisResult.isEmpty {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: analysisResult.contains("doesn't reveal") ? "xmark.circle.fill" : "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(analysisResult.contains("doesn't reveal") ? .orange : .green)
                                .padding(.top, 2)

                            Text(analysisResult)
                                .font(.body)
                                .foregroundColor(.white)
                                .lineSpacing(4)
                        }
                        .padding(16)
                        .frame(maxWidth: 520)
                        .background(
                            (analysisResult.contains("doesn't reveal") ? Color.orange : Color.green)
                                .opacity(0.2)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    (analysisResult.contains("doesn't reveal") ? Color.orange : Color.green).opacity(0.4),
                                    lineWidth: 1
                                )
                        )
                        .padding(.top, 8)
                        .transition(.opacity)
                    }

                    // Completed analyses
                    if !completedAnalyses.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(completedAnalyses) { result in
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption2)
                                    Text(result.evidence.name)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.top, 8)
                    }

                    Spacer()

                    // Bottom tool bar
                    VStack(spacing: 8) {
                        Text("Select a tool, then pick evidence and hit Analyze.")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.6))

                        HStack(spacing: 10) {
                            ForEach(AnalysisTool.allCases.filter { $0 != .magnify }, id: \.rawValue) { tool in
                                Button {
                                    selectedTool = tool
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: tool.icon)
                                            .font(.title3)

                                        Text(tool.rawValue)
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(selectedTool == tool ? .white : .white.opacity(0.7))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .background(selectedTool == tool ? Color.blue.opacity(0.65) : Color.black.opacity(0.55))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if let tool = selectedTool {
                            Text(tool.description)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 500)
                        }
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.65))
                    .shadow(color: .black.opacity(0.85), radius: 12, x: 0, y: 5)                    .cornerRadius(12)
                    .padding(.bottom, 8)

                }
                .padding(.bottom, 25)
                .padding(.trailing,120)

                
            }
            // Analysis counter at top center
            HStack {
                Text("Analyses: \(gameState.analysisResults.count)/\(gameState.analysisCompletionTarget)")

                if gameState.analysisResults.count >= gameState.analysisCompletionTarget {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Text("— \(max(0, gameState.analysisCompletionTarget - gameState.analysisResults.count)) more needed")
                        .foregroundColor(.orange)
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 18)
            .padding(.leading, 20)
            //end

            // Magnify overlay
            if let evidence = magnifyingEvidence,
               let imageName = evidenceImageMap[evidence.name] {
                MagnifyOverlay(evidenceName: evidence.name, imageName: imageName) {
                    magnifyingEvidence = nil
                }
            }

            // Belongings opening sequence
            if let step = belongingsStep {
                ZStack {
                    Color.black.opacity(0.85)
                        .ignoresSafeArea()
                        .onTapGesture { advanceBelongingsStep() }

                    VStack(spacing: 16) {
                        Text(belongingsTitle(for: step))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Image(belongingsImage(for: step))
                            .resizable()
                            .interpolation(.medium)
                            .scaledToFit()
                            .frame(maxWidth: 500, maxHeight: 400)
                            .cornerRadius(12)
                            .shadow(radius: 20)

                        if step == .license {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                                Text("Wayne's License added to evidence.")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                        }

                        Text("Click anywhere to continue")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .onTapGesture { advanceBelongingsStep() }
                }
            }

            VStack(alignment: .trailing, spacing: 12) {


                if showingGuardHint {
                    AnalysisGuardHintView(
                        hintText: currentGuardHint,
                        onDismiss: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showingGuardHint = false
                            }
                        }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    Button {
                        showNextRelevantHint()
                    } label: {
                        Label("Ask Guard", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }

                if gameState.canProgressToNextAct {
                    Button("Continue →") {
                        gameState.progressToNextAct()
                    }
                    .actContinueButtonStyle()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 20)
            .padding(.bottom, 18)
            //come here 1
            
            
        }
        .onAppear {
            syncCompletedAnalyses()
            showInitialGuardHintIfNeeded()
        }
        .onChange(of: gameState.collectedEvidence.count) { _, _ in
            showLicenseHintIfNeeded()
        }
    }

    // Hide Wayne's Belongings once license is extracted; show Wayne's License instead
    private var displayedEvidence: [Evidence] {
        let hasLicense = gameState.hasEvidence(named: "Wayne's License")
        return gameState.collectedEvidence.filter(\.isRealEvidence).filter { evidence in
            if evidence.name == "Wayne's Belongings" && hasLicense { return false }
            return true
        }
    }

    private func evidenceRevealAction(for evidence: Evidence) -> (() -> Void)? {
        if evidence.name == "Wayne's Belongings" && !gameState.hasEvidence(named: "Wayne's License") {
            return { belongingsStep = .bag }
        }
        if evidenceImageMap[evidence.name] != nil {
            return { magnifyingEvidence = evidence }
        }
        return nil
    }

    private func revealButtonTitle(for evidence: Evidence) -> String? {
        if evidence.name == "Wayne's Belongings" && !gameState.hasEvidence(named: "Wayne's License") {
            return "Open"
        }
        if evidenceImageMap[evidence.name] != nil {
            return nil
        }
        return nil
    }

    private func toggleEvidence(_ evidence: Evidence) {
        if let index = selectedEvidence.firstIndex(where: { $0.id == evidence.id }) {
            selectedEvidence.remove(at: index)
        } else if selectedEvidence.count < 2 {
            selectedEvidence.append(evidence)
        } else {
            selectedEvidence.removeAll()
            selectedEvidence.append(evidence)
        }
    }

    private func performAnalysis() {
        guard !selectedEvidence.isEmpty,
              let tool = selectedTool else { return }

        // Comparison requires exactly 2 items selected
        if tool == .comparison && selectedEvidence.count < 2 {
            analysisResult = "Select two pieces of evidence to compare."
            return
        }

        // Capture selection before any state changes
        let selected = selectedEvidence
        selectedEvidence.removeAll()

        // Try analyzing each selected evidence with the tool
        var foundResult = false
        for evidence in selected {
            if let result = gameState.performAnalysis(evidenceID: evidence.id, tool: tool) {
                analysisResult = result
                recordCompletedAnalysis(for: evidence, tool: tool)
                foundResult = true
                break
            }
        }

        if !foundResult {
            analysisResult = "This doesn't reveal anything with this tool. Try a different combination."
        }
    }

    private func belongingsTitle(for step: BelongingsStep) -> String {
        switch step {
        case .bag: return "Wayne's Personal Belongings"
        case .wallet: return "Wayne's Wallet"
        case .license: return "Wayne's License"
        }
    }

    private func belongingsImage(for step: BelongingsStep) -> String {
        switch step {
        case .bag: return "waynesBelongings"
        case .wallet: return "waynesWallet"
        case .license: return "waynesLicense"
        }
    }

    private func advanceBelongingsStep() {
        switch belongingsStep {
        case .bag:
            belongingsStep = .wallet
        case .wallet:
            belongingsStep = .license
        case .license:
            belongingsStep = nil
            // Add Wayne's License as new evidence
            let license = Evidence(
                name: "Wayne's License",
                description: "Wayne's driver license. Organ donor field clearly reads NO.",
                actDiscovered: 3,
                isRealEvidence: true,
                evidenceType: .document,
                metadata: ["organ_donor": "NO"]
            )
            gameState.addEvidence(license)
        case nil:
            break
        }
    }

    private func showInitialGuardHintIfNeeded() {
        guard !didShowInitialGuardHint else { return }

        didShowInitialGuardHint = true
        presentGuardHint("This is your analysis board. Open Wayne's belongings first, then use the tools on the right to analyze the evidence. Select a tool, pick evidence, and hit Analyze.")
    }

    private func showLicenseHintIfNeeded() {
        guard gameState.hasEvidence(named: "Wayne's License"),
              !didShowLicenseGuardHint else { return }

        didShowLicenseGuardHint = true
        presentGuardHint("Good. Wayne's License is important. Compare it with the Prison Intake Form and look for what doesn't match.")
    }

    private func showNextRelevantHint() {
        if !gameState.hasEvidence(named: "Wayne's License") {
            presentGuardHint("Open Wayne's belongings first — click the \"Open\" button next to it on the left. You need what's inside.")
        } else if !hasCompletedLicenseComparison {
            presentGuardHint("Select the Comparison tool, then pick both Wayne's License and the Prison Intake Form from the evidence board. Hit Analyze and see what doesn't add up.")
        } else if !hasAnalyzed("Time Log") {
            presentGuardHint("Use the Timeline tool on the Time Log — it'll show you who was in Wayne's room and when. Then try Context Link on it too.")
        } else if !hasAnalyzed("Syringe") {
            presentGuardHint("Run Medical Analysis on the Syringe — see what was in it. Then use Context Link to tie it to the timeline.")
        } else if !hasAnalyzed("Sedation Chart") {
            presentGuardHint("The Sedation Chart needs Medical Analysis — check if the dosage was normal.")
        } else if !hasAnalyzed("Vital Monitor Printout") {
            presentGuardHint("Use Timeline on the Vital Monitor Printout — it shows Wayne was still alive at 3:00 AM.")
        } else if !hasAnalyzed("Love Letter") {
            presentGuardHint("Try Context Link on the Love Letter — it explains why Kathy was really there that night.")
        } else {
            presentGuardHint("You've uncovered a lot. Keep analyzing — every piece of evidence has something to reveal with the right tool.")
        }
    }

    private func hasAnalyzed(_ evidenceName: String) -> Bool {
        guard let evidence = gameState.collectedEvidence.first(where: { $0.name == evidenceName }) else { return false }
        return gameState.analysisResults[evidence.id.uuidString] != nil
    }

    private func syncCompletedAnalyses() {
        completedAnalyses = gameState.collectedEvidence.compactMap { evidence in
            guard gameState.analysisResults[evidence.id.uuidString] != nil else { return nil }
            return AnalysisResult(evidence: evidence, tool: .comparison)
        }
    }

    private func recordCompletedAnalysis(for evidence: Evidence, tool: AnalysisTool) {
        guard !completedAnalyses.contains(where: { $0.evidence.id == evidence.id }) else { return }
        completedAnalyses.append(AnalysisResult(evidence: evidence, tool: tool))
    }

    private func presentGuardHint(_ hint: String) {
        currentGuardHint = hint
        withAnimation(.easeInOut(duration: 0.25)) {
            showingGuardHint = true
        }
    }

    private var hasCompletedLicenseComparison: Bool {
        gameState.analysisResults.values.contains { result in
            result.contains("Organ Donor") || result.contains("doctored")
        }
    }
}

// evidence board item
struct EvidenceBoardItem: View {
    let evidence: Evidence
    let isSelected: Bool
    let onTap: () -> Void
    var onReveal: (() -> Void)?
    var revealButtonTitle: String?
    @State private var isHovered = false

    private var thumbnailName: String? { evidenceImageMap[evidence.name] }

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onTap) {
                VStack(spacing: 4) {
                    // Thumbnail
                    if let imageName = thumbnailName {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 50)
                            .clipped()
                            .cornerRadius(4)
                            .opacity(isHovered ? 1.0 : 0.8)
                    }

                    HStack {
                        Text(evidence.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
                .padding(6)
                .background(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(isHovered ? 0.2 : 0.1))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }

            // Secondary action for evidence that can be opened or viewed
            if let onReveal = onReveal {
                Button(action: onReveal) {
                    if let revealButtonTitle {
                        Text(revealButtonTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.65))
                            .cornerRadius(4)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        
    }
}

// supporting models
struct AnalysisResult: Identifiable {
    let evidence: Evidence
    let tool: AnalysisTool

    var id: UUID { evidence.id }
}

struct AnalysisGuardHintView: View {
    let hintText: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Jason Perry")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.7))

                Text(hintText)
                    .font(.title3)
                    .foregroundColor(.white)
                    .lineSpacing(8)

                HStack {
                    Spacer()
                    Button("Got it") {
                        onDismiss()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .frame(maxWidth: 580)
            .background(Color.black.opacity(0.88))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )

            Image("prisonGuard")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 260)
        }
    }
}
struct StickyNotesBoardView: View {
    let results: [AnalysisResult]
    let gameState: GameState

    private let notePositions: [CGPoint] = [
        CGPoint(x: 70, y: 60),
        CGPoint(x: 320, y: 90),
        CGPoint(x: 500, y: 65),
        CGPoint(x: 120, y: 250),
        CGPoint(x: 430, y: 275),

        CGPoint(x: 230, y: 210),
        CGPoint(x: 560, y: 220),
        CGPoint(x: 80, y: 370),
        CGPoint(x: 335, y: 380),
        CGPoint(x: 610, y: 360)
    ]

    private let noteRotations: [Double] = [
        -12, 8, -6, 10, -9,
        5, -7, 11, -4, 6
    ]

    var body: some View {
        ZStack {
            ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                if let text = gameState.analysisResults[result.evidence.id.uuidString] {
                    StickyNoteView(
                        title: result.evidence.name,
                        text: text
                    )
                    .rotationEffect(.degrees(noteRotations[index % noteRotations.count]))
                    .position(notePositions[index % notePositions.count])
                }
            }
        }
        .frame(width: 700, height: 420)
    }
}

struct StickyNoteView: View {
    let title: String
    let text: String

    @State private var showingFullText = false

    var body: some View {
        Button {
            showingFullText = true
        } label: {
            ZStack {
                Image("stickyNote")
                    .resizable()
                    .scaledToFit()

                VStack(spacing: 6) {
                    Text(title)
                        .font(.custom("Nanum Pen Script", size: 22))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Text(text)
                        .font(.custom("Nanum Pen Script", size: 18))
                        .foregroundColor(.black.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 10)
                }
                .padding(14)
            }
            .frame(width: 160, height: 160)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingFullText) {
            VStack(spacing: 18) {
                Text(title)
                    .font(.custom("Nanum Pen Script", size: 36))
                    .fontWeight(.bold)

                Text(text)
                    .font(.custom("Nanum Pen Script", size: 28))
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Close") {
                    showingFullText = false
                }
                .padding()
            }
            .frame(width: 500, height: 350)
        }
    }
}

// magnify overlay
struct MagnifyOverlay: View {
    let evidenceName: String
    let imageName: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(evidenceName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    // Zoom controls
                    HStack(spacing: 12) {
                        Button {
                            withAnimation { scale = max(0.5, scale - 0.25) }
                        } label: {
                            Image(systemName: "minus.magnifyingglass")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)

                        Text("\(Int(scale * 100))%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 40)

                        Button {
                            withAnimation { scale = min(4.0, scale + 0.25) }
                        } label: {
                            Image(systemName: "plus.magnifyingglass")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)

                        Button {
                            withAnimation {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        } label: {
                            Text("Reset")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color.black.opacity(0.5))

                // Zoomable image
                GeometryReader { geo in
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onScrollGesture { delta in
                            let newScale = scale + delta * 0.01
                            scale = max(0.5, min(4.0, newScale))
                        }
                }
            }
        }
    }
}

// Scroll gesture for zoom on macOS
#if os(macOS)
import AppKit

extension View {
    func onScrollGesture(action: @escaping (CGFloat) -> Void) -> some View {
        self.background(
            ScrollDetector(action: action)
        )
    }
}

struct ScrollDetector: NSViewRepresentable {
    let action: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = ScrollDetectorView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? ScrollDetectorView)?.action = action
    }
}

class ScrollDetectorView: NSView {
    var action: ((CGFloat) -> Void)?

    override func scrollWheel(with event: NSEvent) {
        action?(event.deltaY)
    }
}
#else
extension View {
    func onScrollGesture(action: @escaping (CGFloat) -> Void) -> some View {
        self
    }
}
#endif

// Office Bulletin Button
struct OfficeBulletinButton: View {
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            Image("officeBulletin")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .brightness(isHovered ? 0.15 : -0.3)
        }
//        .offset(x: -25, y: -100)
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    Act3AnalysisView()
        .environmentObject(GameState())
        .frame(width: 1100, height: 650)
}
