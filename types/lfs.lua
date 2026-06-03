---@meta
---@class lfs
local lfs = {}

---@param filepath string
---@param aname? string|table
---@return table|string|nil result
---@return string? error_msg
function lfs.attributes(filepath, aname) end

---@param path string
---@return boolean success
---@return string? error_msg
function lfs.chdir(path) end

---@return string path
function lfs.currentdir() end

---@param path string
---@return fun():string iter
---@return table dir_obj
function lfs.dir(path) end

---@param dirname string
---@return boolean success
---@return string? error_msg
function lfs.mkdir(dirname) end

---@param dirname string
---@return boolean success
---@return string? error_msg
function lfs.rmdir(dirname) end

---@param filepath string
---@param atime? number
---@param mtime? number
---@return boolean success
---@return string? error_msg
function lfs.touch(filepath, atime, mtime) end

return lfs
