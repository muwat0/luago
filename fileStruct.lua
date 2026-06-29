local lfs = require("lfs")

return function(currentDir)
    local markdownFiles = {}
    local haveIndexmd = false
    local haveIndexhtml = false
    local markdownFileCount = 0

    -- initialize markdownFiles table
    for file in lfs.dir(currentDir) do
        if not(file:sub(1, 2) == ".." or file:sub(1, 1) == '.') then
            local filePath = currentDir .. '/' .. file
            if file == "index.md" then haveIndexmd = true end
            if file == "index.html" then haveIndexhtml = true end
            if file:match("%.md$") then
                markdownFileCount = markdownFileCount + 1
                markdownFiles[markdownFileCount] = {
                    options = {},
                    filePath = filePath,
                    fileName = file:sub(1, file:len() - 3),
                    content = "",
                    hasHtml = false
                }
            end
        end
    end

    -- check html files
    for file in lfs.dir(currentDir) do
        if file:match("%.html$") then
            for index, value in ipairs(markdownFiles) do
                if file == value.fileName .. ".html" then
                    markdownFiles[index].hasHtml = true
                    print(value.fileName .. " file has a html template file.")
                end
            end
        end
    end

    if not(haveIndexhtml) or not(haveIndexmd) then
        return nil, "Can't find index.html or index.md!"
    end

    return markdownFiles
end
