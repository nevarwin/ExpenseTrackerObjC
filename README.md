# ExpenseTracker

iOS expense tracking application with budget management and transaction tracking.

## Project Structure

### Active Projects
- **`ExpenseTracker.xcodeproj/`** - Main Objective-C project (CoreData)
- **`ExpenseTrackerSwift/`** - SwiftUI migration project (SwiftData) - used in feature branches

### Key Directories
- **`ExpenseTracker/`** - Objective-C source files
- **`Models/`** - CoreData model definitions
- **`ExpenseTrackerTests/`** - Unit tests
- **`ExpenseTrackerUITests/`** - UI tests

## Development

### Setup
1. Clone the repository
2. Open `ExpenseTracker.xcodeproj` in Xcode
3. Build and run (⌘R)

### Technology Stack
- **Language**: Objective-C
- **UI**: UIKit
- **Database**: CoreData
- **Platform**: iOS 14+

### Optional: MCP Servers
Developer tooling for Apple documentation (requires Node.js):
```bash
npm install
```

## Branches
- `main` - Stable Objective-C version
- `feature/swiftui-migration` - SwiftUI + SwiftData migration
- `swift-dev` - Swift development branch

## License
MIT
