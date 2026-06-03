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

            for i, value in ipairs(lines) do
                if value:sub(value:len(), value:len()) == "\n" then
                    value = value:sub(1, value:find("\n")-1)
                end
                markdownFiles[index].options[i] = value
            end
        else
            return print(file.filePath .. " file doesn't have a options section!")
        end
    else
        print("can't read the file " .. file.filePath)
    end
end

for index, value in ipairs(markdownFiles) do
    -- print file path with index
    print(index .. ': ' .. markdownFiles[index].filePath)
    local f = io.open(markdownFiles[index].filePath, 'r')
    if f then
        local content = f:read("*all")
        f:close()
        -- print file content
        print(content)
        -- print file options
        print("--- OPTIONS ---")
        for i, value in ipairs(markdownFiles[index].options) do
            print(markdownFiles[index].options[i])
        end
        print("---------------")
    else
        print("can't read the file " .. markdownFiles[index].filePath)
    end
end

-- get index.html content
local indexFile = io.open("index.html"):read("*all")

-- remove and create "public/" directory
lfs.rmdir("public")
lfs.mkdir("public")

for index, value in ipairs(markdownFiles) do
    local workDir = lfs.currentdir()
    -- create html file for that md file
    local htmlFile = io.open(workDir .. "/public/" .. markdownFiles[index].fileName .. ".html", 'w')
    if htmlFile then
        local content = indexFile
        -- replace <!-- sitecontents --> with markdown file content

        htmlFile:write(content)
        htmlFile:close()
    else
        print("Error: Cannot create html file for " .. markdownFiles[index].filePath)
    end
end

