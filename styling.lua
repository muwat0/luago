local lfs = require("lfs")
local module = {}
local function styleLists(s)
    local lines = {}
    for line in (s .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(lines, line)
    end

    local result = {}
    local inUl = false
    local inOl = false

    for _, line in ipairs(lines) do
        local ulItem = line:match("^[%-%*%+]%s+(.*)")
        local olItem = line:match("^%d+%.%s+(.*)")

        if ulItem then
            if inOl then
                table.insert(result, "</ol>")
                inOl = false
            end
            if not inUl then
                table.insert(result, "<ul>")
                inUl = true
            end
            table.insert(result, "<li>" .. ulItem .. "</li>") -- ulItem!
        elseif olItem then
            if inUl then
                table.insert(result, "</ul>")
                inUl = false
            end
            if not inOl then
                table.insert(result, "<ol>")
                inOl = true
            end
            table.insert(result, "<li>" .. olItem .. "</li>")
        else
            if inUl then
                table.insert(result, "</ul>")
                inUl = false
            end
            if inOl then
                table.insert(result, "</ol>")
                inOl = false
            end
            table.insert(result, line)
        end
    end

    if inUl then
        table.insert(result, "</ul>")
    end
    if inOl then
        table.insert(result, "</ol>")
    end

    return table.concat(result, "\n")
end
local function styleParagraph(s)
    local lines = {}
    for line in (s .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(lines, line)
    end

    local result = {}
    local pLines = {}

    local function flushP()
        if #pLines > 0 then
            table.insert(result, "<p>" .. table.concat(pLines, "\n") .. "</p>")
            pLines = {}
        end
    end

    for _, line in ipairs(lines) do
        local isBlock = line:match("^<") or line:match("^#")
        local isEmpty = line:match("^%s*$")

        if isBlock or isEmpty then
            flushP()
            table.insert(result, line)
        else
            table.insert(pLines, line)
        end
    end
    flushP()

    return table.concat(result, "\n")
end
function module.transform(s)
    -- blockquote
    local lines = {}
    for line in (s .. "\n"):gmatch("([^\n]*)\n?") do
        local nline = line:gsub("^>%s*(.*)", "<blockquote>%1</blockquote>")
        table.insert(lines, nline)
    end
    s = table.concat(lines, "\n")
    -- lists
    s = styleLists(s)
    -- paragraph
    s = styleParagraph(s)
    s = s:gsub("<p></p>", "")
    -- line breaks
    s = s:gsub("\r?\n", "<br>")
    -- remove <br> tags around block elements
    local blockTags = { "ul", "ol", "li", "blockquote", "p", "h1", "h2", "h3", "h4", "h5", "h6", "hr" }
    for _, tag in ipairs(blockTags) do
        s = s:gsub("(</" .. tag .. ">)<br>", "%1")
        s = s:gsub("<br>(</" .. tag .. ">)", "%1")
        s = s:gsub("(<" .. tag .. ">)<br>", "%1")
        s = s:gsub("<br>(<" .. tag .. ">)", "%1")
    end
    -- self-closing hr
    s = s:gsub("(<hr>)<br>", "%1")
    s = s:gsub("<br>(<hr>)", "%1")
    -- headers
    s = s:gsub("######%s*(.-)%s*<br>", "<h6>%1</h6>")
    s = s:gsub("#####%s*(.-)%s*<br>", "<h5>%1</h5>")
    s = s:gsub("####%s*(.-)%s*<br>", "<h4>%1</h4>")
    s = s:gsub("###%s*(.-)%s*<br>", "<h3>%1</h3>")
    s = s:gsub("##%s*(.-)%s*<br>", "<h2>%1</h2>")
    s = s:gsub("#%s*(.-)%s*<br>", "<h1>%1</h1>")
    -- TODO: h1 and h2 using == and --
    -- bold and italic text
    s = s:gsub("%*%*(.-)%*%*", "<b>%1</b>")
    s = s:gsub("%*(.-)%*", "<i>%1</i>")
    s = s:gsub("%_%_(.-)%_%_", "<b>%1</b>")
    s = s:gsub("%_(.-)%_", "<i>%1</i>")
    -- images
    s = s:gsub("!%[(.-)%]%((.-)%)", '<img src="%2" alt="%1"></img>')
    -- links
    s = s:gsub("%[(.-)%]%((.-)%)", '<a href="%2">%1</a>')
    -- code
    s = s:gsub("`(.-)`", "<code>%1</code>")
    -- horizontal rule
    s = s:gsub("%-%-%-", "<hr>")

    return s
end

function module.formatShortcode(element, markdownFiles, index)
    local dir = markdownFiles[index].filePath:match("(.*)/[^/]+%.md$")
    local results = {}

    for mdfile in lfs.dir(dir) do
        if mdfile:match("%.md$") and mdfile ~= markdownFiles[index].fileName .. ".md" then
            local fileName = mdfile:match("(.-)%.md$")

            for i, _ in ipairs(markdownFiles) do
                if markdownFiles[i].fileName == fileName then
                    local copy = element

                    -- replace items starting with list.item.
                    for option in copy:gmatch("{{list%.item%.(.-)}}") do
                        local value = markdownFiles[i].options[option]
                        if value then
                            copy = copy:gsub("{{list%.item%." .. option .. "}}", value)
                        end
                    end

                    table.insert(results, copy)
                end
            end
        end
    end

    return table.concat(results, "\n")
end

return module
