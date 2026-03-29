import Foundation

class NowPlayingTrackProvider {

    func getCurrentTrack(completion: @escaping (Track) -> Void) {
        let js = """
        (function() {
            var title = '';
            var artist = '';
            var titleEl = document.querySelector('[class*="Meta_titleContainer"] a')
                || document.querySelector('[class*="PlayerBarDesktop"] [class*="Meta_albumLink"]');
            if (titleEl) {
                var ariaT = titleEl.getAttribute('aria-label') || '';
                if (ariaT.startsWith('Track ')) title = ariaT.substring(6);
                else title = titleEl.textContent.trim();
            }
            var artistEls = document.querySelectorAll('[class*="PlayerBarDesktop"] [class*="Meta_text"] [class*="Meta_link"]');
            if (artistEls.length > 0) {
                var ariaA = artistEls[0].getAttribute('aria-label') || '';
                if (ariaA.startsWith('Artist ')) artist = ariaA.substring(7);
                else artist = artistEls[0].textContent.trim();
            }
            var pauseBtn = document.querySelector('[aria-label="Pause"]');
            var playBtn = document.querySelector('[aria-label="Playback"]');
            var isPlaying = pauseBtn !== null && playBtn === null;
            var artworkURL = '';
            var imgEl = document.querySelector('[class*="PlayerBarDesktop"] img');
            if (imgEl) artworkURL = imgEl.src || '';
            return JSON.stringify({title: title, artist: artist, playing: isPlaying, artwork: artworkURL});
        })()
        """

        CDPConnection.shared.evaluate(js: js) { result in
            guard !result.isEmpty,
                  let data = result.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.empty)
                return
            }

            let title = obj["title"] as? String ?? ""
            let artist = obj["artist"] as? String ?? ""
            let isPlaying = obj["playing"] as? Bool ?? false
            let artwork = obj["artwork"] as? String
            completion(Track(title: title, artist: artist, isPlaying: isPlaying, artworkURL: artwork))
        }
    }
}
