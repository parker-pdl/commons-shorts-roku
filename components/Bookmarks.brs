' =============================================================================
' Bookmarks.brs — continue-watching bookmark storage (device registry)
' =============================================================================
' Shared by MainScene (builds the Continue Watching row) and DetailScreen
' (saves/loads resume positions). Bookmarks persist on the device in
' roRegistrySection "PDLContinueWatching" as a single JSON map:
'   { "<item id>": { "pos": seconds, "dur": seconds, "ts": savedAtEpoch } }
' Capped to the 10 most recent titles.
' =============================================================================

function bmSection() as object
    return createObject("roRegistrySection", "PDLContinueWatching")
end function

' Load the full bookmark map (empty AA when none saved / parse failure)
function bmLoad() as object
    sec = bmSection()
    if sec.exists("bookmarks")
        data = ParseJson(sec.read("bookmarks"))
        if data <> invalid and GetInterface(data, "ifAssociativeArray") <> invalid
            return data
        end if
    end if
    return {}
end function

sub bmPersist(map as object)
    sec = bmSection()
    sec.write("bookmarks", FormatJson(map))
    sec.flush()
end sub

' Save/update the resume position for a title
sub bmSet(id as string, posSec as integer, dur as integer)
    if id = "" then return
    map = bmLoad()
    entry = {}
    entry.pos = posSec
    entry.dur = dur
    entry.ts  = CreateObject("roDateTime").AsSeconds()
    map[id] = entry

    ' Keep only the 10 most recently watched
    while map.count() > 10
        oldestId = invalid
        oldestTs = 0
        for each k in map
            e = map[k]
            if oldestId = invalid or e.ts < oldestTs
                oldestId = k
                oldestTs = e.ts
            end if
        end for
        if oldestId = invalid then exit while
        map.delete(oldestId)
    end while

    bmPersist(map)
end sub

' Remove a title's bookmark (finished watching, or watched past the end)
sub bmClear(id as string)
    if id = "" then return
    map = bmLoad()
    if map.doesExist(id)
        map.delete(id)
        bmPersist(map)
    end if
end sub

' Fetch one title's bookmark ({pos, dur, ts}) or invalid
function bmGet(id as string) as dynamic
    if id = "" then return invalid
    map = bmLoad()
    if map.doesExist(id) then return map[id]
    return invalid
end function

' Format seconds as "m:ss" / "h:mm:ss" for the resume hint
function bmFormatTime(seconds as integer) as string
    h = seconds \ 3600
    mn = (seconds mod 3600) \ 60
    s = seconds mod 60
    ss = s.toStr()
    if s < 10 then ss = "0" + ss
    if h > 0
        ms = mn.toStr()
        if mn < 10 then ms = "0" + ms
        return h.toStr() + ":" + ms + ":" + ss
    end if
    return mn.toStr() + ":" + ss
end function
