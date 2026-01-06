import Foundation
import UIKit

// MARK: - Models
struct AnalysisResponse: Codable {
    let analysisId: String
    let timestamp: String
    let coachFeedback: String
    let phases: [String: PhaseData]
    let videoUrl: String
    let worstMistakeTimestamp: Double?
    
    enum CodingKeys: String, CodingKey {
        case analysisId = "analysis_id"
        case timestamp
        case coachFeedback = "coach_feedback"
        case phases
        case videoUrl = "video_url"
        case worstMistakeTimestamp = "worst_mistake_timestamp"
    }
}

struct PhaseData: Codable {
    let leg: String
    let angle: Int
    let braking: Double
    let torso: Int
    let peakForce: Double
    
    enum CodingKeys: String, CodingKey {
        case leg = "Leg"
        case angle = "Angle"
        case braking = "Braking"
        case torso = "Torso"
        case peakForce = "Peak_Force"
    }
}

struct ErrorResponse: Codable {
    let error: String
}

// MARK: - API Client
class JumpMasterAPI {
    static let shared = JumpMasterAPI()
    
    // Update this with your server IP/domain
    //private let baseURL = "http://192.168.1.83:5000" //at home
    //private let baseURL = "http://172.20.10.3:5000" //usb
    //private let baseURL = "http://100.76.191.100:5000" //tailscale
    private let baseURL = "https://henrys-macbook-air.tail21aa88.ts.net/" //tailscale funnel
    
    private init() {}
    
    // MARK: - Health Check
    func healthCheck(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/health") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(.success(true))
            } else {
                completion(.failure(NSError(domain: "Server unhealthy", code: -1)))
            }
        }.resume()
    }
    
    // MARK: - Analyze Jump
    func analyzeJump(videoURL: URL, progress: @escaping (Double) -> Void, completion: @escaping (Result<AnalysisResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/analyze") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create multipart form data
        var body = Data()
        
        // Add video file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video\"; filename=\"jump.mp4\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/mp4\r\n\r\n".data(using: .utf8)!)
        
        do {
            let videoData = try Data(contentsOf: videoURL)
            body.append(videoData)
        } catch {
            completion(.failure(error))
            return
        }
        
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Upload with progress tracking
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        
        let task = session.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "Invalid response", code: -1)))
                return
            }
            
            if httpResponse.statusCode == 200 {
                do {
                    let decoder = JSONDecoder()
                    let analysisResponse = try decoder.decode(AnalysisResponse.self, from: data)
                    completion(.success(analysisResponse))
                } catch {
                    completion(.failure(error))
                }
            } else {
                // Try to parse error
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    completion(.failure(NSError(domain: errorResponse.error, code: httpResponse.statusCode)))
                } else {
                    completion(.failure(NSError(domain: "Unknown error", code: httpResponse.statusCode)))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Download Video
    func downloadVideo(analysisId: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/download/\(analysisId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let localURL = localURL else {
                completion(.failure(NSError(domain: "No file downloaded", code: -1)))
                return
            }
            
            // Move to permanent location
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent("analyzed_\(analysisId).mp4")
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: localURL, to: destinationURL)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Cleanup
    func cleanup(analysisId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/cleanup/\(analysisId)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "Cleanup failed", code: -1)))
            }
        }.resume()
    }
}

// MARK: - Usage Example in a ViewController
class JumpAnalysisViewController: UIViewController {
    
    func analyzeVideo(from videoURL: URL) {
        // Show loading indicator
        showLoadingIndicator()
        
        JumpMasterAPI.shared.analyzeJump(videoURL: videoURL, progress: { progress in
            DispatchQueue.main.async {
                // Update progress UI
                print("Upload progress: \(progress * 100)%")
            }
        }) { result in
            DispatchQueue.main.async {
                self.hideLoadingIndicator()
                
                switch result {
                case .success(let response):
                    print("Analysis ID: \(response.analysisId)")
                    print("Coach Feedback: \(response.coachFeedback)")
                    
                    // Display results
                    self.displayResults(response)
                    
                    // Download analyzed video
                    self.downloadAnalyzedVideo(analysisId: response.analysisId)
                    
                case .failure(let error):
                    self.showError(error.localizedDescription)
                }
            }
        }
    }
    
    func downloadAnalyzedVideo(analysisId: String) {
        JumpMasterAPI.shared.downloadVideo(analysisId: analysisId) { result in
            switch result {
            case .success(let videoURL):
                DispatchQueue.main.async {
                    print("Video saved to: \(videoURL)")
                    // Play or share the video
                    self.playVideo(at: videoURL)
                    
                    // Cleanup server copy
                    JumpMasterAPI.shared.cleanup(analysisId: analysisId) { _ in }
                }
            case .failure(let error):
                print("Download failed: \(error)")
            }
        }
    }
    
    // MARK: - UI Helper Methods
    func showLoadingIndicator() {
        // Implement your loading UI
    }
    
    func hideLoadingIndicator() {
        // Hide loading UI
    }
    
    func displayResults(_ response: AnalysisResponse) {
        // Display analysis results in your UI
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func playVideo(at url: URL) {
        // Implement video playback
    }
}
