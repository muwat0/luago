local lfs = require("lfs")

-- list of markdown files in working directory
local markdownFiles = {}

-- amount of markdown files in working directory
local markdownFileCount = 0
local currentDir = lfs.currentdir()
for file in lfs.dir(currentDir) do
    -- ignore "." and ".." files
    if not(file:sub(1,3) == ".." or file:sub(1,2) == '.') then
        local filePath = currentDir .. '/' .. file
        -- match file names ending with ".md"
        if file:match("%.md$") then
            markdownFileCount = markdownFileCount + 1
            markdownFiles[markdownFileCount] = filePath
        end
    end
end


for index, value in ipairs(markdownFiles) do
    -- print file path with index
    print(index .. ': ' .. markdownFiles[index])
    local f = io.open(markdownFiles[index], 'r')
    if f then
        local content = f:read("*all")
        f:close()
        -- print file content
        print(content)
    else
        print("can't read the file ".. markdownFiles[index])
    end
end
