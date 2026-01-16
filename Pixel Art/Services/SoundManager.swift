import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    var musicPlayer: AVAudioPlayer?
    var sfxPlayer: AVAudioPlayer?
    
    var isMusicOn: Bool = true
    
    var isMuted: Bool = false {
        didSet {
            if isMuted {
                musicPlayer?.pause()
            } else {
                if isMusicOn { musicPlayer?.play() }
            }
        }
    }
    
    init() {
        setupAudioSession()
    }

    func setupAudioSession() {
        do {
            // Cho phép phát nhạc ngay cả khi bật chế độ Rung/Silent
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Lỗi AudioSession: \(error)")
        }
    }
    
    // 1. Phát nhạc nền
    func playBackgroundMusic(filename: String = "bgm", extensionName: String = "mp3") {
        if let player = musicPlayer, player.isPlaying { return }
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: extensionName) else {
            print("Không tìm thấy file nhạc nền")
            return
        }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1 // Lặp vô hạn
            musicPlayer?.volume = 0.5
            
            if !isMuted && isMusicOn {
                musicPlayer?.play()
            }
        } catch {
            print("Lỗi phát nhạc: \(error.localizedDescription)")
        }
    }
    
    // 2. Hàm dừng nhạc nền 
    func stopBackgroundMusic() {
        musicPlayer?.stop()
        musicPlayer?.currentTime = 0 // Reset về đầu bài
    }
    
    // 3. Phát hiệu ứng âm thanh
    func playSoundEffect(filename: String = "paint", extensionName: String = "wav") {
        guard !isMuted else { return }
        guard let url = Bundle.main.url(forResource: filename, withExtension: extensionName) else { return }
        
        do {
            sfxPlayer = try AVAudioPlayer(contentsOf: url)
            sfxPlayer?.volume = 1.0
            sfxPlayer?.play()
        } catch {
            print("Lỗi SFX: \(error.localizedDescription)")
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
        isMusicOn = !isMuted
    }
}
