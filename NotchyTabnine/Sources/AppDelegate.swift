import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var floatingPanel: NSPanel!
    var terminalView: TerminalView!
    var tabnineProcess: Process!
    
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
    
    private func startTabnineSession() {
        terminalView.clear()
        terminalView.writeOutput("Initializing Tabnine agent...\n")
        
        // Start tabnine-agent process
        tabnineProcess = Process()
        tabnineProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/tabnine-agent")
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
            terminalView.writeOutput("Tabnine agent ready. Type /help for commands.\n\n")
        } catch {
            terminalView.writeOutput("Error: Could not start Tabnine. Is it installed?\n")
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
