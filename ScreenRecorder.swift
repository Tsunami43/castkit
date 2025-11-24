import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreGraphics

@MainActor
class ScreenRecorder: NSObject {
    private var stream: SCStream?
    private var videoWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var startTime: CMTime?
    private var fileURL: URL?
    var cropRect: CGRect?

    func startRecording(with filter: SCContentFilter) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "ScreenRecording_\(dateString).mp4"

        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        fileURL = downloadsURL.appendingPathComponent(fileName)

        guard let fileURL = fileURL else {
            throw RecordingError.invalidURL
        }

        // Configuration
        let config = SCStreamConfiguration()
        config.width = 1920
        config.height = 1080
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30) // 30 FPS
        config.queueDepth = 5

        // Setup video writer
        videoWriter = try AVAssetWriter(outputURL: fileURL, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]

        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true

        guard let videoWriter = videoWriter, let videoInput = videoInput else {
            throw RecordingError.writerSetupFailed
        }

        if videoWriter.canAdd(videoInput) {
            videoWriter.add(videoInput)
        } else {
            throw RecordingError.cannotAddInput
        }

        // Create and start stream
        stream = SCStream(filter: filter, configuration: config, delegate: self)
        guard let stream = stream else {
            throw RecordingError.streamCreationFailed
        }

        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
        try await stream.startCapture()

        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        startTime = .zero
    }

    func stopRecording() async throws -> URL {
        guard let stream = stream else {
            throw RecordingError.noActiveRecording
        }

        try await stream.stopCapture()

        guard let videoInput = videoInput, let videoWriter = videoWriter else {
            throw RecordingError.writerNotInitialized
        }

        videoInput.markAsFinished()

        await videoWriter.finishWriting()

        self.stream = nil
        self.videoWriter = nil
        self.videoInput = nil
        self.startTime = nil

        guard let fileURL = fileURL else {
            throw RecordingError.invalidURL
        }

        return fileURL
    }

    enum RecordingError: Error {
        case invalidURL
        case writerSetupFailed
        case cannotAddInput
        case streamCreationFailed
        case noActiveRecording
        case writerNotInitialized
    }
}

extension ScreenRecorder: SCStreamDelegate {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Stream stopped with error: \(error.localizedDescription)")
    }
}

extension ScreenRecorder: SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }

        Task { @MainActor in
            guard let videoInput = self.videoInput,
                  videoInput.isReadyForMoreMediaData,
                  let videoWriter = self.videoWriter,
                  videoWriter.status == .writing else {
                return
            }

            if let cropRect = self.cropRect {
                // Crop the sample buffer
                if let croppedBuffer = cropSampleBuffer(sampleBuffer, to: cropRect) {
                    videoInput.append(croppedBuffer)
                }
            } else {
                videoInput.append(sampleBuffer)
            }
        }
    }

    private func cropSampleBuffer(_ sampleBuffer: CMSampleBuffer, to rect: CGRect) -> CMSampleBuffer? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let croppedImage = ciImage.cropped(to: rect)

        let context = CIContext()
        guard let outputBuffer = createPixelBuffer(width: Int(rect.width), height: Int(rect.height)) else {
            return nil
        }

        context.render(croppedImage, to: outputBuffer)

        var newSampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo()
        timingInfo.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        timingInfo.duration = CMSampleBufferGetDuration(sampleBuffer)
        timingInfo.decodeTimeStamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)

        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: outputBuffer,
            formatDescriptionOut: &formatDescription
        )

        guard let formatDesc = formatDescription else {
            return nil
        }

        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: outputBuffer,
            formatDescription: formatDesc,
            sampleTiming: &timingInfo,
            sampleBufferOut: &newSampleBuffer
        )

        return newSampleBuffer
    }

    private func createPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]

        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        return pixelBuffer
    }
}
