import UIKit
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    // Keys lưu UserDefaults
    private let kMusicKey = "kMusicEnabled"
    private let kHapticKey = "kHapticEnabled"
    
    var isMusicEnabled: Bool {
        get { UserDefaults.standard.object(forKey: kMusicKey) as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: kMusicKey)
            if newValue { playBackgroundMusic() } else { stopBackgroundMusic() }
        }
    }
    
    var isHapticEnabled: Bool {
        get { UserDefaults.standard.object(forKey: kHapticKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: kHapticKey) }
    }
    
    private init() {
        setupAudio()
    }
    
    private func setupAudio() {
        guard let url = Bundle.main.url(forResource: "bgm", withExtension: "mp3") else {
            print("❌ Lỗi: Không tìm thấy file bg_music.mp3 trong Bundle.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Lặp vô hạn
            audioPlayer?.volume = 0.5
            audioPlayer?.prepareToPlay() // Load trước vào bộ nhớ đệm
        } catch {
            print("❌ Lỗi load trình phát nhạc: \(error)")
        }
    }
    
    func playBackgroundMusic() {
        if isMusicEnabled {
            if audioPlayer?.isPlaying == false {
                audioPlayer?.play()
            }
        }
    }
    
    func pauseBackgroundMusic() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.pause()
        }
    }
    
    func stopBackgroundMusic() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }
    
    func toggleMute() {
        isMusicEnabled = !isMusicEnabled
    }
    
    // [QUAN TRỌNG] Hàm rung tập trung
    // Tất cả ViewModel phải gọi hàm này thay vì tự tạo Generator
    func triggerHaptic(type: UINotificationFeedbackGenerator.FeedbackType) {
        if isHapticEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(type)
        }
    }
    
    func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        if isHapticEnabled {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }
    }
}
