local lfs = require("lfs")

-- list of markdown files in working directory
local markdownFiles = {}

local haveIndexmd = false
local haveIndexhtml = false
-- amount of markdown files in working directory
local markdownFileCount = 0
local currentDir = lfs.currentdir()
for file in lfs.dir(currentDir) do
    -- ignore "." and ".." files
    if not(file:sub(1,2) == ".." or file:sub(1,1) == '.') then
        local filePath = currentDir .. '/' .. file
        if file:match("index.md") then haveIndexmd = true end
        if file:match("index.html") then haveIndexhtml = true end
        -- match file names ending with ".md"
        if file:match("%.md$") then
            markdownFileCount = markdownFileCount + 1
            markdownFiles[markdownFileCount] = {
                options = {},
                filePath = filePath,
                fileName = file:sub(1, file:len()-3),
                content = "",
                hasHtml = false
            }
        end
    end
end
-- check html files with same name as the md files
for file in lfs.dir(currentDir) do
    if file:match("%.html$") then
        for index, value in ipairs(markdownFiles) do
            if file:match(value.fileName .. ".html") then
                markdownFiles[index].hasHtml = true
                print(value.fileName .. "file has a html template file.")
            end
        end
    end
end

-- stop the program if "index.html" or "index.md" doesn't exist
if (not(haveIndexhtml) and not(haveIndexmd)) then return print("Can't find index.html or index.md!") end

-- check for options section on every markdown file
for index, file in ipairs(markdownFiles) do
    local f = io.open(file.filePath, 'r')
    if f then
        local content = f:read("*all")
        f:close()
        if content:sub(1,4) ~= "---\n" then
            return print(file.filePath .. " file doesn't have a options section!")
        end
        local fileOptions = content:sub(5, content:len())
        if fileOptions:find("---") then
            fileOptions = fileOptions:sub(1, fileOptions:find("---\n")-1)
            local lines = {}
            local lineCount = 0
            while fileOptions:find("\n") do
                lineCount = lineCount + 1
                lines[lineCount] = fileOptions:sub(1, fileOptions:find("\n"))
                fileOptions = fileOptions:sub(fileOptions:find("\n")+1, fileOptions:len())
            end

            -- fill options table
            for _, value in ipairs(lines) do
                if value:sub(value:len(), value:len()) == "\n" then
                    value = value:sub(1, value:find("\n")-1)
                end
                local colonPos = value:find(":")
                if colonPos then
                    local key = value:sub(1, colonPos - 1):match("^%s*(.-)%s*$")
                    local val = value:sub(colonPos + 1):match("^%s*(.-)%s*$")
                    if key and key ~= "" then
                        markdownFiles[index].options[key] = val
                    end
                end
            end
        else
            return print(file.filePath .. " file doesn't have a options section!")
        end
    else
        print("can't read the file " .. file.filePath)
    end
end

-- replace markdownFiles.content with md file content
for index, _ in ipairs(markdownFiles) do
    local f = io.open(markdownFiles[index].filePath)
    if f then
        local content = f:read("*a")
        f:close()

        -- delete options section
        content = content:sub(5, content:len())
        content = content:sub(content:find("---\n")+4, content:len())

        markdownFiles[index].content = content
    end
end

for index, _ in ipairs(markdownFiles) do
    print("---------------")
    -- print file path with index
    print(index .. ': ' .. markdownFiles[index].filePath)
    local f = io.open(markdownFiles[index].filePath, 'r')
    if f then
        f:close()
        -- print file content
        print(markdownFiles[index].content)
        -- print file options
        print("--- OPTIONS ---")
        for key, val in pairs(markdownFiles[index].options) do
            print(key .. ": " .. val)
        end
        print("---------------")
    else
        print("can't read the file " .. markdownFiles[index].filePath)
    end
end

-- get index.html content
local indexFile = io.open("index.html"):read("*all")

-- delete html files and create "public/" directory
for file in lfs.dir(currentDir .. "/public") do
    if file:match("%.html$") then
        os.remove(currentDir .. "/public/" .. file)
    end
end
lfs.mkdir("public")

for index, _ in ipairs(markdownFiles) do
    if markdownFiles[index].options["draft"] ~= "yes" then
        local workDir = lfs.currentdir()
        -- create html file for that md file
        local htmlFile = io.open(workDir .. "/public/" .. markdownFiles[index].fileName .. ".html", 'w')
        if htmlFile then
            local content = indexFile
            if markdownFiles[index].hasHtml then content = io.open(markdownFiles[index].fileName .. ".html"):read("*all") end

            -- STYLING
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
                        if inOl then table.insert(result, "</ol>"); inOl = false end
                        if not inUl then table.insert(result, "<ul>"); inUl = true end
                        table.insert(result, "<li>" .. ulItem .. "</li>")  -- ulItem!

                    elseif olItem then
                        if inUl then table.insert(result, "</ul>"); inUl = false end
                        if not inOl then table.insert(result, "<ol>"); inOl = true end
                        table.insert(result, "<li>" .. olItem .. "</li>")

                    else
                        if inUl then table.insert(result, "</ul>"); inUl = false end
                        if inOl then table.insert(result, "</ol>"); inOl = false end
                        table.insert(result, line)
                    end
                end

                if inUl then table.insert(result, "</ul>") end
                if inOl then table.insert(result, "</ol>") end

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
            local function styling(s)
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
                local blockTags = { "ul", "ol", "li", "blockquote", "p",
                "h1", "h2", "h3", "h4", "h5", "h6", "hr" }
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
            markdownFiles[index].content = styling(markdownFiles[index].content)

            -- replace <!-- sitecontents --> with markdown file content
            local start_idx, end_idx = content:find("<!-- sitecontents -->", 1, true)
            if start_idx and end_idx then
                local first = content:sub(1, start_idx - 1)
                local second = content:sub(end_idx + 1)
                content = first .. markdownFiles[index].content .. second
            end
            while content:find("<!-- title -->", 1, true) do
                start_idx, end_idx = content:find("<!-- title -->", 1, true)
                if start_idx and end_idx then
                    local first = content:sub(1, start_idx - 1)
                    local second = content:sub(end_idx + 1)
                    content = first .. markdownFiles[index].options["title"] .. second
                end
            end

            -- list shortcodes
            while content:find("{{list:}}", 1, true) do
                start_idx, end_idx = content:find("{{list:}}")
                if start_idx and end_idx then
                    local first = content:sub(1, start_idx - 1)
                    local second = content:sub(end_idx + 1)
                    if second:find("{{:list}}", 1, true) then
                        start_idx, end_idx = second:find("{{:list}}")
                        if start_idx and end_idx then
                            local shortcode = second:sub(1, start_idx - 1)
                            local third = second:sub(end_idx + 1)
                            local function formatShortcode(element)
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
                            shortcode = formatShortcode(shortcode)
                            content = first .. shortcode .. third
                        end
                    end
                end
            end

            htmlFile:write(content)
            htmlFile:close()
        else
            print("Error: Cannot create html file for " .. markdownFiles[index].filePath)
        end
    end
end
