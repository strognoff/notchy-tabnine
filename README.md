# NotchyTabnine

A macOS menu bar app that puts Tabnine CLI agent right in your MacBook's notch. Hover over the notch or click the menu bar icon to open a floating terminal panel with embedded Tabnine agent sessions.

![NotchyTabnine](https://img.shields.io/badge/macOS-14.0+-orange)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Platform](https://img.shields.io/badge/platform-macOS%20Menu%20Bar-orange)

## Features

- **Menu Bar App** — Click the terminal icon to open floating panel
- **Tabnine CLI Agent** — Run Tabnine agent sessions directly in the app
- **Auto Project Detection** — Automatically detects your open project from VSCode, VSCode Insiders, or Xcode
- **Notch Integration** — Hover over MacBook Pro notch to reveal panel (macOS 14+)
- **Multi-Session Tabs** — Run multiple Tabnine sessions side by side
- **Git Checkpoints** — Cmd+S to snapshot before Tabnine makes changes
- **Project Commands** — Built-in commands to navigate and detect projects

## Requirements

- macOS 14.0+ (Sonoma or later)
- MacBook with notch (MacBook Pro 14" or 16") for notch features
- [Tabnine CLI](https://docs.tabnine.com/main/getting-started/tabnine-cli) installed

## Installation

### Install Tabnine CLI

```bash
brew install tabnine
```

Verify installation:
```bash
tabnine --version
```

### Build from Source

1. **Install XcodeGen** (if not installed):
```bash
brew install xcodegen
```

2. **Generate Xcode project**:
```bash
xcodegen generate
```

3. **Open in Xcode**:
```bash
open NotchyTabnine.xcodeproj
```

4. **Build** (Cmd+B)

5. **Run** (Cmd+R)

## Usage

### First Launch

1. Click the terminal icon in the menu bar
2. NotchyTabnine auto-detects your open project from VSCode or Xcode
3. A floating panel appears with Tabnine agent ready in your project directory
4. Type `/help` to see available commands
5. Start coding!

### Project Auto-Detection

NotchyTabnine automatically detects your current project from:

1. **VSCode** — Reads from `~/Library/Application Support/Code/User/workspaceStorage/`
2. **VSCode Insiders** — Reads from `~/Library/Application Support/Code - Insiders/User/workspaceStorage/`
3. **Xcode** — Detects frontmost `.xcodeproj` or `.xcworkspace`

Priority order: VSCode → VSCode Insiders → Xcode (first one found wins)

### Commands

- `/help` — Show all available commands
- `/ask <question>` — Ask Tabnine anything about your code
- `/cd <path>` — Change project directory
- `/detect` — Re-detect current project from VSCode/Xcode
- `/projects` — List recent projects
- `/test` — Run tests in current directory
- `exit` — Close the session

### Keyboard Shortcuts

- `↑/↓` — Command history navigation
- `Cmd+T` — New Tabnine tab
- `Cmd+W` — Close current tab
- `Cmd+S` — Git checkpoint (save snapshot)
- `Cmd+,` — Preferences

## Architecture

```
NotchyTabnine/
├── Sources/
│   ├── main.swift              # App entry point
│   ├── AppDelegate.swift       # Menu bar, panel & project detection
│   └── TerminalView.swift      # Terminal UI component
├── Resources/
│   ├── Info.plist              # App configuration
│   └── NotchyTabnine.entitlements
└── project.yml                 # XcodeGen configuration
```

### Project Detection Flow

```
togglePanel()
    ↓
detectCurrentProject()
    ├── detectVSCodeProject()       → workspaceStorage/window.json
    ├── detectVSCodeInsidersProject()
    └── detectXcodeProject()       → runningApplications recentDocuments
    ↓
startTabnineSession(projectPath)
    ↓
Tabnine agent runs in project directory
```

## Dependencies

- **SwiftTerm** — Terminal emulator component (via SPM)
- **Tabnine CLI** — Backend AI coding assistant

## Troubleshooting

### Tabnine not found
Make sure Tabnine CLI is installed:
```bash
which tabnine
```

### Project not detected
- Make sure VSCode, VSCode Insiders, or Xcode is open with a folder/workspace
- Try `/detect` command to re-scan
- Use `/cd <path>` to manually set the project directory

### Notch not working
- Requires macOS 14.0+ and MacBook Pro with notch
- Check System Settings → Desktop & Dock → Automatically hide and show the Dock

## License

MIT License - see [LICENSE](LICENSE)

## Based On

- [Notchy](https://github.com/adamlyttleapps/notchy) by Adam Lyttle
- [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) by Miguel de Icaza

## Contributing

Contributions welcome! Please open an issue first for major changes.
