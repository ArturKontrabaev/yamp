import Foundation

let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))!

typealias MRFn = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void

let ptr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString)!
let getInfo = unsafeBitCast(ptr, to: MRFn.self)

getInfo(DispatchQueue.main) { info in
    if info.isEmpty {
        print("EMPTY — no now playing info")
    } else {
        for (key, value) in info.sorted(by: { $0.key < $1.key }) {
            print("\(key) = \(value)")
        }
    }
    exit(0)
}

RunLoop.main.run()
