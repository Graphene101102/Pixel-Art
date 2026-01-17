import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    var isMuted: Bool = false
    
    private init() {
        // Cấu hình để nhạc không bị ngắt bởi chế độ im lặng (Silent mode) của iPhone
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Lỗi AudioSession: \(error)")
        }
    }
    
    func playBackgroundMusic() {
        // Nếu đang mute thì không phát
        if isMuted { return }
        
        // 1. Nếu đang phát rồi -> Bỏ qua (Không phát lại từ đầu)
        if let player = audioPlayer, player.isPlaying {
            return
        }
        
        // 2. Nếu đã có player (đang Pause) -> Resume (Phát tiếp)
        if let player = audioPlayer {
            player.play()
            return
        }
        
        // 3. Nếu chưa có (Lần đầu) -> Khởi tạo và phát
        guard let url = Bundle.main.url(forResource: "bgm", withExtension: "mp3") else {
            print("⚠️ Không tìm thấy file nhạc!")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Lặp vô tận
            audioPlayer?.volume = 0.5       // Âm lượng vừa phải
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Lỗi khởi tạo nhạc: \(error.localizedDescription)")
        }
    }
    
    // Tạm dừng (giữ vị trí phát)
    func pauseBackgroundMusic() {
        if let player = audioPlayer, player.isPlaying {
            player.pause()
        }
    }
    
    // Hàm này tắt hẳn (reset về 0)
    func stopBackgroundMusic() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
    }
    
    func toggleMute() {
        isMuted.toggle()
    }
}
