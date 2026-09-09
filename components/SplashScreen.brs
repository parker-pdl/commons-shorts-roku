' =============================================================================
' SplashScreen.brs — animation sequencer + skip handling
' =============================================================================

sub init()
    m.splashTimer = m.top.findNode("splashTimer")
    m.imageReveal = m.top.findNode("imageReveal")
    m.textFadeIn  = m.top.findNode("textFadeIn")
    m.glowExpand  = m.top.findNode("glowExpand")

    m.imageReveal.control = "start"
    m.textFadeIn.control  = "start"
    m.glowExpand.control  = "start"

    m.splashTimer.observeField("fire", "onSplashTimerFired")
    m.splashTimer.control = "start"
end sub

sub onSplashTimerFired()
    m.top.splashComplete = true
end sub

' Allow the viewer to skip the splash with OK or Back
function onKeyEvent(key as String, press as Boolean) as Boolean
    if press
        if key = "OK" or key = "back"
            m.splashTimer.control = "stop"
            m.top.splashComplete = true
            return true
        end if
    end if
    return false
end function
