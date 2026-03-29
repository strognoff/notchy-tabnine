import AppKit

class TerminalView: NSView {
    private var textView: NSTextView!
    private var scrollView: NSScrollView!
    private var inputField: NSTextField!
    private var commandHistory: [String] = []
    private var historyIndex: Int = -1
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Output text view (scrollable)
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 40, width: bounds.width, height: bounds.height - 40))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        
        textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        textView.textColor = NSColor.white
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.autoresizingMask = [.width, .height]
        
        scrollView.documentView = textView
        addSubview(scrollView)
        
        // Input field
        inputField = NSTextField(frame: NSRect(x: 0, y: 5, width: bounds.width - 20, height: 30))
        inputField.target = self
        inputField.action = #selector(submitCommand)
        inputField.placeholderString = "Type Tabnine command..."
        inputField.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        inputField.backgroundColor = NSColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
        inputField.textColor = NSColor.white
        inputField.isBordered = true
        inputField.bezelStyle = .roundedBezel
        addSubview(inputField)
    }
    
    @objc private func submitCommand() {
        guard let command = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty else { return }
        
        writeOutput("$ \(command)\n")
        commandHistory.append(command)
        historyIndex = commandHistory.count
        inputField.stringValue = ""
        
        // Send to Tabnine via stdin - this would connect to the process
        NotificationCenter.default.post(name: .tabnineCommand, object: command)
    }
    
    func writeOutput(_ text: String) {
        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: NSColor.white,
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            ]
        )
        
        textView.textStorage?.append(attributedString)
        textView.scrollToEndOfDocument(nil)
    }
    
    func clear() {
        textView.string = ""
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 126: // Up arrow - history back
            if historyIndex > 0 {
                historyIndex -= 1
                inputField.stringValue = commandHistory[historyIndex]
            }
        case 125: // Down arrow - history forward
            if historyIndex < commandHistory.count - 1 {
                historyIndex += 1
                inputField.stringValue = commandHistory[historyIndex]
            } else {
                historyIndex = commandHistory.count
                inputField.stringValue = ""
            }
        default:
            super.keyDown(with: event)
        }
    }
}

extension Notification.Name {
    static let tabnineCommand = Notification.Name("tabnineCommand")
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
