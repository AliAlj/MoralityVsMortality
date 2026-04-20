import SwiftUI
import Combine

// MARK: - Act 3: Wrapper View
struct Act3AnalysisView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $selectedTab) {
                Text("Lab Analysis").tag(0)
                Text("Case Board").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                Act4LabAnalysisView()
            } else {
                Act5CaseBoardView()
            }
        }
    }
}

// MARK: - Act 4: Lab Analysis View Model
@MainActor
class Act4ViewModel: ObservableObject {
    @Published var selectedEvidence: Evidence?
    @Published var selectedTool: AnalysisTool?
    @Published var analysisInProgress: Bool = false
    @Published var currentAnalysisResult: String = ""
    @Published var completedAnalyses: [AnalysisResult] = []
    
    var gameState: GameState
    
    init(gameState: GameState) {
        self.gameState = gameState
        loadPreviousAnalyses()
    }
    
    private func loadPreviousAnalyses() {
        // Load any previously completed analyses from game state
        for (evidenceID, result) in gameState.analysisResults {
            if let uuid = UUID(uuidString: evidenceID),
               let evidence = gameState.getEvidence(by: uuid) {
                completedAnalyses.append(
                    AnalysisResult(
                        evidence: evidence,
                        tool: .uv, // This would need to be stored in game state
                        result: result
                    )
                )
            }
        }
    }
    
    func performAnalysis() {
        guard let evidence = selectedEvidence,
              let tool = selectedTool else { return }
        
        analysisInProgress = true
        
        // Simulate analysis time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let result = self.gameState.performAnalysis(evidenceID: evidence.id, tool: tool)
            
            if let result = result {
                self.currentAnalysisResult = result
                
                let analysisResult = AnalysisResult(
                    evidence: evidence,
                    tool: tool,
                    result: result
                )
                self.completedAnalyses.append(analysisResult)
                
                // Create new evidence for significant findings
                if self.isSignificantResult(result) {
                    let newEvidence = Evidence(
                        name: "Lab Result: \(evidence.name)",
                        description: result,
                        actDiscovered: 4,
                        isRealEvidence: true,
                        evidenceType: .analysis,
                        metadata: [
                            "original_evidence": evidence.name,
                            "analysis_tool": tool.rawValue,
                            "lab_certified": "true"
                        ]
                    )
                    self.gameState.addEvidence(newEvidence)
                }
            } else {
                self.currentAnalysisResult = "No significant results found with this tool."
            }
            
            self.analysisInProgress = false
        }
    }
    
    private func isSignificantResult(_ result: String) -> Bool {
        let significantKeywords = ["matches", "unknown", "detected", "profile", "tampering", "traces"]
        return significantKeywords.contains { result.lowercased().contains($0) }
    }
    
    func canAnalyze() -> Bool {
        guard let evidence = selectedEvidence,
              let tool = selectedTool else { return false }
        
        // Check if this combination has already been analyzed
        return !completedAnalyses.contains { analysis in
            analysis.evidence.id == evidence.id && analysis.tool == tool
        }
    }
    
    func clearSelection() {
        selectedEvidence = nil
        selectedTool = nil
        currentAnalysisResult = ""
    }
}

struct AnalysisResult: Identifiable {
    let id = UUID()
    let evidence: Evidence
    let tool: AnalysisTool
    let result: String
    let timestamp = Date()
}

// MARK: - Act 4: Lab Analysis View
struct Act4LabAnalysisView: View {
    @EnvironmentObject private var gameState: GameState
    @StateObject private var viewModel: Act4ViewModel
    
    init() {
        self._viewModel = StateObject(wrappedValue: Act4ViewModel(gameState: GameState()))
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Evidence selection
            VStack(alignment: .leading) {
                Text("🧪 **Lab Analysis**")
                    .font(.headline)
                    .padding(.bottom)
                
                Text("Select Evidence")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(gameState.collectedEvidence.filter(\.isRealEvidence)) { evidence in
                            EvidenceSelectionCard(
                                evidence: evidence,
                                isSelected: viewModel.selectedEvidence?.id == evidence.id,
                                onSelect: {
                                    viewModel.selectedEvidence = evidence
                                }
                            )
                        }
                    }
                }
                .frame(maxHeight: 300)
                
                Divider()
                
                Text("Select Analysis Tool")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                    ForEach(AnalysisTool.allCases, id: \.rawValue) { tool in
                        ToolSelectionCard(
                            tool: tool,
                            isSelected: viewModel.selectedTool == tool,
                            onSelect: {
                                viewModel.selectedTool = tool
                            }
                        )
                    }
                }
            }
            .frame(width: 300)
            
            // Analysis workspace
            VStack {
                // Current analysis setup
                AnalysisWorkspaceView(viewModel: viewModel)
                
                Divider()
                
                // Results history
                AnalysisHistoryView(results: viewModel.completedAnalyses)
            }
        }
        .padding()
        .onAppear {
            viewModel.gameState = gameState
        }
    }
}

struct EvidenceSelectionCard: View {
    let evidence: Evidence
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(evidence.name)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Text(evidence.evidenceType.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct ToolSelectionCard: View {
    let tool: AnalysisTool
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: toolIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(tool.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var toolIcon: String {
        switch tool {
        case .uv: return "lightbulb.fill"
        case .dna: return "dollarsign.circle"
        case .blood: return "drop.fill"
        case .fingerprint: return "hand.point.up.braille.fill"
        case .microscope: return "eye.circle.fill"
        }
    }
}

struct AnalysisWorkspaceView: View {
    @ObservedObject var viewModel: Act4ViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Analysis Workspace")
                .font(.headline)
            
            // Current setup display
            HStack {
                VStack(alignment: .leading) {
                    Text("Evidence:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.selectedEvidence?.name ?? "None selected")
                        .font(.body)
                }
                
                Image(systemName: "plus")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading) {
                    Text("Tool:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.selectedTool?.rawValue ?? "None selected")
                        .font(.body)
                }
                
                Spacer()
                
                Button(action: viewModel.performAnalysis) {
                    if viewModel.analysisInProgress {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Analyze")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canAnalyze() || viewModel.analysisInProgress)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Selected tool description
            if let tool = viewModel.selectedTool {
                Text(tool.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Current result
            if !viewModel.currentAnalysisResult.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Analysis Result:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(viewModel.currentAnalysisResult)
                        .font(.body)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
    }
}

struct AnalysisHistoryView: View {
    let results: [AnalysisResult]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Previous Analyses (\(results.count))")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if results.isEmpty {
                Text("No analyses completed yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(results) { result in
                            AnalysisResultCard(result: result)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
    }
}

struct AnalysisResultCard: View {
    let result: AnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.evidence.name)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text(result.tool.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(result.result)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
    }
}

// TODO: Expand this view with:
// - 3D molecular models for DNA analysis
// - Spectrograph displays for chemical analysis
// - Comparison tools for fingerprint matching
// - Time-lapse photography for UV analysis
// - Database search functionality
// - Quality scores for analysis confidence
// - Cross-reference with known evidence databases

#Preview {
    Act4LabAnalysisView()
        .environmentObject(GameState())
}

import SwiftUI

import SwiftUI
import Combine

// MARK: - Act 5: Case Board View Model
@MainActor
class Act5ViewModel: ObservableObject {
    @Published var evidenceNodes: [EvidenceNode] = []
    @Published var connectionLines: [ConnectionLine] = []
    @Published var selectedEvidence: Set<UUID> = []
    @Published var availableConnectionTypes: [EvidenceConnection.ConnectionType] = EvidenceConnection.ConnectionType.allCases
    @Published var isConnecting: Bool = false
    @Published var connectionFeedback: String = ""
    
    var gameState: GameState
    private let boardSize = CGSize(width: 800, height: 600)
    
    init(gameState: GameState) {
        self.gameState = gameState
        setupEvidenceNodes()
        updateConnectionLines()
    }
    
    private func setupEvidenceNodes() {
        // Arrange evidence in a grid pattern with some randomization
        let evidence = gameState.collectedEvidence.filter(\.isRealEvidence)
        let columns = 4
        let rows = (evidence.count + columns - 1) / columns
        
        evidenceNodes = evidence.enumerated().map { index, evidence in
            let col = index % columns
            let row = index / columns
            
            let baseX = (boardSize.width / CGFloat(columns + 1)) * CGFloat(col + 1)
            let baseY = (boardSize.height / CGFloat(rows + 1)) * CGFloat(row + 1)
            
            // Add some randomization to make it look more organic
            let offsetX = CGFloat.random(in: -30...30)
            let offsetY = CGFloat.random(in: -30...30)
            
            return EvidenceNode(
                evidence: evidence,
                position: CGPoint(x: baseX + offsetX, y: baseY + offsetY),
                isSelected: false
            )
        }
    }
    
    private func updateConnectionLines() {
        connectionLines = gameState.evidenceConnections.compactMap { connection in
            guard let node1 = evidenceNodes.first(where: { $0.evidence.id == connection.evidence1ID }),
                  let node2 = evidenceNodes.first(where: { $0.evidence.id == connection.evidence2ID }) else {
                return nil
            }
            
            return ConnectionLine(
                connection: connection,
                startPoint: node1.position,
                endPoint: node2.position
            )
        }
    }
    
    func selectEvidence(_ evidence: Evidence) {
        if selectedEvidence.contains(evidence.id) {
            selectedEvidence.remove(evidence.id)
        } else if selectedEvidence.count < 2 {
            selectedEvidence.insert(evidence.id)
        } else {
            // Replace selection
            selectedEvidence.removeAll()
            selectedEvidence.insert(evidence.id)
        }
        
        updateNodeSelection()
    }
    
    private func updateNodeSelection() {
        for i in evidenceNodes.indices {
            evidenceNodes[i].isSelected = selectedEvidence.contains(evidenceNodes[i].evidence.id)
        }
    }
    
    func createConnection(type: EvidenceConnection.ConnectionType) {
        guard selectedEvidence.count == 2 else { return }
        
        let evidenceIDs = Array(selectedEvidence)
        let evidence1ID = evidenceIDs[0]
        let evidence2ID = evidenceIDs[1]
        
        // Check if connection already exists
        let connectionExists = gameState.evidenceConnections.contains { connection in
            (connection.evidence1ID == evidence1ID && connection.evidence2ID == evidence2ID) ||
            (connection.evidence1ID == evidence2ID && connection.evidence2ID == evidence1ID)
        }
        
        if connectionExists {
            connectionFeedback = "Connection already exists between these evidence pieces."
            return
        }
        
        gameState.createConnection(evidence1ID: evidence1ID, evidence2ID: evidence2ID, type: type)
        updateConnectionLines()
        
        let newConnection = gameState.evidenceConnections.last!
        connectionFeedback = newConnection.isCorrect ?
            "✅ Correct connection! This link is valid." :
            "❌ This connection doesn't seem right. Try a different relationship."
        
        selectedEvidence.removeAll()
        updateNodeSelection()
        
        // Clear feedback after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.connectionFeedback.contains("✅") || self.connectionFeedback.contains("❌") {
                self.connectionFeedback = ""
            }
        }
    }
    
    func removeConnection(_ connection: EvidenceConnection) {
        gameState.removeConnection(connection)
        updateConnectionLines()
        connectionFeedback = "Connection removed."
    }
    
    func getNodePosition(for evidenceID: UUID) -> CGPoint? {
        evidenceNodes.first { $0.evidence.id == evidenceID }?.position
    }
}

struct EvidenceNode {
    let evidence: Evidence
    let position: CGPoint
    var isSelected: Bool
}

struct ConnectionLine {
    let connection: EvidenceConnection
    let startPoint: CGPoint
    let endPoint: CGPoint
}

// MARK: - Act 5: Case Board View
struct Act5CaseBoardView: View {
    @EnvironmentObject private var gameState: GameState
    @StateObject private var viewModel: Act5ViewModel
    
    init() {
        self._viewModel = StateObject(wrappedValue: Act5ViewModel(gameState: GameState()))
    }
    
    var body: some View {
        VStack {
            // Header and controls
            HStack {
                Text("🕸️ **Case Board**")
                    .font(.headline)
                
                Spacer()
                
                Text("Connect related evidence • \(gameState.correctConnectionsCount) correct connections")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Main board area
            ZStack {
                // Background
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .border(Color.gray, width: 1)
                
                // Connection lines
                ForEach(viewModel.connectionLines, id: \.connection.id) { line in
                    ConnectionLineView(line: line) {
                        viewModel.removeConnection(line.connection)
                    }
                }
                
                // Evidence nodes
                ForEach(viewModel.evidenceNodes, id: \.evidence.id) { node in
                    EvidenceNodeView(
                        node: node,
                        onTap: {
                            viewModel.selectEvidence(node.evidence)
                        }
                    )
                    .position(node.position)
                }
            }
            .frame(height: 500)
            
            // Connection controls
            if viewModel.selectedEvidence.count == 2 {
                ConnectionControlsView(
                    connectionTypes: viewModel.availableConnectionTypes,
                    onConnect: viewModel.createConnection
                )
                .padding()
            } else {
                Text(viewModel.selectedEvidence.isEmpty ?
                     "Select two evidence pieces to create a connection" :
                     "Select one more evidence piece")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            // Feedback
            if !viewModel.connectionFeedback.isEmpty {
                Text(viewModel.connectionFeedback)
                    .font(.body)
                    .padding()
                    .background(
                        viewModel.connectionFeedback.contains("✅") ?
                        Color.green.opacity(0.2) : Color.red.opacity(0.2)
                    )
                    .cornerRadius(8)
                    .animation(.easeInOut, value: viewModel.connectionFeedback)
            }
            
            // Progress summary
            CaseBoardSummaryView()
        }
        .onAppear {
            viewModel.gameState = gameState
        }
    }
}

struct EvidenceNodeView: View {
    let node: EvidenceNode
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Evidence type icon
                Image(systemName: evidenceIcon)
                    .font(.title3)
                    .foregroundColor(node.isSelected ? .white : .primary)
                
                Text(node.evidence.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(node.isSelected ? .white : .primary)
                    .lineLimit(2)
            }
            .frame(width: 80, height: 80)
            .background(
                Circle()
                    .fill(node.isSelected ? Color.blue : Color.white)
                    .overlay(
                        Circle().stroke(Color.primary, lineWidth: node.isSelected ? 3 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .shadow(radius: node.isSelected ? 5 : 2)
    }
    
    private var evidenceIcon: String {
        switch node.evidence.evidenceType {
        case .physical: return "cube.fill"
        case .document: return "doc.text.fill"
        case .timestamp: return "clock.fill"
        case .analysis: return "flask.fill"
        case .connection: return "link"
        }
    }
}

struct ConnectionLineView: View {
    let line: ConnectionLine
    let onRemove: () -> Void
    
    var body: some View {
        ZStack {
            // Connection line
            Path { path in
                path.move(to: line.startPoint)
                path.addLine(to: line.endPoint)
            }
            .stroke(
                line.connection.isCorrect ? Color.green : Color.red,
                style: StrokeStyle(
                    lineWidth: line.connection.isCorrect ? 3 : 2,
                    lineCap: .round,
                    dash: line.connection.isCorrect ? [] : [5, 5]
                )
            )
            
            // Connection type label and remove button
            let midPoint = CGPoint(
                x: (line.startPoint.x + line.endPoint.x) / 2,
                y: (line.startPoint.y + line.endPoint.y) / 2
            )
            
            HStack(spacing: 4) {
                Text(line.connection.connectionType.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .cornerRadius(4)
                    .shadow(radius: 1)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Color.white, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .position(midPoint)
        }
    }
}

struct ConnectionControlsView: View {
    let connectionTypes: [EvidenceConnection.ConnectionType]
    let onConnect: (EvidenceConnection.ConnectionType) -> Void
    
    var body: some View {
        VStack {
            Text("Create Connection")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(connectionTypes, id: \.rawValue) { type in
                    Button(action: { onConnect(type) }) {
                        VStack {
                            Image(systemName: connectionIcon(for: type))
                                .font(.title2)
                            Text(type.rawValue)
                                .font(.caption)
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func connectionIcon(for type: EvidenceConnection.ConnectionType) -> String {
        switch type {
        case .timeline: return "clock"
        case .location: return "location"
        case .person: return "person"
        case .method: return "wrench"
        case .motive: return "target"
        }
    }
}

struct CaseBoardSummaryView: View {
    @EnvironmentObject private var gameState: GameState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Evidence Pieces: \(gameState.realEvidenceCount)")
                Text("Connections: \(gameState.evidenceConnections.count)")
                Text("Correct: \(gameState.correctConnectionsCount)")
            }
            .font(.caption)
            
            Spacer()
            
            if gameState.canProgressToNextAct {
                VStack(alignment: .trailing) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Case Analysis Complete")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// TODO: Expand this view with:
// - Drag and drop to reposition evidence
// - Zoom and pan capabilities for large case boards
// - Evidence grouping and clustering
// - Timeline view mode
// - Export case board as image
// - Collaborative features for team investigations
// - AI-suggested connections
// - Evidence filtering and search

#Preview {
    Act5CaseBoardView()
        .environmentObject(GameState())
}
