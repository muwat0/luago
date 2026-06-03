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
                filePath = filePath
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
        if content:sub(1,3) ~= "---" then
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
    else
        print("can't read the file " .. markdownFiles[index].filePath)
    end
end

