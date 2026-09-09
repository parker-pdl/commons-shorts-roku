' =============================================================================
' MainScene.brs — screen orchestrator + remote feed bootstrap + deep linking
' =============================================================================
' Loads the catalogue from a remote JSON feed via the ContentLoader Task (with a
' bundled fallback), wires Splash -> Intro bumper -> Home -> Detail navigation,
' and handles deep links (launch / input with contentId + mediaType) required
' by Roku cert.
'
' v1.3: a full-screen intro video plays once on normal launch, after the splash.
'   • OK / Back / Play (or any stream error) skips it.
'   • Deep links bypass it entirely — cert requires deep-linked titles to begin
'     playback directly.
' =============================================================================

' Where the channel pulls its catalogue from. Editing feed/feed.json in the repo
' updates the channel without a rebuild.
function FEED_URL() as string
    return "https://commons-shorts-feed.parkerdatalinktv.workers.dev"
end function

' Launch bumper played once on startup (skippable).
function INTRO_URL() as string
    return "https://pub-4a1ee3e926844caba75e0b33d0b2208d.r2.dev/video_147169.mp4"
end function

sub init()
    m.splashScreen = m.top.findNode("splashScreen")
    m.homeScreen   = m.top.findNode("homeScreen")
    m.detailScreen = m.top.findNode("detailScreen")
    m.introPlayer  = m.top.findNode("introPlayer")
    m.introBacking = m.top.findNode("introBacking")

    m.splashDone   = false
    m.contentReady = false
    m.contentRoot  = invalid
    m.masterRoot   = invalid
    m.pendingDeepLinkId = invalid
    m.launchBeaconFired = false

    ' Intro bumper state: playing -> done (skipped, finished, or errored)
    m.introStarted = false
    m.introDone    = false

    m.splashScreen.observeField("splashComplete", "onSplashComplete")
    m.homeScreen.observeField("itemSelected",     "onItemSelected")
    m.detailScreen.observeField("goBack",         "onDetailBack")
    m.introPlayer.observeField("state",           "onIntroStateChanged")

    ' Deep-link contentId can arrive before OR after the feed finishes loading
    m.top.observeField("deepLinkContentId", "onDeepLinkChanged")
    if m.top.deepLinkContentId <> invalid and m.top.deepLinkContentId <> ""
        m.pendingDeepLinkId = m.top.deepLinkContentId
    end if

    startContentLoad()
end sub

sub startContentLoad()
    m.loader = createObject("roSGNode", "ContentLoader")
    m.loader.feedUrl = FEED_URL()
    m.loader.observeField("content", "onContentLoaded")
    m.loader.control = "RUN"
end sub

sub onContentLoaded()
    root = m.loader.content
    if root <> invalid and root.getChildCount() > 0
        m.masterRoot  = root   ' pristine tree — never mutated or reparented
        m.contentRoot = root   ' used for deep-link lookup
        m.lastBmSig = invalid
        rebuildHomeContent()
        m.contentReady = true

        ' Roku cert: signal the channel has finished launching (fire once)
        if not m.launchBeaconFired
            m.top.signalBeacon("AppLaunchComplete")
            m.launchBeaconFired = true
        end if

        if m.pendingDeepLinkId <> invalid
            tryDeepLink()
        else if m.splashDone and m.introDone
            revealHome()
        end if
    end if
end sub

' ─── Intro bumper ────────────────────────────────────────────────────────────

sub startIntro()
    if m.introStarted then return
    m.introStarted = true

    url = INTRO_URL()
    if url = invalid or url = ""
        finishIntro()
        return
    end if

    videoContent = createObject("roSGNode", "ContentNode")
    videoContent.url          = url
    videoContent.title        = ""
    videoContent.streamFormat = "mp4"

    m.splashScreen.visible = false
    m.introBacking.visible = true
    m.introPlayer.content  = videoContent
    m.introPlayer.visible  = true
    m.introPlayer.control  = "play"
    m.introPlayer.setFocus(true)
end sub

sub onIntroStateChanged()
    state = m.introPlayer.state
    if state = "finished" or state = "error"
        finishIntro()
    else if state = "stopped" and m.introStarted and not m.introDone
        finishIntro()
    end if
end sub

sub finishIntro()
    if m.introDone then return
    m.introDone = true

    m.introPlayer.control = "stop"
    m.introPlayer.visible = false
    m.introPlayer.content = invalid
    m.introBacking.visible = false

    if m.pendingDeepLinkId <> invalid
        if m.contentReady then tryDeepLink()
    else if m.contentReady
        revealHome()
    end if
    ' If content isn't ready yet, onContentLoaded reveals Home when it lands.
end sub

' Skip the bumper on OK / Back / Play; swallow everything else while it runs.
function onKeyEvent(key as String, press as Boolean) as Boolean
    if press and m.introStarted and not m.introDone
        if key = "OK" or key = "back" or key = "play"
            finishIntro()
        end if
        return true
    end if
    return false
end function

' ─── Deep linking ────────────────────────────────────────────────────────────

sub onDeepLinkChanged()
    id = m.top.deepLinkContentId
    if id <> invalid and id <> ""
        m.pendingDeepLinkId = id
        ' A deep link always outranks the bumper
        if m.introStarted and not m.introDone then finishIntro()
        tryDeepLink()
    end if
end sub

sub tryDeepLink()
    if m.pendingDeepLinkId = invalid or m.contentRoot = invalid then return

    ' Never let the bumper play over (or after) a deep link
    if m.introStarted and not m.introDone
        finishIntro()
    else
        m.introStarted = true
        m.introDone    = true
    end if

    item = findItemById(m.contentRoot, m.pendingDeepLinkId)
    if item <> invalid
        ' Jump straight to the title's detail screen, skipping splash/home
        m.splashScreen.visible = false
        m.homeScreen.visible   = false
        m.detailScreen.itemContent = item
        m.detailScreen.visible = true
        m.detailScreen.setFocus(true)

        ' Roku cert (deep-link 5.x + content-play 3.6): a deep-linked title must
        ' BEGIN PLAYBACK, not just show the springboard. Every catalogue item is a
        ' playable movie/short, so auto-play on any deep link regardless of mediaType.
        m.detailScreen.autoPlay = true

        m.pendingDeepLinkId = invalid
    end if
end sub

function findItemById(root as object, id as string) as object
    for each cat in root.getChildren(-1, 0)
        for each it in cat.getChildren(-1, 0)
            if it.id = id then return it
        end for
    end for
    return invalid
end function

' ─── Screen transitions ──────────────────────────────────────────────────────

sub onSplashComplete()
    m.splashDone = true
    ' If a deep link is in flight, NEVER fall back to Home or the bumper (that
    ' home flash can fail the deep-link test). Wait for content — onContentLoaded
    ' fires tryDeepLink — then jump straight to the title.
    if m.pendingDeepLinkId <> invalid
        if m.contentReady then tryDeepLink()
    else if m.detailScreen.visible = false
        startIntro()
    end if
end sub

sub revealHome()
    m.splashScreen.visible = false
    m.detailScreen.visible = false
    m.homeScreen.visible   = true
    m.homeScreen.setFocus(true)
end sub

sub onItemSelected(event as Dynamic)
    selectedItem = event.getData()
    if selectedItem <> invalid
        m.detailScreen.itemContent = selectedItem
        m.homeScreen.visible   = false
        m.detailScreen.visible = true
        m.detailScreen.setFocus(true)
    end if
end sub

sub onDetailBack()
    ' Refresh the Continue Watching row if the user's progress changed
    rebuildHomeContent()
    m.detailScreen.visible = false
    m.homeScreen.visible   = true
    m.homeScreen.setFocus(true)
end sub

' ─── Continue Watching row ───────────────────────────────────────────────────
' Rebuilds the home content tree with a "Continue Watching" row on top,
' assembled from bookmarks saved in the device registry. Skipped entirely
' when the bookmark set hasn't changed, so casual back-and-forth navigation
' never resets the browse position.
sub rebuildHomeContent()
    if m.masterRoot = invalid then return

    map = bmLoad()
    sig = FormatJson(map)
    if sig = m.lastBmSig then return
    m.lastBmSig = sig

    ' Build a FRESH display tree from clones every time. The master tree is
    ' never mutated and no node is ever reparented out of a live RowList —
    ' reparenting live content wedges the list's internal state on-device.
    newRoot = createObject("roSGNode", "ContentNode")

    ' Collect bookmarked items (dedupe: titles can appear in several rows)
    entries = []
    seen = {}
    for each cat in m.masterRoot.getChildren(-1, 0)
        for each it in cat.getChildren(-1, 0)
            if it.id <> "" and map.doesExist(it.id) and not seen.doesExist(it.id)
                seen[it.id] = true
                bm = map[it.id]
                ts = 0
                if bm.ts <> invalid then ts = bm.ts
                entries.push({ item: it, ts: ts })
            end if
        end for
    end for

    if entries.count() > 0
        ' Newest-watched first (insertion sort; the row is capped at 10)
        sorted = []
        for each e in entries
            inserted = false
            for i = 0 to sorted.count() - 1
                if e.ts > sorted[i].ts
                    sorted = insertAt(sorted, e, i)
                    inserted = true
                    exit for
                end if
            end for
            if not inserted then sorted.push(e)
        end for

        cwCat = newRoot.createChild("ContentNode")
        cwCat.title = "Continue Watching"
        for each e in sorted
            cwCat.appendChild(e.item.clone(true))
        end for
    end if

    ' Clone the catalogue rows into the display tree
    for each cat in m.masterRoot.getChildren(-1, 0)
        newRoot.appendChild(cat.clone(true))
    end for

    m.homeScreen.content = newRoot
end sub

function insertAt(arr as object, e as object, idx as integer) as object
    out = []
    for i = 0 to arr.count() - 1
        if i = idx then out.push(e)
        out.push(arr[i])
    end for
    return out
end function
