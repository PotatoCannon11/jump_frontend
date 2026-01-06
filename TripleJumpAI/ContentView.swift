import SwiftUI
import PhotosUI
import Photos
import AVKit

// MARK: - 1. Theme Extensions
extension Color {
    // Original Theme
    static let chartreuse = Color(red: 0.87, green: 1.0, blue: 0.0)
    static let darkCard = Color(white: 0.12)
    
    // New Theme (Matte Slate / Crimson)
    static let matteSlate = Color(red: 30/255, green: 41/255, blue: 59/255)
    static let crimson = Color(red: 220/255, green: 38/255, blue: 38/255)
    static let offWhite = Color(red: 248/255, green: 250/255, blue: 252/255)
    static let slateBlack = Color(red: 15/255, green: 23/255, blue: 42/255)
}

struct ContentView: View {
    // MARK: - 2. State Properties
    
    // Theme State
    @State private var useNewTheme: Bool = false
    
    // Internal initializer for previewing themes
    init(useNewTheme: Bool = false) {
        _useNewTheme = State(initialValue: useNewTheme)
    }
    
    // Theme Helpers
    var themeBackground: Color { useNewTheme ? .matteSlate : .black }
    var themeAccent: Color { useNewTheme ? .crimson : .chartreuse }
    var themeCard: Color { useNewTheme ? .offWhite : .darkCard }
    var themeCardText: Color { useNewTheme ? .slateBlack : .white }
    var themePrimaryText: Color { .white } // Text on background remains white for both dark backgrounds
    
    // API & Status
    @State private var serverStatus: Bool = false
    @State private var selectedItem: PhotosPickerItem?
    
    // Analysis State
    @State private var isAnalyzing: Bool = false
    @State private var uploadProgress: Double = 0.0
    @State private var analysisResult: AnalysisResponse?
    @State private var analyzedVideoURL: URL?
    @State private var showFullScreen: Bool = false
    
    // Timers
    @State private var healthCheckTimer: Timer?
    
    // Error Handling
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    
    // Save Video State
    @State private var saveMessage: String?
    @State private var showSaveAlert: Bool = false

    // MARK: - 3. Body
    var body: some View {
        NavigationView {
            ZStack {
                themeBackground.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // 1. Server Health
                        Button(action: checkServerHealth) {
                            HStack {
                                Circle()
                                    .fill(serverStatus ? themeAccent : Color.red)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: serverStatus ? themeAccent : .red, radius: 4)
                                
                                Text(serverStatus ? "SYSTEM ONLINE" : "OFFLINE - TAP TO RETRY")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .tracking(1)
                                    .foregroundColor(serverStatus ? themeAccent : .gray)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                        .onAppear { startHealthCheckTimer() }
                        .onDisappear { stopHealthCheckTimer() }

                        // 2. Main Content Switcher
                        if isAnalyzing {
                            processingView
                        } else if let result = analysisResult, let videoURL = analyzedVideoURL {
                            resultsView(result: result, videoURL: videoURL)
                        } else {
                            uploadView
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("TRIPLE JUMP AI")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(themeAccent)
                        .tracking(2)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            useNewTheme.toggle()
                        }
                    }) {
                        Image(systemName: useNewTheme ? "paintpalette.fill" : "paintpalette")
                            .foregroundColor(themeAccent)
                    }
                }
            }
            // NEW: Fullscreen Video Cover
            .fullScreenCover(isPresented: $showFullScreen) {
                if let url = analyzedVideoURL {
                    FullScreenVideoPlayer(videoURL: url, mistakeTimestamp: analysisResult?.worstMistakeTimestamp, isPresented: $showFullScreen, accentColor: themeAccent)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
            .alert("Save Video", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveMessage ?? "")
            }
        }
        .preferredColorScheme(.dark) // Keep base dark scheme for status bar etc, as both backgrounds are dark-ish
    }

    // MARK: - Subviews
    
    // View 1: Upload
    var uploadView: some View {
        VStack(spacing: 35) {
            Spacer().frame(height: 20)
            
            PulsingLogoView(isConnected: serverStatus, activeColor: themeAccent)
            
            VStack(spacing: 10) {
                Text("ANALYZE TECHNIQUE")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themePrimaryText)
                    .tracking(1)
                
                Text("Upload high-framerate video for biomechanical extraction.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
            }
            
            PhotosPicker(selection: $selectedItem, matching: .videos) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("UPLOAD VIDEO")
                        .fontWeight(.bold)
                        .tracking(1)
                }
                .foregroundColor(useNewTheme ? .white : .black) // Contrast for button text
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(serverStatus ? themeAccent : Color.gray)
                .cornerRadius(12)
                .shadow(color: serverStatus ? themeAccent.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 30)
            .disabled(!serverStatus)
            .onChange(of: selectedItem) { newItem in
                if let item = newItem { processSelection(item: item) }
            }
        }
    }
    
    // View 2: Processing
    var processingView: some View {
        VStack(spacing: 30) {
            Spacer().frame(height: 50)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: themeAccent))
                .scaleEffect(2.0)
            
            Text("PROCESSING BIOMECHANICS...")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(themeAccent)
                .tracking(1)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("UPLOADING")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(Int(uploadProgress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(themeAccent)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 6)
                            .foregroundColor(themeCard)
                        
                        Rectangle()
                            .frame(width: min(CGFloat(self.uploadProgress) * geometry.size.width, geometry.size.width), height: 6)
                            .foregroundColor(themeAccent)
                            .animation(.linear(duration: 0.2), value: uploadProgress)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // View 3: Results (Updated with Fullscreen Trigger)
    func resultsView(result: AnalysisResponse, videoURL: URL) -> some View {
        VStack(spacing: 24) {
            
            // A. Video Player Preview
            ZStack(alignment: .bottomTrailing) {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 250)
                    .cornerRadius(0)
                    .overlay(Rectangle().stroke(themeAccent, lineWidth: 1))
                
                // Fullscreen Trigger Button
                Button(action: {
                    showFullScreen = true
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(useNewTheme ? .white : .black)
                        .padding(8)
                        .background(themeAccent)
                        .clipShape(Rectangle()) // Technical look
                        .cornerRadius(4)
                }
                .padding(10)
            }
            .padding(.horizontal)
            
            // B. AI Coach Feedback
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(themeAccent)
                    Text("COACH ANALYSIS")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundColor(themeAccent)
                        .tracking(1)
                    Spacer()
                }
                .padding(.bottom, 10)
                
                Text(result.coachFeedback)
                    .font(.body)
                    .foregroundColor(themeCardText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(themeCard)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            .padding(.horizontal)
            
            // C. Phase Metrics
            VStack(alignment: .leading, spacing: 10) {
                Text("PHASE METRICS")
                    .font(.caption)
                    .fontWeight(.heavy)
                    .foregroundColor(.gray)
                    .tracking(1)
                    .padding(.horizontal)
                
                let sortedPhases = ["HOP", "SKIP", "JUMP"].compactMap { name in
                    result.phases[name].map { (name, $0) }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(sortedPhases, id: \.0) { name, data in
                            PhaseCard(phaseName: name, data: data, cardColor: themeCard, textColor: themeCardText, accentColor: themeAccent)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // D. Save to Camera Roll
            Button(action: {
                saveToCameraRoll(url: videoURL)
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("SAVE TO CAMERA ROLL")
                }
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(useNewTheme ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeAccent)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 10)

            // E. Reset
            Button(action: resetAnalysis) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("NEW ANALYSIS")
                }
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(useNewTheme ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeAccent)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 20) // Added padding at bottom
        }
    }
    
    // MARK: - 5. Logic & Actions
    
    // Server Health Logic
    func startHealthCheckTimer() {
        checkServerHealth() // Initial check
        if healthCheckTimer == nil {
            healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                checkServerHealth()
            }
        }
    }
    
    func stopHealthCheckTimer() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }

    func checkServerHealth() {
        JumpMasterAPI.shared.healthCheck { result in
            DispatchQueue.main.async {
                switch result {
                case .success: self.serverStatus = true
                case .failure: self.serverStatus = false
                }
            }
        }
    }
    
    func processSelection(item: PhotosPickerItem) {
        self.isAnalyzing = true
        self.uploadProgress = 0.1
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let data = data else { self.triggerError("Load failed"); return }
                    self.saveAndUpload(data: data)
                case .failure(let error): self.triggerError(error.localizedDescription)
                }
            }
        }
    }
    
    func saveAndUpload(data: Data) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("upload_jump.mp4")
        do {
            if FileManager.default.fileExists(atPath: tempURL.path) { try FileManager.default.removeItem(at: tempURL) }
            try data.write(to: tempURL)
            JumpMasterAPI.shared.analyzeJump(videoURL: tempURL) { progress in
                DispatchQueue.main.async { self.uploadProgress = progress }
            } completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self.analysisResult = response
                        self.downloadResultVideo(id: response.analysisId)
                    case .failure(let error): self.triggerError(error.localizedDescription)
                    }
                }
            }
        } catch { triggerError("File error") }
    }
    
    func downloadResultVideo(id: String) {
        JumpMasterAPI.shared.downloadVideo(analysisId: id) { result in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                switch result {
                case .success(let url):
                    self.analyzedVideoURL = url
                    // Cleanup server copy after successful download
                    JumpMasterAPI.shared.cleanup(analysisId: id) { cleanupResult in
                        switch cleanupResult {
                        case .success:
                            print("Server cleanup successful for ID: \(id)")
                        case .failure(let error):
                            print("Server cleanup failed: \(error.localizedDescription)")
                        }
                    }
                case .failure(let error): self.triggerError(error.localizedDescription)
                }
            }
        }
    }
    
    func resetAnalysis() {
        selectedItem = nil
        analysisResult = nil
        analyzedVideoURL = nil
        isAnalyzing = false
        uploadProgress = 0
    }
    
    func saveToCameraRoll(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.triggerError("Permission to access photo library is denied.")
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { saved, error in
                DispatchQueue.main.async {
                    if saved {
                        self.saveMessage = "Video saved to your Photos album!"
                        self.showSaveAlert = true
                    } else {
                        self.triggerError(error?.localizedDescription ?? "Failed to save video.")
                    }
                }
            }
        }
    }
    
    func triggerError(_ msg: String) {
        self.errorMessage = msg
        self.showError = true
        self.isAnalyzing = false
        self.selectedItem = nil
    }
}

// MARK: - Dedicated Fullscreen Player View
struct FullScreenVideoPlayer: View {
    let videoURL: URL
    let mistakeTimestamp: Double?
    @Binding var isPresented: Bool
    var accentColor: Color = .chartreuse // Default to original
    
    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = true
    @State private var currentTime: Double = 0.0
    @State private var duration: Double = 1.0
    @State private var showControls: Bool = true
    @State private var isScrubbing: Bool = false
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var isLandscape: Bool { verticalSizeClass == .compact }
    var hideUI: Bool { isLandscape && isScrubbing }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // UIKit Player Wrapper
            if let player = player {
                ZoomableUIKitPlayer(player: player)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation { showControls.toggle() }
                    }
            }
            
            // Overlay Controls
            if showControls {
                VStack {
                    // Top Bar (Close)
                    if !hideUI {
                        HStack {
                            Button(action: { isPresented = false }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(accentColor)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.leading)
                        .padding(.top, 40)
                    }
                    
                    Spacer()
                    
                    // Bottom Bar (Playback Controls)
                    if #available(iOS 16.0, *) {
                        if hideUI {
                            VStack(spacing: 15) {
                                scrubberView
                            }
                            .padding(20)
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        } else {
                            VStack(spacing: 15) {
                                scrubberView
                                
                                HStack(spacing: 40) {
                                    // Backward 5s
                                    Button(action: { seek(by: -5) }) {
                                        Image(systemName: "gobackward.5")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }
                                    
                                    // Play/Pause
                                    Button(action: togglePlayPause) {
                                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(15)
                                            .background(accentColor)
                                            .clipShape(Circle())
                                    }
                                    
                                    // Forward 5s
                                    Button(action: { seek(by: 5) }) {
                                        Image(systemName: "goforward.5")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .padding(20)
                            .glassEffect(in: RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            setupPlayer()
        }
    }
    
    var scrubberView: some View {
        // Slider with Mistake Marker
        ZStack(alignment: .leading) {
            Slider(value: Binding(get: { currentTime }, set: { newVal in
                currentTime = newVal
                player?.seek(to: CMTime(seconds: newVal, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
            }), in: 0...duration, onEditingChanged: { editing in
                isScrubbing = editing
            })
            .accentColor(accentColor)
            
            // Mistake Marker Overlay
            if let mistakeTime = mistakeTimestamp, duration > 0 {
                GeometryReader { geometry in
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        .position(x: (CGFloat(mistakeTime) / CGFloat(duration)) * geometry.size.width, y: geometry.size.height / 2)
                }
                .allowsHitTesting(false) // Pass touches through to Slider
            }
        }
        .frame(height: 20) // Constrain height for GeometryReader
    }
    
    func setupPlayer() {
        let newPlayer = AVPlayer(url: videoURL)
        self.player = newPlayer
        newPlayer.play()
        
        // Observe Duration
        let asset = AVAsset(url: videoURL)
        Task {
            if let dur = try? await asset.load(.duration) {
                await MainActor.run { self.duration = dur.seconds }
            }
        }
        
        // Observe Time
        newPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            self.currentTime = time.seconds
            // Loop video
            if time.seconds >= self.duration - 0.1 {
                self.player?.seek(to: .zero)
                self.player?.play()
            }
        }
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    func seek(by seconds: Double) {
        guard let player = player else { return }
        let newTime = player.currentTime().seconds + seconds
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }
}

// MARK: - UIKit Bridge
struct ZoomableUIKitPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> ZoomableVideoViewController {
        return ZoomableVideoViewController(player: player)
    }
    
    func updateUIViewController(_ uiViewController: ZoomableVideoViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - UIKit View Controller
class ZoomableVideoViewController: UIViewController, UIScrollViewDelegate {
    let player: AVPlayer
    var playerLayer: AVPlayerLayer?
    var scrollView: UIScrollView!
    var contentContainer: UIView!
    
    init(player: AVPlayer) {
        self.player = player
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // 1. Setup ScrollView
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scrollView)
        
        // 2. Setup Container
        contentContainer = UIView(frame: scrollView.bounds)
        contentContainer.backgroundColor = .black
        scrollView.addSubview(contentContainer)
        
        // 3. Setup Player Layer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = contentContainer.bounds
        contentContainer.layer.addSublayer(playerLayer!)
        
        // 4. Double Tap Gesture
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if scrollView.zoomScale == 1.0 {
            scrollView.contentSize = view.bounds.size
            contentContainer.frame = view.bounds
            playerLayer?.frame = view.bounds
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentContainer
    }
    
    @objc func handleDoubleTap() {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            scrollView.setZoomScale(2.5, animated: true)
        }
    }
}

// MARK: - 6. Biomechanical Components

struct PhaseCard: View {
    let phaseName: String
    let data: PhaseData
    var cardColor: Color = .darkCard
    var textColor: Color = .white
    var accentColor: Color = .chartreuse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(phaseName)
                    .font(.title3)
                    .fontWeight(.black)
                    .italic()
                    .foregroundColor(textColor)
                Spacer()
                Text(data.leg)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(cardColor == .offWhite ? .white : .black) // Adjust badge text based on theme
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor)
                    .cornerRadius(4)
            }
            Rectangle().frame(height: 1).foregroundColor(textColor.opacity(0.1))
            VStack(spacing: 8) {
                StatRow(label: "FORCE", value: String(format: "%.1f G", data.peakForce), isBad: data.peakForce < 3.5, labelColor: .gray, valueColor: accentColor)
                StatRow(label: "ANGLE", value: "\(data.angle)°", isBad: data.angle < 135, labelColor: .gray, valueColor: accentColor)
                StatRow(label: "BRAKE", value: String(format: "%.2f m", data.braking), isBad: data.braking > 0.30, labelColor: .gray, valueColor: accentColor)
                StatRow(label: "LEAN", value: "\(data.torso)°", isBad: data.torso > 25, labelColor: .gray, valueColor: accentColor)
            }
        }
        .padding()
        .frame(width: 180)
        .background(cardColor)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(textColor.opacity(0.1), lineWidth: 1))
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let isBad: Bool
    var labelColor: Color = .gray
    var valueColor: Color = .chartreuse
    
    var body: some View {
        HStack {
            Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(labelColor)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(isBad ? .red : valueColor)
        }
    }
}

// MARK: - Pulsing Logo Component
struct PulsingLogoView: View {
    var isConnected: Bool
    var activeColor: Color = .chartreuse
    @State private var animateWaves = false
    
    var color: Color {
        isConnected ? activeColor : .gray
    }
    
    var body: some View {
        ZStack {
            // Wave 1
            Circle()
                .stroke(color.opacity(0.5), lineWidth: 1)
                .frame(width: 140, height: 140)
                .scaleEffect(animateWaves ? 1.5 : 1)
                .opacity(animateWaves ? 0 : 1)
                .animation(animateWaves ? Animation.easeOut(duration: 2).repeatForever(autoreverses: false) : .default, value: animateWaves)
            
            // Wave 2
            Circle()
                .stroke(color.opacity(0.5), lineWidth: 1)
                .frame(width: 140, height: 140)
                .scaleEffect(animateWaves ? 1.5 : 1)
                .opacity(animateWaves ? 0 : 1)
                .animation(animateWaves ? Animation.easeOut(duration: 2).repeatForever(autoreverses: false).delay(1) : .default, value: animateWaves)
            
            // Main Circle
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 2)
                .frame(width: 140, height: 140)
            
            // Icon
            Image(systemName: "figure.run.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .foregroundColor(color)
                .shadow(color: isConnected ? color.opacity(0.6) : .clear, radius: 10)
        }
        .onAppear {
            if isConnected { animateWaves = true }
        }
        .onChange(of: isConnected) { connected in
            animateWaves = connected
        }
    }
}

// MARK: - Preview

#Preview("Full Screen Player (Chartreuse)") {
    @Previewable @State var presented: Bool = true
    FullScreenVideoPlayer(videoURL: URL(fileURLWithPath: ""), mistakeTimestamp: 2.5, isPresented: $presented, accentColor: .chartreuse)
}

#Preview("Full Screen Player (Crimson)") {
    @Previewable @State var presented: Bool = true
    FullScreenVideoPlayer(videoURL: URL(fileURLWithPath: ""), mistakeTimestamp: 2.5, isPresented: $presented, accentColor: .crimson)
}

#Preview("Results Screen (Chartreuse)") {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        ScrollView {
            ContentView(useNewTheme: false).resultsView(
                result: AnalysisResponse(
                    analysisId: "preview_id",
                    timestamp: "2024-01-06T12:00:00Z",
                    coachFeedback: "Your hop phase shows good explosive power, but your transition into the skip is causing significant braking force. Focus on maintaining a more upright torso (currently 28°) to preserve horizontal velocity.",
                    phases: [
                        "HOP": PhaseData(leg: "Right", angle: 142, braking: 0.12, torso: 18, peakForce: 4.5),
                        "SKIP": PhaseData(leg: "Left", angle: 128, braking: 0.38, torso: 28, peakForce: 3.2),
                        "JUMP": PhaseData(leg: "Both", angle: 148, braking: 0.08, torso: 12, peakForce: 5.1)
                    ],
                    videoUrl: "",
                    worstMistakeTimestamp: 2.1
                ),
                videoURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Results Screen (Crimson)") {
    ZStack {
        Color.matteSlate.edgesIgnoringSafeArea(.all)
        ScrollView {
            ContentView(useNewTheme: true).resultsView(
                result: AnalysisResponse(
                    analysisId: "preview_id",
                    timestamp: "2024-01-06T12:00:00Z",
                    coachFeedback: "Your hop phase shows good explosive power, but your transition into the skip is causing significant braking force. Focus on maintaining a more upright torso (currently 28°) to preserve horizontal velocity.",
                    phases: [
                        "HOP": PhaseData(leg: "Right", angle: 142, braking: 0.12, torso: 18, peakForce: 4.5),
                        "SKIP": PhaseData(leg: "Left", angle: 128, braking: 0.38, torso: 28, peakForce: 1),
                        "JUMP": PhaseData(leg: "Both", angle: 148, braking: 0.08, torso: 12, peakForce: 5.1)
                    ],
                    videoUrl: "",
                    worstMistakeTimestamp: 2.1
                ),
                videoURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!
            )
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Main Content (Chartreuse)") {
    ContentView(useNewTheme: false)
}

#Preview("Main Content (Crimson)") {
    ContentView(useNewTheme: true)
}
