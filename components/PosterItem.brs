' =============================================================================
' PosterItem.brs — poster card renderer + focus animation + title-card fallback
' =============================================================================
' v1.3: titles without an original poster render a styled title card instead
' of a generic fallback image. Triggered when the feed has no poster URL, or
' when the poster URL fails to load. The glow tint follows the category row.
' =============================================================================

sub init()
    m.posterImage = m.top.findNode("posterImage")
    m.titleLabel  = m.top.findNode("titleLabel")
    m.titleScrim  = m.top.findNode("titleScrim")
    m.focusBorder = m.top.findNode("focusBorder")
    m.cardBg      = m.top.findNode("cardBg")
    m.titleCard   = m.top.findNode("titleCard")
    m.tcGlow      = m.top.findNode("tcGlow")
    m.tcTitle     = m.top.findNode("tcTitle")
    m.tcYear      = m.top.findNode("tcYear")

    m.posterImage.observeField("loadStatus", "onPosterLoadStatus")

    ' Scale from the card's centre so focus growth is symmetric
    m.top.scaleRotateCenter = [100, 150]
end sub

sub onItemContentChanged()
    item = m.top.itemContent
    if item = invalid then return

    m.titleLabel.text = item.title

    url = item.HDPosterUrl
    if not isApprovedPoster(url)
        ' Not artwork from Parker's R2 bucket — render the title card,
        ' and never attempt to fetch third-party posters.
        showTitleCard(item)
    else
        ' Reset to poster mode; the loadStatus observer flips to the
        ' title card if this URL turns out to be dead.
        m.titleCard.visible   = false
        m.posterImage.visible = true
        m.posterImage.uri     = url
    end if
end sub

' Poster URL failed to load (404 / dead host) -> render the title card
sub onPosterLoadStatus()
    if m.posterImage.loadStatus = "failed"
        showTitleCard(m.top.itemContent)
    end if
end sub

sub showTitleCard(item as Dynamic)
    if item = invalid then return
    m.posterImage.visible = false

    m.tcTitle.text = UCase(item.title)

    yr = ""
    if item.hasField("year") then yr = item.year
    if yr = invalid then yr = ""
    m.tcYear.text = yr

    m.tcGlow.blendColor = glowForCategory(item)
    m.titleCard.visible = true
end sub

' Category-tinted glow: warm gold for the silent era, purple for the
' so-bad-it's-good row, deep ember red everywhere else.
function glowForCategory(item as Dynamic) as string
    cat = ""
    parent = item.getParent()
    if parent <> invalid and parent.title <> invalid then cat = LCase(parent.title)

    if Instr(1, cat, "animation") > 0 then return "0xE0A93AFF"
    if Instr(1, cat, "comedy") > 0 then return "0xC9A25EFF"
    if Instr(1, cat, "noir") > 0 then return "0x6E8CA8FF"
    if Instr(1, cat, "western") > 0 then return "0xB5714AFF"
    if Instr(1, cat, "sci-fi") > 0 then return "0x9A6BB5FF"
    if Instr(1, cat, "silent") > 0 then return "0xC9A25EFF"
    if Instr(1, cat, "vault") > 0 then return "0x5FA8A0FF"
    if Instr(1, cat, "retro") > 0 then return "0x5FA8A0FF"
    if Instr(1, cat, "space") > 0 then return "0x5A7FC4FF"
    if Instr(1, cat, "after dark") > 0 then return "0xB5544AFF"
    if Instr(1, cat, "so bad") > 0 then return "0x9A6BB5FF"
    if Instr(1, cat, "short") > 0 then return "0x7FA3B8FF"
    return "0xB5544AFF"
end function

' Smoothly scale + reveal the title as the card gains focus (focusPercent 0->1)
sub onFocusChanged()
    fp = m.top.focusPercent
    s  = 1.0 + (0.12 * fp)
    m.top.scale = [s, s]
    m.focusBorder.opacity = fp
    ' Title cards already carry their title — skip the redundant bottom strip
    if m.titleCard.visible
        m.titleScrim.opacity = 0.0
        m.titleLabel.opacity = 0.0
    else
        m.titleScrim.opacity = fp
        m.titleLabel.opacity = fp
    end if
end sub
