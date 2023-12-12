local Path = require("plenary.path")
local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")
local user_config = string.format("%s/alter.json", config_path)
local cache_config = string.format("%s/alter.json", data_path)

---@class AlterData
---@field tbl {}
local alterData = {
    tbl = {}
}

---@class Alter
---@field data AlterData
local AlterConfig = {
    data = alterData
}

function alterData:print()
    for i, v in ipairs(self.tbl) do
        print(i.. ", " .. v .. "\n")
    end
end

local function project_key()
    return vim.loop.cwd()
end

---@param bufnr string
---@return string
local function get_data(bufnr)
    -- make current buffers absolute path to relative with reference to 
    -- current project directory.
    return Path:new(bufnr):make_relative(project_key())
end

local function save_to_cache() 
    Path:new(cache_config):write(vim.fn.json_encode(AlterConfig.data.tbl), "w")
end

local function set_current_buffer()
    local slot = get_data( vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
    table.insert(AlterConfig.data.tbl, slot)
end

local function set_bufnr()
    local bufnr = vim.fn.bufnr(AlterConfig.data.tbl[1])
    if bufnr ~= nil then
        vim.api.nvim_set_current_buf(bufnr)
    end
end

local function print_buffer()
    AlterConfig.data:print()
end

local function printAllElements(tbl)
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print("Table found at key:", key)
            printAllElements(value)  -- Recursively call function for nested tables
        else
            print(key, value)  -- Print other types of values
        end
    end
end

local function AlterDataLoad()
    alterData.tbl = vim.json.decode(Path:new(cache_config):read())
    printAllElements(alterData.tbl)
end

return {
    data = get_data,
    cur = set_current_buffer,
    print = print_buffer,
    set = set_bufnr,
    cac = save_to_cache,
    pro = AlterDataLoad,
}
