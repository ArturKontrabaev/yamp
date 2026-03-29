import Foundation

class NowPlayingTrackProvider {

    func getCurrentTrack(completion: @escaping (Track) -> Void) {
        DispatchQueue.global().async {
            let scriptPath = Bundle.main.bundlePath
                .components(separatedBy: "/YAMP.app")[0] + "/get_track.py"

            // Try multiple paths for get_track.py
            let paths = [
                scriptPath,
                NSHomeDirectory() + "/yamp/get_track.py",
                "/Users/" + NSUserName() + "/yamp/get_track.py",
            ]

            var pyPath: String?
            for p in paths {
                if FileManager.default.fileExists(atPath: p) {
                    pyPath = p
                    break
                }
            }

            guard let scriptFile = pyPath else {
                DispatchQueue.main.async { completion(.empty) }
                return
            }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["python3", scriptFile]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                DispatchQueue.main.async { completion(.empty) }
                return
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8),
                  let jsonData = output.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                DispatchQueue.main.async { completion(.empty) }
                return
            }

            let title = obj["title"] as? String ?? ""
            let artist = obj["artist"] as? String ?? ""

            DispatchQueue.main.async {
                completion(Track(title: title, artist: artist, isPlaying: !title.isEmpty, artworkURL: nil))
            }
        }
    }
}
