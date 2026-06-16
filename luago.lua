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
        -- match file names ending with ".md"
        if file:match("index.md") then haveIndexmd = true end
        if file:match("index.html") then haveIndexhtml = true end
        if file:match("%.md$") then
            markdownFileCount = markdownFileCount + 1
            markdownFiles[markdownFileCount] = {
                options = {},
                filePath = filePath,
                fileName = file:sub(1, file:len()-3),
                content = ""
            }
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
            for i, value in ipairs(lines) do
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
for index, value in ipairs(markdownFiles) do
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

for index, value in ipairs(markdownFiles) do
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
local siteName
local siteTitle

-- remove and create "public/" directory
lfs.rmdir("public")
lfs.mkdir("public")

for index, value in ipairs(markdownFiles) do
    local workDir = lfs.currentdir()
    -- create html file for that md file
    local htmlFile = io.open(workDir .. "/public/" .. markdownFiles[index].fileName .. ".html", 'w')
    if htmlFile then
        local content = indexFile

        -- STYLING
        local function styling(s)
            -- blockquote
            -- s = s:gsub(">%s*(.-)%s*\r?\n", "<blockquote>%1</blockquote>")
            local lines = {}
            for line in s:gmatch("([^\n]*)\n?") do
                local nline = line:gsub("^>%s*(.*)", "<blockquote>%1</blockquote>")
                table.insert(lines, nline)
            end
            s = table.concat(lines, "\n")
            -- line breaks
            s = s:gsub("\r?\n", "<br>")
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
            -- TODO: ordered and unordered lists

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

        htmlFile:write(content)
        htmlFile:close()
    else
        print("Error: Cannot create html file for " .. markdownFiles[index].filePath)
    end
end

