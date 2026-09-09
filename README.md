# Commons Shorts — Roku channel

Free public-domain and Creative Commons short films, streamed straight from
Wikimedia Commons (`upload.wikimedia.org`) — no re-hosting, no transcoding.

Built from the same shell as **Free Classic Movies & TV** (see
`parker-pdl/free-classic-movies-tv`): remote JSON feed with a bundled
fallback, Roku Advertising Framework pre-roll via the `pdl-ads` worker
(`?ch=shorts`), deep-link support.

## Feed

`feed/feed.json` — 195 titles across 5 collections (Horror Shorts, Animated
Shorts, Live Action Shorts, Documentaries, Longer Features), each item's
`streamUrl` pointing directly at the Commons-hosted webm/ogv file.

Editing `feed/feed.json` in this repo (pushed to `main`) updates the channel
live — `MainScene.brs`'s `FEED_URL()` points at the GitHub raw URL for this
file, with the packaged copy as offline fallback.

Excluded on this pass: Indonesian-language student films, and the Mr. Bean
clips (kept out to be safe on rights/likeness).

## Status

v1 (build 1) — not yet sideloaded or tested on a Roku device. Icon/splash
are a first pass, same visual language as the movies channel with new
wordmark. Next: sideload + test playback across formats (webm/ogv), confirm
Roku's Video node handles all of them cleanly, swap any that don't.
