import SwiftUI
import Combine

// MARK: - Act 3: Wrapper View
struct Act3AnalysisView: View {
    @EnvironmentObject private var gameState: GameState
    @State private var lightsOn = false
    @State private var showBoard = false

    var body: some View {
        ZStack {
            // Room background
            Image(lightsOn ? "officeLightOn" : "officeLightOff")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            Color.black.opacity(lightsOn ? 0.1 : 0.5)

            // Light switch and bulletin (when not on board)
            if !showBoard {
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                lightsOn.toggle()
                            }
                        } label: {
                            Image(lightsOn ? "lightOn" : "lightOff")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 60)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 40)

                        Spacer()
                    }
                    Spacer()
                }

                OfficeBulletinButton {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showBoard = true
                    }
                }
            }

            // Board overlay
            if showBoard {
                CaseBoardView(showBoard: $showBoard)
                    .environmentObject(gameState)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Case Board View
struct CaseBoardView: View {
    @EnvironmentObject private var gameState: GameState
    @Binding var showBoard: Bool

    @State private var selectedEvidence: [Evidence] = []
    @State private var selectedTool: AnalysisTool? = nil
    @State private var analysisResult: String = ""
    @State private var completedAnalyses: [AnalysisResult] = []
    @State private var showingLoveLetter = false

    var body: some View {
        ZStack {
            // Board background
            Image("officeBoard")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            Color.black.opacity(0.3)

            HStack(spacing: 0) {
                // Left side: Evidence on the board
                ScrollView {
                    VStack(spacing: 8) {
                        Text("EVIDENCE")
                            .font(.custom("Times New Roman", size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(2)
                            .padding(.top, 8)

                        ForEach(gameState.collectedEvidence.filter(\.isRealEvidence)) { evidence in
                            EvidenceBoardItem(
                                evidence: evidence,
                                isSelected: selectedEvidence.contains(where: { $0.id == evidence.id }),
                                onTap: {
                                    toggleEvidence(evidence)
                                },
                                onReveal: evidence.name == "Love Letter" ? {
                                    showingLoveLetter = true
                                } : nil
                            )
                        }
                    }
                    .padding(10)
                }
                .frame(width: 180)
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

                            if selectedEvidence.count == 2 && selectedTool != nil {
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
                    HStack {
                        Text("Analyses: \(completedAnalyses.count)")
                        Text("Connections: \(gameState.correctConnectionsCount)")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
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

            // Love letter overlay
            if showingLoveLetter {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingLoveLetter = false
                        }

                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                showingLoveLetter = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            .padding()
                        }

                        Image("loveLetter")
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
        guard selectedEvidence.count == 2,
              let tool = selectedTool else { return }

        // Capture selection before any state changes
        let selected = selectedEvidence
        let e1 = selected[0]
        let e2 = selected[1]
        selectedEvidence.removeAll()

        // Try analyzing each selected evidence with the tool
        var foundResult = false
        for evidence in selected {
            if let result = gameState.performAnalysis(evidenceID: evidence.id, tool: tool) {
                analysisResult = result
                completedAnalyses.append(
                    AnalysisResult(evidence: evidence, tool: tool, result: result)
                )
                foundResult = true
                break
            }
        }

        if !foundResult {
            analysisResult = "These pieces don't reveal anything with this tool. Try a different combination."
        }

        // Also create a connection between the two evidence pieces
        let connectionExists = gameState.evidenceConnections.contains { c in
            (c.evidence1ID == e1.id && c.evidence2ID == e2.id) ||
            (c.evidence1ID == e2.id && c.evidence2ID == e1.id)
        }
        if !connectionExists && foundResult {
            let connectionType: EvidenceConnection.ConnectionType
            switch tool {
            case .comparison: connectionType = .method
            case .timeline: connectionType = .timeline
            case .medical: connectionType = .method
            case .contextLink: connectionType = .person
            }
            gameState.createConnection(evidence1ID: e1.id, evidence2ID: e2.id, type: connectionType)
        }
    }
}

// MARK: - Evidence Board Item
struct EvidenceBoardItem: View {
    let evidence: Evidence
    let isSelected: Bool
    let onTap: () -> Void
    var onReveal: (() -> Void)?
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onTap) {
                HStack {
                    Text(evidence.name)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                .padding(8)
                .background(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(isHovered ? 0.2 : 0.1))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.blue : Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }

            // Reveal button for love letter
            if let onReveal = onReveal {
                Button(action: onReveal) {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Supporting Models
struct AnalysisResult: Identifiable {
    let id = UUID()
    let evidence: Evidence
    let tool: AnalysisTool
    let result: String
}

// MARK: - Office Bulletin Button
struct OfficeBulletinButton: View {
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            Image("officeBulletin")
                .resizable()
                .scaledToFit()
                .frame(height: 270)
                .brightness(isHovered ? 0.15 : 0)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(isHovered ? 0.6 : 0), lineWidth: 2)
                        .shadow(color: .white.opacity(isHovered ? 0.4 : 0), radius: 8)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    Act3AnalysisView()
        .environmentObject(GameState())
        .frame(width: 800, height: 550)
}
