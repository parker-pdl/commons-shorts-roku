# Common Grounds — web / webOS TV app

The web front-end for **Common Grounds** (Wiki Common Grounds), the free public-domain
& Creative Commons short-film app. This is the version submitted to the LG Seller Lounge
(webOS) for QA.

- **Live URL:** https://common-grounds-tv.parkerdatalinktv.workers.dev
- **Feed:** https://commons-shorts-feed.parkerdatalinktv.workers.dev
  (a CORS-enabled proxy of `feed/feed.json` in this repo)
- **App ID (LG):** `com.parkerdatalink.commongrounds`

## Files

- `index.html` — the whole app (single file, no build step). Fetches the feed
  client-side and renders category rows of title-card thumbnails. Supports LG
  Magic Remote / keyboard: arrows to browse, OK/Enter to play, Back to return.
- `worker.js` — optional Cloudflare Worker wrapper that serves `index.html`
  (used if you'd rather deploy as a script Worker than a static upload).

## Deploy

Deployed as a Cloudflare Worker via **Workers & Pages → Create → Upload your static
files**, uploading `index.html`. To update, re-upload `index.html` to the
`common-grounds-tv` worker.

Same look and architecture as the Free Classic Movies & TV channel; the only
schema difference is the shorts feed has no `poster` field, so thumbnails are
generated title cards.
