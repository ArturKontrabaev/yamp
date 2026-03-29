import Foundation

typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
typealias MRNowPlayingClientGetBundleIdentifierFunction = @convention(c) (AnyObject?) -> String?

class NowPlayingTrackProvider {
    private let getInfo: MRMediaRemoteGetNowPlayingInfoFunction?
    private let getBundleId: MRNowPlayingClientGetBundleIdentifierFunction?
    private let bundle: CFBundle?

    init() {
        let path = "/System/Library/PrivateFrameworks/MediaRemote.framework"
        bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: path))

        if let bundle = bundle {
            let infoPtr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString)
            getInfo = unsafeBitCast(infoPtr, to: MRMediaRemoteGetNowPlayingInfoFunction?.self)

            let clientPtr = CFBundleGetFunctionPointerForName(bundle, "MRNowPlayingClientGetBundleIdentifier" as CFString)
            getBundleId = unsafeBitCast(clientPtr, to: MRNowPlayingClientGetBundleIdentifierFunction?.self)
        } else {
            getInfo = nil
            getBundleId = nil
        }
    }

    func getCurrentTrack(completion: @escaping (Track) -> Void) {
        guard let getInfo = getInfo else {
            completion(.empty)
            return
        }

        getInfo(DispatchQueue.main) { info in
            guard !info.isEmpty else {
                completion(.empty)
                return
            }

            let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String ?? ""
            let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
            let playbackRate = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0
            let isPlaying = playbackRate > 0

            let track = Track(title: title, artist: artist, isPlaying: isPlaying)
            completion(track)
        }
    }
}
