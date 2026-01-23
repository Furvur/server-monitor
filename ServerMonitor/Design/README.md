# Design System

This folder contains the design language and component exploration for ServerMonitor.

## Structure

```
Design/
├── DesignSystem.swift      # Design tokens (colors, typography, spacing)
├── ComponentCatalog.swift  # Gallery of all UI components
├── Candidates/             # Design alternatives being explored
│   └── *Candidates.swift   # e.g., StatCardCandidates.swift
├── Choices/                # Finalized design decisions
│   └── *Choice.swift       # e.g., StatCardChoice.swift
└── README.md               # This file
```

## Workflow

### 1. Design Tokens (DesignSystem.swift)

All design constants live here:
- `DSColor` - Status colors, semantic colors, backgrounds
- `DSTypography` - Font styles
- `DSSpacing` - Consistent spacing values (xxs through xxl)
- `DSRadius` - Corner radius values
- `DSDimension` - Component dimensions, window sizes

Use these tokens throughout the app for consistency.

### 2. Exploring Designs (Candidates/)

When designing a new component or redesigning an existing one:

1. Create a file named `{Component}Candidates.swift`
2. Implement 2-4 design alternatives as separate views
3. Add `#Preview` blocks to compare them side-by-side
4. Document pros/cons for each candidate
5. Use Xcode Canvas to iterate quickly

Example naming:
- `StatCardCandidates.swift`
- `ServerRowCandidates.swift`
- `MenuBarLayoutCandidates.swift`

### 3. Documenting Decisions (Choices/)

When a design is finalized:

1. Create `{Component}Choice.swift` in the Choices folder
2. Document the rationale for the chosen design
3. Note rejected alternatives and why
4. Include the final implementation

This creates a design decision log for the project.

### 4. Using Xcode Previews

Open the Canvas (Editor → Canvas or ⌥⌘↩) to:
- Compare candidates side-by-side
- Test components at different sizes
- Verify dark/light mode appearance
- Preview with sample data

Useful preview modifiers:
```swift
#Preview("Name") {
    MyView()
        .preferredColorScheme(.dark)  // Test dark mode
        .frame(width: 300)            // Fixed width
}
```

## Design Tokens Reference

### Colors
```swift
DSColor.online      // Green - server online
DSColor.offline     // Red - server offline
DSColor.warning     // Orange - warnings
DSColor.connecting  // Yellow - in progress
DSColor.unknown     // Gray - unknown state
```

### Spacing
```swift
DSSpacing.xxs  // 4pt
DSSpacing.xs   // 6pt
DSSpacing.sm   // 8pt
DSSpacing.md   // 12pt
DSSpacing.lg   // 16pt
DSSpacing.xl   // 20pt
DSSpacing.xxl  // 40pt
```

### Corner Radius
```swift
DSRadius.sm    // 6pt - small elements
DSRadius.md    // 8pt - cards, buttons
DSRadius.lg    // 12pt - large containers
```
