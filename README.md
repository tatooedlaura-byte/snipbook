# Snipbook

**Little Moments, Cut & Kept.**

A camera-first, shape-based junk journal app for iOS. Collect everyday ephemera with zero design pressure.

## Features

- **Shape-based capture**: Choose from 6 unique shapes (stamp, circle, ticket, label, torn paper, rectangle)
- **Instant masking**: Photos are automatically cut to shape with transparent backgrounds
- **Organic book layout**: Snips are placed with subtle randomness for a handmade feel
- **Zero friction**: No accounts, no social features, no complexity
- **PDF export**: Share your collection as a beautiful PDF

## Architecture

```
Snipbook/
├── App/
│   └── SnipbookApp.swift          # App entry point & SwiftData container
├── Models/
│   ├── ShapeType.swift            # Shape enum with metadata
│   ├── Snip.swift                 # Individual cut-out with masked image
│   ├── Page.swift                 # Book page (holds 1-2 snips)
│   └── Book.swift                 # Collection of pages
├── Views/
│   ├── BookView.swift             # Main scrollable book view
│   ├── PageView.swift             # Single page with snips
│   ├── SnipView.swift             # Individual snip display
│   ├── ShapePickerView.swift      # Shape selection sheet
│   ├── CaptureView.swift          # Camera/import with shape overlay
│   ├── CameraPreviewView.swift    # AVFoundation preview wrapper
│   └── SettingsView.swift         # Settings & export
├── Services/
│   ├── CameraService.swift        # AVFoundation camera management
│   └── ImageMaskingService.swift  # Core Graphics masking logic
├── Shapes/
│   ├── ShapePaths.swift           # Vector path definitions
│   └── SnipShape.swift            # SwiftUI Shape wrapper
├── Extensions/
│   └── Color+App.swift            # App color palette
└── Resources/
    └── Info.plist                 # Permissions & app config
```

## Core Flow

1. **BookView** → User taps + button
2. **ShapePickerView** → User selects a shape
3. **CaptureView** → Camera preview with shape overlay
4. **ImageMaskingService** → Masks photo to shape (transparent PNG)
5. **Book.addSnip()** → Adds to current/new page
6. **BookView** → Shows updated book with new snip

## Key Implementation Details

### Image Masking (The Magic)

```swift
// ImageMaskingService.swift
func maskImage(_ image: UIImage, with shapeType: ShapeType) -> Data? {
    // 1. Create CGContext with alpha channel
    // 2. Add shape path as clipping mask
    // 3. Draw image within clipped area
    // 4. Export as PNG with transparency
}
```

### Shape Paths

All shapes are defined as `SwiftUI.Path` in `ShapePaths.swift`:
- **Postage Stamp**: Scalloped edges using arcs
- **Circle**: Simple ellipse
- **Ticket**: Rounded rect with side notches
- **Label**: Tag shape with hole
- **Torn Paper**: Organic bezier blob
- **Rectangle**: Rounded rectangle

### Data Persistence

Uses SwiftData with three models:
- `Book` → has many `Page`
- `Page` → has 1-2 `Snip`
- `Snip` → stores masked PNG data (`.externalStorage`)

## Setup in Xcode

1. Create new iOS App project in Xcode
2. Copy all Swift files maintaining folder structure
3. Add Info.plist permissions
4. Set deployment target to iOS 17.0+
5. Build and run

## Requirements

- iOS 17.0+
- Xcode 15+
- Swift 5.9+

## Philosophy

> This app is about:
> - **collecting**, not creating
> - **keeping**, not perfecting
> - **moments**, not metrics

If a feature adds friction, remove it.

## Future Ideas

- Multiple books
- Optional captions
- More shape variety
- iCloud sync
- Widget showing random snip
