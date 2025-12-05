import Foundation
import AVFoundation

class AudioRecorder: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var fileURL: URL?

    var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }

    func startRecording() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "AudioRecording_\(dateString).m4a"

        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        fileURL = downloadsURL.appendingPathComponent(fileName)

        guard let fileURL = fileURL else {
            throw AudioRecordingError.invalidURL
        }

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true)

        // Audio settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.prepareToRecord()

        guard let recorder = audioRecorder else {
            throw AudioRecordingError.recorderInitFailed
        }

        if !recorder.record() {
            throw AudioRecordingError.recordingStartFailed
        }
    }

    func stopRecording() throws -> URL {
        guard let recorder = audioRecorder else {
            throw AudioRecordingError.noActiveRecording
        }

        recorder.stop()

        // Deactivate audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setActive(false)

        guard let fileURL = fileURL else {
            throw AudioRecordingError.invalidURL
        }

        audioRecorder = nil
        self.fileURL = nil

        return fileURL
    }

    enum AudioRecordingError: Error {
        case invalidURL
        case recorderInitFailed
        case recordingStartFailed
        case noActiveRecording
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Audio recording finished unsuccessfully")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Audio recording error: \(error.localizedDescription)")
        }
    }
}
