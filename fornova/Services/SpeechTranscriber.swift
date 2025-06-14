import AVFoundation
import Speech

final class SpeechTranscriber: NSObject, SFSpeechRecognizerDelegate {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))!
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()

    
    func startTranscribing(resultHandler: @escaping (String) -> Void) throws {
        
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .notDetermined {
            let sem = DispatchSemaphore(value: 0)
            SFSpeechRecognizer.requestAuthorization { _ in sem.signal() }
            sem.wait()
        }
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw NSError(domain: "Speech", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Нет доступа к распознаванию речи"])
        }

        
        switch session.recordPermission {
        case .undetermined:
            let sem2 = DispatchSemaphore(value: 0)
            session.requestRecordPermission { _ in sem2.signal() }
            sem2.wait()
        case .denied:
            throw NSError(domain: "Speech", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Нет доступа к микрофону"])
        default:
            break
        }

        
        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        let node = audioEngine.inputNode
        let format = node.inputFormat(forBus: 0)
        node.removeTap(onBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer.recognitionTask(with: request!) { res, error in
            if let res = res {
                DispatchQueue.main.async {
                    resultHandler(res.bestTranscription.formattedString)
                }
            }
            if error != nil || (res?.isFinal ?? false) {
                self.audioEngine.stop()
                node.removeTap(onBus: 0)
                self.request = nil
                self.task = nil
            }
        }
    }

    func stop() {
        audioEngine.stop()
        request?.endAudio()
        task?.cancel()
    }
}
