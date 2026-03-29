import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var floatingPanel: NSPanel!
    var terminalView: TerminalView!
    var tabnineProcess: Process!
    var currentProjectPath: String?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupFloatingPanel()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: "NotchyTabnine")
            button.action = #selector(togglePanel)
            button.target = self
        }
    }
    
    private func setupFloatingPanel() {
        let panelWidth: CGFloat = 600
        let panelHeight: CGFloat = 400
        
        floatingPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        floatingPanel.title = "NotchyTabnine"
        floatingPanel.level = .floating
        floatingPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        floatingPanel.isMovableByWindowBackground = true
        floatingPanel.hidesOnDeactivate = false
        
        terminalView = TerminalView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight))
        floatingPanel.contentView = terminalView
        
        centerPanel()
    }
    
    private func centerPanel() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = floatingPanel.frame.size
        let x = screenFrame.midX - panelSize.width / 2
        let y = screenFrame.midY - panelSize.height / 2
        floatingPanel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    @objc private func togglePanel() {
        if floatingPanel.isVisible {
            floatingPanel.orderOut(nil)
        } else {
            centerPanel()
            floatingPanel.makeKeyAndOrderFront(nil)
            startTabnineSession()
        }
    }
    
    // MARK: - Project Detection
    
    /// Detects current project from frontmost editor (VSCode or Xcode)
    func detectCurrentProject() -> String? {
        // Try VSCode first
        if let vscodePath = detectVSCodeProject() {
            return vscodePath
        }
        
        // Try VSCode Insiders
        if let vscodeInsidersPath = detectVSCodeInsidersProject() {
            return vscodeInsidersPath
        }
        
        // Try Xcode
        if let xcodePath = detectXcodeProject() {
            return xcodePath
        }
        
        return nil
    }
    
    /// Detects project from VSCode by reading Recent Workspaces
    private func detectVSCodeProject() -> String? {
        // VSCode stores recent workspaces in com.apple.property-list XML format
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vscodeDir = appSupport.appendingPathComponent("Code/User/globalStorage/storage.json")
        
        // Try alternative: read from VSCode's state database
        let stateDb = appSupport.appendingPathComponent("Code/User/workspaceStorage")
        
        if FileManager.default.fileExists(atPath: stateDb.path) {
            // Read from workspace storage
            if let workspaces = try? FileManager.default.contentsOfDirectory(at: stateDb, includingPropertiesForKeys: nil) {
                for workspace in workspaces.prefix(1) {
                    let jsonFile = workspace.appendingPathComponent("window.json")
                    if let data = try? Data(contentsOf: jsonFile),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let folder = json["folder"] as? String {
                        return folder
                    }
                }
            }
        }
        
        // Alternative: Check environment variable set by VSCode terminal
        if let cwd = ProcessInfo.processInfo.environment["PWD"],
           FileManager.default.fileExists(atPath: cwd + "/.vscode") {
            return cwd
        }
        
        return nil
    }
    
    /// Detects project from VSCode Insiders
    private func detectVSCodeInsidersProject() -> String? {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let stateDb = appSupport.appendingPathComponent("Code - Insiders/User/workspaceStorage")
        
        if FileManager.default.fileExists(atPath: stateDb.path) {
            if let workspaces = try? FileManager.default.contentsOfDirectory(at: stateDb, includingPropertiesForKeys: nil) {
                for workspace in workspaces.prefix(1) {
                    let jsonFile = workspace.appendingPathComponent("window.json")
                    if let data = try? Data(contentsOf: jsonFile),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let folder = json["folder"] as? String {
                        return folder
                    }
                }
            }
        }
        
        return nil
    }
    
    /// Detects project from Xcode (similar to original Notchy)
    private func detectXcodeProject() -> String? {
        let workspace = NSWorkspace.shared.runningApplications.first {
            $0.bundleIdentifier == "com.apple.dt.Xcode"
        }
        
        guard let xcodeApp = workspace else { return nil }
        
        // Get Xcode's frontmost document
        if let xcodeDocs = xcodeApp.value(forKey: "recentDocuments") as? [Any] {
            for doc in xcodeDocs.prefix(1) {
                if let url = doc as? URL {
                    // Get the directory containing the .xcodeproj or .xcworkspace
                    let projectPath = url.deletingLastPathComponent().path
                    if projectPath.hasSuffix(".xcodeproj") || projectPath.hasSuffix(".xcworkspace") {
                        return projectPath
                    }
                    // Return directory if it's a source file
                    return url.deletingLastPathComponent().deletingLastPathComponent().path
                }
            }
        }
        
        return nil
    }
    
    /// Lists recent projects from common locations
    func listRecentProjects() -> [String] {
        var projects: [String] = []
        
        let searchPaths = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Developer"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Projects"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Code"),
        ]
        
        for searchPath in searchPaths {
            if let enumerator = FileManager.default.enumerator(at: searchPath, includingPropertiesForKeys: [.isDirectoryKey]) {
                for case let url as URL in enumerator {
                    if url.pathExtension == "xcodeproj" || url.pathExtension == "xcworkspace" || url.lastPathComponent == ".git" {
                        projects.append(url.deletingLastPathComponent().path)
                    }
                }
            }
        }
        
        return Array(Set(projects).prefix(20)) // Dedupe and limit
    }
    
    // MARK: - Tabnine Session
    
    private func startTabnineSession() {
        terminalView.clear()
        
        // Detect current project
        currentProjectPath = detectCurrentProject()
        
        terminalView.writeOutput("🔍 Detecting project...\n")
        
        if let project = currentProjectPath {
            terminalView.writeOutput("📁 Project: \(project)\n\n")
        } else {
            terminalView.writeOutput("⚠️  No project detected. Use /cd <path> to set project.\n\n")
        }
        
        terminalView.writeOutput("Initializing Tabnine agent...\n")
        
        // Start tabnine-agent with project directory
        tabnineProcess = Process()
        tabnineProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/tabnine-agent")
        
        // Set working directory if detected
        if let project = currentProjectPath {
            tabnineProcess.currentDirectoryURL = URL(fileURLWithPath: project)
        }
        
        tabnineProcess.arguments = ["--background"]
        
        let pipe = Pipe()
        tabnineProcess.standardOutput = pipe
        tabnineProcess.standardError = pipe
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTabnineOutput),
            name: FileHandle.readCompletionNotification,
            object: pipe.fileHandleForReading
        )
        
        pipe.fileHandleForReading.readInBackgroundAndNotify()
        
        do {
            try tabnineProcess.run()
            terminalView.writeOutput("Tabnine agent ready. Type /help for commands.\n")
            if currentProjectPath == nil {
                terminalView.writeOutput("Use /cd to set project directory.\n")
            }
            terminalView.writeOutput("\n")
        } catch {
            terminalView.writeOutput("Error: Could not start Tabnine. Is it installed?\n")
            terminalView.writeOutput("Run: brew install tabnine\n")
        }
    }
    
    @objc private func handleTabnineOutput(_ notification: Notification) {
        guard let data = notification.userInfo?[NSFileHandleNotificationDataKey] as? Data,
              let output = String(data: data, encoding: .utf8) else { return }
        
        DispatchQueue.main.async {
            self.terminalView.writeOutput(output)
        }
        
        if let handle = notification.object as? FileHandle {
            handle.readInBackgroundAndNotify()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        tabnineProcess?.terminate()
    }
}
