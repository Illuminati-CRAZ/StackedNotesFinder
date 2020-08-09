function draw()
    imgui.Begin("ive ranked three (3) maps with overlapping notes")

    state.IsWindowHovered = imgui.IsWindowHovered()

    local lenience = state.GetValue("lenience") or 0

    local errors = state.GetValue("errors") or {}

    --local debug = state.GetValue("debug") or "hi"
    local errorstring = state.GetValue("errorstring") or ""

    local currentobject = state.GetValue("currentobject") or 0

    local showcopytext = state.GetValue("showcopytext") or false

    _, lenience = imgui.InputInt("Lenience", lenience)
    if lenience < 0 then lenience = 0 end

    --the following code is bad, do not do this
    --it took over a minute to check my 15.5k note 4k map
    --it took almost half a minute to check Uta, a 12.1k note 7k map
    --[[if imgui.Button("no guarantees") then
        local notes = {}

        for i=1,8,1 do
            notes[i] = {}
        end

        for _,note in pairs(map.HitObjects) do
            table.insert(notes[note.lane], note)
        end

        local errors = {}

        for i=1,8,1 do
            local rices = {}
            local lns = {}
            for _,note in pairs(notes[i]) do
                if note.EndTime > 0 then
                    for _,rice in pairs(rices) do
                        if (note.StartTime <= rice.StartTime) and (rice.StartTime <= note.EndTime) then
                            table.insert(errors, rice.StartTime .. "|" .. i)
                        end
                    end
                    for _,ln in pairs(lns) do
                        if (ln.StartTime <= note.StartTime) and (note.StartTime <= ln.EndTime) then
                            table.insert(errors, note.StartTime .. "|" .. i)
                        elseif (ln.StartTime <= note.EndTime) and (note.EndTime <= ln.EndTime) then
                            table.insert(errors, note.EndTime .. "|" .. i)
                        end
                    end
                    table.insert(lns, note)
                else
                    for _,rice in pairs(rices) do
                        if note.StartTime == rice.StartTime then
                            table.insert(errors, note.StartTime .. "|" .. i)
                        end
                    end
                    for _,ln in pairs(lns) do
                        if (ln.StartTime <= note.StartTime) and (note.StartTime <= ln.EndTime) then
                            table.insert(errors, note.StartTime .. "|" .. i)
                        end
                    end
                    table.insert(rices, note)
                end
            end
        end

        errorstring = ""
        for _,error in pairs(errors) do
            errorstring = errorstring .. error .. ", "
        end
        errorstring = errorstring:sub(1,-3)

        if errorstring == "" then
            errorstring = "probably no stacked notes"
        end
    end]]--

    --this one's better, I think
    --i didn't really test this thoroughly to make sure it catches everything, but I think the logic is sound(?)
    --okay nevermind I found a problem like 6 hours later and fixed it probably
    --only takes at most a few seconds for a 15k note map
    if imgui.Button(":flushed:") then
        local notes = {}

        for i=1,8,1 do
            notes[i] = {}
        end

        for _,note in pairs(map.HitObjects) do
            table.insert(notes[note.lane], note)
        end

        --for verifying that map.HitObjects returned notes in order
        --[[debug = ""
        for _,column in pairs(notes) do
            prev = -1
            for _,note in pairs(column) do
                if note.StartTime <= prev then
                    debug = debug .. "false" .. ", "
                    break
                else
                    prev = note.StartTime
                end
            end
            debug = debug .. "true" .. ", "
        end--]]

        errors = {}

        for i=1,8,1 do
            local prev = utils.CreateHitObject(-1, i)
            local prevstart = -1
            local prevend = -1
            for _,note in pairs(notes[i]) do
                if note.EndTime > 0 then
                    if (prevstart <= note.StartTime) and (note.StartTime <= prevend + lenience) then
                        table.insert(errors, note)
                    elseif (prevstart - lenience <= note.EndTime) and (note.EndTime <= prevend) then
                        table.insert(errors, note)
                    elseif (note.StartTime - lenience <= prev.StartTime) and (prev.StartTime <= note.EndTime + lenience) then
                        table.insert(errors, prev)
                    end
                    prevstart = note.StartTime
                    if note.EndTime > prevend then
                        prevend = note.EndTime
                    end
                else
                    if (prevstart - lenience <= note.StartTime) and (note.StartTime <= prevend + lenience) then
                        table.insert(errors, note)
                    elseif (prev.StartTime - lenience <= note.StartTime) and (note.StartTime <= prev.StartTime + lenience) then
                        table.insert(errors, note)
                    end
                    prev = note
                end
            end
        end

        table.sort(errors, function(a, b) return a.StartTime < b.StartTime end)

        errorstring = ""
        for _,error in pairs(errors) do
            errorstring = errorstring .. error.StartTime .. "|" .. error.Lane .. ", "
        end
        errorstring = errorstring:sub(1,-3)

        if errorstring == "" then
            errorstring = "probably no stacked notes"
        end

        currentobject = 0
    end

    if errors[1] then
        imgui.Text("")
        --imgui.Columns(3)
        if imgui.Button("Go to Previous Object") then
            if currentobject > 1 then
                currentobject = currentobject - 1
            else
                currentobject = #errors
            end
            actions.GoToObjects(errors[currentobject].StartTime .. "|" .. errors[currentobject].Lane)
            showcopytext = false
        end


        imgui.SameLine(0, 4)
        --imgui.separator()
        --imgui.NextColumn()
        if imgui.Button("Go to Next Object") then
            if currentobject < #errors then
                currentobject = currentobject + 1
            else
                currentobject = 1
            end
            actions.GoToObjects(errors[currentobject].StartTime .. "|" .. errors[currentobject].Lane)
            showcopytext = false
        end

        imgui.SameLine(0, 4)
        --imgui.NextColumn()
        if imgui.Button("Copy to Clipboard") then
            imgui.SetClipboardText(errorstring)
            showcopytext = true
        end

        --imgui.Columns(1)

        imgui.TextWrapped(currentobject .. "/" .. #errors)
        if showcopytext then
            imgui.SameLine(0,4)
            imgui.TextWrapped("Copied!")
        end
    end

    imgui.TextWrapped(errorstring)
    if errorstring != "" then
        imgui.TextWrapped("")
    end

    --imgui.TextWrapped(debug)

    imgui.TextWrapped("what if we kissed.... during the overlapped note in uta :flushed:")

    state.SetValue("lenience", lenience)

    state.SetValue("errorstring", errorstring)

    state.SetValue("errors", errors)

    state.SetValue("currentobject", currentobject)

    state.SetValue("showcopytext", showcopytext)
    
    --state.SetValue("debug", debug)

    imgui.End()
end
