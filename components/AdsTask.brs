' =============================================================================
' AdsTask.brs — Roku Ad Framework pre-roll runner (task thread)
' =============================================================================
' 1. Ask the Parker Data Link house-ad server (VAST 3.0) for a spot.
' 2. If it returns nothing, fall back to Roku's default ad fill.
' =============================================================================
Library "Roku_Ads.brs"

sub init()
    m.top.functionName = "runAds"
end sub

function houseAdUrl() as String
    return "https://pdl-ads.parkerdatalinktv.workers.dev/vast?ch=shorts"
end function

sub runAds()
    ' PDL promo content plays ad-free
    if m.top.skipAds
        m.top.adResult = true
        return
    end if

    watched = true
    adIface = Roku_Ads()
    adIface.setDebugOutput(false)

    ' House ads first
    adIface.setAdUrl(houseAdUrl())
    adPods = adIface.getAds()

    ' Fall back to Roku's own fill if the house server had nothing
    if adPods = invalid or adPods.count() = 0
        adIface.setAdUrl()
        adPods = adIface.getAds()
    end if

    if adPods <> invalid and adPods.count() > 0
        watched = adIface.showAds(adPods)
    end if
    m.top.adResult = watched
end sub
