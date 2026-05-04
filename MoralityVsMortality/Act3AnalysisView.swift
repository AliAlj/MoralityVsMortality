import SwiftUI

// act 3 wrapper view
struct Act3AnalysisView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var lightsOn = false
    @State private var showBoard = false
    @State private var switchHovered = false

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

        }
        .clipped()
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
                        Text("EVIDENCE")
                            .font(.custom("Times New Roman", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(2)
                            .padding(.top, 8)

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
                    .padding(10)
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

                    Spacer()

                    // Selected evidence display
                    if !selectedEvidence.isEmpty {
                        HStack(spacing: 12) {
                            ForEach(selectedEvidence) { ev in
                                Text(ev.name)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.4))
                                    .cornerRadius(6)
                            }

                            if selectedTool != nil {
                                Button("Analyze") {
                                    performAnalysis()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    }

                    // Result
                    if !analysisResult.isEmpty {
                        Text(analysisResult)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: 500)
                            .background(Color.green.opacity(0.3))
                            .cornerRadius(10)
                            .padding(.top, 8)
                    }

                    // Completed analyses
                    if !completedAnalyses.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(completedAnalyses) { result in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    Text("\(result.tool.rawValue): \(result.evidence.name)")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding(.top, 8)
                    }

                    Spacer()

                    // Progress
                    VStack(spacing: 8) {
                        HStack {
                            Text("Analyses: \(gameState.analysisResults.count)")
                            if gameState.analysisResults.count >= gameState.analysisCompletionTarget {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Ready to continue")
                                    .foregroundColor(.green)
                            } else {
                                Text("Need \(max(0, gameState.analysisCompletionTarget - gameState.analysisResults.count)) more")
                                    .foregroundColor(.orange)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)

                        if gameState.canProgressToNextAct {
                            Button {
                                gameState.progressToNextAct()
                            } label: {
                                HStack {
                                    Text("Continue to Act IV")
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.bottom, 10)
                }

                // Right side: Tools
                VStack(spacing: 8) {
                    Text("TOOLS")
                        .font(.custom("Times New Roman", size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(2)
                        .padding(.top, 8)

                    ForEach(AnalysisTool.allCases, id: \.rawValue) { tool in
                        Button {
                            selectedTool = tool
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tool.icon)
                                    .font(.title3)
                                    .foregroundColor(selectedTool == tool ? .white : .white.opacity(0.6))
                                Text(tool.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(selectedTool == tool ? .white : .white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 65)
                            .background(selectedTool == tool ? Color.blue.opacity(0.6) : Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Tool description
                    if let tool = selectedTool {
                        Text(tool.description)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(8)
                    }
                }
                .frame(width: 130)
                .padding(10)
                .background(Color.black.opacity(0.5))
            }

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

            if showingGuardHint {
                AnalysisGuardHintView(
                    hintText: currentGuardHint,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showingGuardHint = false
                        }
                    }
                )
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
        .onAppear {
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

        // Magnify tool opens zoom view instead of analyzing
        if tool == .magnify {
            magnifyingEvidence = selectedEvidence.first
            selectedEvidence.removeAll()
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
                completedAnalyses.append(
                    AnalysisResult(evidence: evidence, tool: tool)
                )
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
        presentGuardHint("Start with the belongings bag I gave you. If Wayne kept anything personal on him, it may tell you more than the paperwork does.")
    }

    private func showLicenseHintIfNeeded() {
        guard gameState.hasEvidence(named: "Wayne's License") else { return }
        guard !didShowLicenseGuardHint else { return }
        didShowLicenseGuardHint = true
        presentGuardHint("That license looks off compared to the intake form. Put those two side by side and see what doesn't match.")
    }

    private func showNextRelevantHint() {
        if !gameState.hasEvidence(named: "Wayne's License") {
            presentGuardHint("Try opening Wayne's belongings first. The bag itself isn't the important part.")
        } else if !hasCompletedLicenseComparison {
            presentGuardHint("The license and the intake form are telling two different stories. Compare those documents.")
        } else {
            presentGuardHint("Look for contradictions in the records, then tie them back to the timeline and medical evidence.")
        }
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
    let id = UUID()
    let evidence: Evidence
    let tool: AnalysisTool
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
