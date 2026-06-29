local script_dir = debug.getinfo(1, "S").source:match("@?(.*/)")
if script_dir then package.path = script_dir .. "?.lua;" .. script_dir .. "?/init.lua;" .. package.path end

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
            local styling = require("styling")
            markdownFiles[index].content = styling.transform(markdownFiles[index].content)

            -- start_idx, end_idx = c
            -- {{pageContent}} shortcode
            content = content:gsub("{{pageContent}}", markdownFiles[index].content)
            -- {{pageTitle}} shortcode
            content = content:gsub("{{pageTitle}}", markdownFiles[index].options["title"])

            local start_idx, end_idx
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
