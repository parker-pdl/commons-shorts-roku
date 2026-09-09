' =============================================================================
' HomeScreen.brs — RowList wiring, spotlight hero updates, selection bubbling
' =============================================================================
' v1.3: hero poster falls back to a styled title card when the focused movie
' has no original poster (missing URL or dead link).
' =============================================================================

sub init()
    m.rowList       = m.top.findNode("rowList")
    m.heroPoster    = m.top.findNode("heroPoster")
    m.heroCardGroup = m.top.findNode("heroCardGroup")
    m.hcGlow        = m.top.findNode("hcGlow")
    m.hcTitle       = m.top.findNode("hcTitle")
    m.hcYear        = m.top.findNode("hcYear")
    m.heroTitle     = m.top.findNode("heroTitle")
    m.heroMeta      = m.top.findNode("heroMeta")
    m.heroDesc      = m.top.findNode("heroDesc")

    m.rowList.observeField("rowItemFocused",  "onRowItemFocused")
    m.rowList.observeField("rowItemSelected", "onRowItemSelected")
    m.heroPoster.observeField("loadStatus",   "onHeroPosterLoadStatus")

    ' CRITICAL: when this screen becomes visible again (e.g. returning from a
    ' movie), focus must land on the RowList itself. Focusing the HomeScreen
    ' Group does NOT forward focus to the list (initialFocus only applies at
    ' startup) — that was the "remote goes dead after watching" bug.
    m.top.observeField("visible", "onVisibleChanged")
end sub

sub onVisibleChanged()
    if m.top.visible then m.rowList.setFocus(true)
end sub

' Bind the ContentNode tree and seed the hero with the first title
sub onContentChanged()
    m.rowList.content = m.top.content
    updateHero([0, 0])
    if m.top.visible then m.rowList.setFocus(true)
end sub

sub onRowItemFocused()
    updateHero(m.rowList.rowItemFocused)
end sub

' Refresh the spotlight panel from the focused [rowIndex, itemIndex]
sub updateHero(idx as Dynamic)
    if idx = invalid or idx.count() < 2 then return
    content = m.top.content
    if content = invalid then return
    cat = content.getChild(idx[0])
    if cat = invalid then return
    item = cat.getChild(idx[1])
    if item = invalid then return

    m.heroItem = item

    m.heroTitle.text  = item.title
    m.heroDesc.text   = item.description

    url = item.HDPosterUrl
    if not isApprovedPoster(url)
        showHeroCard(item, cat.title)
    else
        m.heroCardGroup.visible = false
        m.heroPoster.visible    = true
        m.heroPoster.uri        = url
    end if

    yr   = item.year
    meta = cat.title
    if yr <> invalid and yr <> "" then meta = yr + "   •   " + cat.title
    m.heroMeta.text = meta
end sub

' Hero poster URL failed to load -> swap in the title card
sub onHeroPosterLoadStatus()
    if m.heroPoster.loadStatus = "failed" and m.heroItem <> invalid
        catTitle = ""
        parent = m.heroItem.getParent()
        if parent <> invalid and parent.title <> invalid then catTitle = parent.title
        showHeroCard(m.heroItem, catTitle)
    end if
end sub

sub showHeroCard(item as Dynamic, catTitle as Dynamic)
    m.heroPoster.visible = false

    m.hcTitle.text = UCase(item.title)

    yr = ""
    if item.hasField("year") then yr = item.year
    if yr = invalid then yr = ""
    m.hcYear.text = yr

    cat = ""
    if catTitle <> invalid then cat = LCase(catTitle)
    if Instr(1, cat, "silent") > 0
        m.hcGlow.blendColor = "0xC9A25EFF"
    else if Instr(1, cat, "so bad") > 0
        m.hcGlow.blendColor = "0x9A6BB5FF"
    else if Instr(1, cat, "short") > 0
        m.hcGlow.blendColor = "0x7FA3B8FF"
    else
        m.hcGlow.blendColor = "0xB5544AFF"
    end if

    m.heroCardGroup.visible = true
end sub

' Open the detail screen for the chosen [rowIndex, itemIndex]
sub onRowItemSelected(event as Dynamic)
    idx = event.getData()
    if idx <> invalid and idx.count() = 2
        content = m.top.content
        if content <> invalid
            cat = content.getChild(idx[0])
            if cat <> invalid
                item = cat.getChild(idx[1])
                if item <> invalid then m.top.itemSelected = item
            end if
        end if
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    return false   ' Back on the home screen exits the channel (default)
end function
