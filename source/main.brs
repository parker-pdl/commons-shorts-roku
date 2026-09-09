' =============================================================================
' Classic Horror Movies by: ParkerDataLink.com — Main Entry Point
' =============================================================================
' Boots the SceneGraph render thread, forwards deep-link arguments
' (contentId / mediaType) into the scene on cold start, and keeps listening for
' warm deep links via roInput — both required for Roku Channel Store cert.
' =============================================================================

sub Main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    scene = screen.CreateScene("MainScene")
    screen.show()

    ' Receive deep links that arrive while the channel is already running
    m.input = CreateObject("roInput")
    m.input.setMessagePort(m.port)

    ' Cold-start deep link (channel launched directly at a title)
    applyDeepLink(scene, args)

    ' Primary event loop
    while true
        msg = wait(0, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        else if msgType = "roInputEvent"
            applyDeepLink(scene, msg.getInfo())
        end if
    end while
end sub

' Forward contentId / mediaType into the scene if present.
sub applyDeepLink(scene as Object, params as Dynamic)
    if params <> invalid and params.contentId <> invalid and params.contentId <> ""
        if params.mediaType <> invalid then scene.deepLinkMediaType = params.mediaType
        scene.deepLinkContentId = params.contentId   ' set last so the observer sees mediaType
    end if
end sub
