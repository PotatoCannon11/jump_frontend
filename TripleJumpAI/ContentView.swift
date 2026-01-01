import SwiftUI
import PhotosUI
import AVKit

// MARK: - 1. Theme Extensions
extension Color {
    static let chartreuse = Color(red: 0.87, green: 1.0, blue: 0.0)
    static let darkCard = Color(white: 0.12)
}

struct ContentView: View {
    // MARK: - State Properties
    @State private var serverStatus: Bool = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var isAnalyzing: Bool = false
    @State private var uploadProgress: Double = 0.0
    @State private var analysisResult: AnalysisResponse?
    @State private var analyzedVideoURL: URL?
    @State private var showFullScreen: Bool = false // NEW: Fullscreen state
    
    // Error Handling
    @State private var errorMessage: String?
    @State private var showError: Bool = false

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // 1. Server Health
                        HStack {
                            Circle()
                                .fill(serverStatus ? Color.chartreuse : Color.red)
                                .frame(width: 8, height: 8)
                                .shadow(color: serverStatus ? .chartreuse : .red, radius: 4)
                            
                            Text(serverStatus ? "SYSTEM ONLINE" : "CONNECTING...")
                                .font(.caption)
                                .fontWeight(.bold)
                                .tracking(1)
                                .foregroundColor(serverStatus ? .chartreuse : .gray)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .onAppear { checkServerHealth() }

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
                        .foregroundColor(.white)
                        .tracking(2)
                }
            }
            // NEW: Fullscreen Video Cover
            .fullScreenCover(isPresented: $showFullScreen) {
                if let url = analyzedVideoURL {
                    FullScreenVideoPlayer(videoURL: url, isPresented: $showFullScreen)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews
    
    // View 1: Upload
    var uploadView: some View {
        VStack(spacing: 35) {
            Spacer().frame(height: 20)
            
            ZStack {
                Circle()
                    .stroke(Color.chartreuse.opacity(0.3), lineWidth: 2)
                    .frame(width: 140, height: 140)
                
                Image(systemName: "figure.run.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .foregroundColor(.chartreuse)
                    .shadow(color: .chartreuse.opacity(0.6), radius: 10)
            }
            
            VStack(spacing: 10) {
                Text("ANALYZE TECHNIQUE")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
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
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 55)
                .background(serverStatus ? Color.chartreuse : Color.gray)
                .cornerRadius(12)
                .shadow(color: serverStatus ? .chartreuse.opacity(0.4) : .clear, radius: 8, x: 0, y: 4)
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
                .progressViewStyle(CircularProgressViewStyle(tint: .chartreuse))
                .scaleEffect(2.0)
            
            Text("PROCESSING BIOMECHANICS...")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.chartreuse)
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
                        .foregroundColor(.chartreuse)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 6)
                            .foregroundColor(Color.darkCard)
                        
                        Rectangle()
                            .frame(width: min(CGFloat(self.uploadProgress) * geometry.size.width, geometry.size.width), height: 6)
                            .foregroundColor(.chartreuse)
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
                    .overlay(Rectangle().stroke(Color.chartreuse, lineWidth: 1))
                
                // Fullscreen Trigger Button
                Button(action: {
                    showFullScreen = true
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.chartreuse)
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
                        .foregroundColor(.chartreuse)
                    Text("COACH ANALYSIS")
                        .font(.caption)
                        .fontWeight(.heavy)
                        .foregroundColor(.chartreuse)
                        .tracking(1)
                    Spacer()
                }
                .padding(.bottom, 10)
                
                Text(result.coachFeedback)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.darkCard)
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
                            PhaseCard(phaseName: name, data: data)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // D. Reset
            Button(action: resetAnalysis) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("NEW ANALYSIS")
                }
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.chartreuse)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }
    
    // ... [Logic functions remain the same as previous: checkServerHealth, processSelection, etc.] ...
    
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
                case .success(let url): self.analyzedVideoURL = url
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
    
    func triggerError(_ msg: String) {
        self.errorMessage = msg
        self.showError = true
        self.isAnalyzing = false
        self.selectedItem = nil
    }
}

// MARK: - NEW: Dedicated Fullscreen Player View
struct FullScreenVideoPlayer: View {
    let videoURL: URL
    @Binding var isPresented: Bool
    
    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = true
    @State private var currentTime: Double = 0.0
    @State private var duration: Double = 1.0
    @State private var showControls: Bool = true
    
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
                    HStack {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .padding(10)
                                .background(Color.chartreuse)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.leading)
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Bottom Bar (Playback Controls)
                    if #available(iOS 26.0, *) {
                        VStack(spacing: 15) {
                            // Slider
                            Slider(value: Binding(get: { currentTime }, set: { newVal in
                                currentTime = newVal
                                player?.seek(to: CMTime(seconds: newVal, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
                            }), in: 0...duration)
                            .accentColor(.chartreuse)
                            .onAppear {
                                // Custom slider thumb appearance hack if needed, or stick to standard accent
                            }
                            
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
                                        .background(Color.chartreuse)
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

// MARK: - Styled Components (Same as before)
struct PhaseCard: View {
    let phaseName: String
    let data: PhaseData
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(phaseName).font(.title3).fontWeight(.black).italic().foregroundColor(.white)
                Spacer()
                Text(data.leg).font(.caption).fontWeight(.bold).foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 4).background(Color.chartreuse).cornerRadius(4)
            }
            Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.1))
            VStack(spacing: 8) {
                StatRow(label: "FORCE", value: String(format: "%.1f G", data.peakForce), isBad: data.peakForce < 3.5)
                StatRow(label: "ANGLE", value: "\(data.angle)°", isBad: data.angle < 135)
                StatRow(label: "BRAKE", value: String(format: "%.2f m", data.braking), isBad: data.braking > 0.30)
                StatRow(label: "LEAN", value: "\(data.torso)°", isBad: data.torso > 25)
            }
        }
        .padding().frame(width: 180).background(Color.darkCard).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct StatRow: View {
    let label: String; let value: String; let isBad: Bool
    var body: some View {
        HStack {
            Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
            Spacer()
            Text(value).font(.system(size: 14, weight: .medium, design: .monospaced)).foregroundColor(isBad ? .red : .chartreuse)
        }
    }
}

#Preview {
    @Previewable @State var presented: Bool = true
    FullScreenVideoPlayer(videoURL: URL(fileURLWithPath: ""), isPresented: $presented)
}
