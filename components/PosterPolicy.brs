' =============================================================================
' PosterPolicy.brs — poster source whitelist
' =============================================================================
' Only artwork Parker uploaded to his own Cloudflare R2 buckets (or a
' parkerdatalink.com domain) is ever loaded. Any other poster URL in the feed
' is ignored and the styled title card renders instead — no network attempt.
' Shared by PosterItem, HomeScreen (hero), and DetailScreen.
' =============================================================================

function isApprovedPoster(url as dynamic) as boolean
    if url = invalid then return false
    if type(url) <> "roString" and type(url) <> "String" then return false
    if url = "" then return false

    u = LCase(url)
    ' classic-posters bucket
    if Instr(1, u, "pub-3ece269d2dd44298a19cc5f5355f7802.r2.dev/") > 0 then return true
    ' mp4-media-and-videos bucket (also holds channel imagery)
    if Instr(1, u, "pub-4a1ee3e926844caba75e0b33d0b2208d.r2.dev/") > 0 then return true
    ' any current/future custom domain
    if Instr(1, u, "parkerdatalink.com/") > 0 then return true
    ' packaged assets are always fine
    if Instr(1, u, "pkg:/") = 1 then return true

    return false
end function
