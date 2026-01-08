# TripleJumpAI

TripleJumpAI is an iOS application designed to help athletes and coaches analyze triple jump technique using biomechanical data extracted from video.

## Overview

This app serves as a client for a biomechanical analysis backend. It allows users to upload high-framerate videos of triple jumps, which are then processed to extract key performance metrics. The app provides detailed feedback, including phase-specific data (Hop, Skip, Jump) and visual overlays to identify technical flaws.

## Features

*   **Video Analysis:** Upload videos directly from your Photos library for processing.
*   **Biomechanical Metrics:** detailed breakdown of each phase (Hop, Skip, Jump):
    *   **Takeoff Angle:** Measurement of the takeoff angle in degrees.
    *   **Braking Force:** Estimation of braking forces during ground contact.
    *   **Torso Angle:** Analysis of body lean.
    *   **Peak Force:** Relative peak force estimation.
*   **AI Coach Feedback:** Automated textual feedback highlighting areas for improvement.
*   **Visual Analysis:** View the analyzed video with overlays (implied by the backend processing).
*   **Interactive Player:**
    *   **Zoom & Pan:** Pinch-to-zoom for close-up inspection of technique.
    *   **Scrubbing:** Frame-by-frame scrubbing with a marker for the "worst mistake" moment.
    *   **Slow Motion:** Playback controls for detailed review.
*   **Theming:** Toggle between "High Contrast" (Chartreuse) and "Matte Slate/Crimson" themes.
*   **Save & Share:** Save the analyzed video back to your Camera Roll.

## Tech Stack

*   **Language:** Swift
*   **Framework:** SwiftUI & UIKit
*   **Networking:** `URLSession` for communication with the Python/Flask backend.
*   **Media:** `AVKit`, `PhotosUI` for video playback and selection.

## Setup & Requirements

### Prerequisites
*   **Xcode:** 15.0 or later (for iOS 16+ support).
*   **iOS Device:** An iPhone or iPad running iOS 16.0 or later.
*   **Backend Server:** This app requires a running instance of the JumpMaster analysis server.

### Configuration
The API endpoint is currently configured in `swift_api_client.swift`.
```swift
// In JumpMasterAPI class
private let baseURL = "https://your-backend-url.com"
```
Ensure this URL points to your active analysis server.

## Usage

1.  **Launch the App:** Open TripleJumpAI on your device.
2.  **Check Status:** Ensure the "SYSTEM ONLINE" indicator is active.
3.  **Upload Video:** Tap "UPLOAD VIDEO" to select a triple jump video from your gallery.
    *   *Tip: Use high-framerate (slow-motion) video for best results.*
4.  **Wait for Analysis:** The app will upload the video and process it. Progress is shown on screen.
5.  **Review Results:**
    *   Read the "Coach Analysis" feedback.
    *   Review metrics for Hop, Skip, and Jump phases.
    *   Watch the analyzed video in the interactive player. Use the zoom and scrub features to examine specific movements.
6.  **Save:** Tap "SAVE TO CAMERA ROLL" to keep the analyzed video.

## License

[Insert License Information Here]
