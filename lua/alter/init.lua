local Path = require("plenary.path")
local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")
local user_config = string.format("%s/alter.json", config_path)
local cache_config = string.format("%s/alter.json", data_path)

-- util function sections
-- prints out all given table
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

---@param filename string
local function create_mark(filename)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)

    print(cursor_pos[1], cursor_pos[2])

    local data = {}
    data[filename] = {
        row = cursor_pos[1],
        col = cursor_pos[2],
    }

    return data
end

---@return string| nil
local function project_key()
    return vim.loop.cwd()
end

-- Class declarations sections

---@class AlterData
---@field tbl {}
---@field connections {}
local alterData = {
    tbl = {},
    connections = {}
}

---@class Alter
---@field data AlterData
local alterConfig = {
    data = alterData
}

-- class methods declarations

-- reads cache_config and puts it to alterData.tbl and prints out the values.
function alterConfig:Load()
    self.data = vim.json.decode(Path:new(cache_config):read())
    printAllElements(self.data)
end

local function connection_maker()
   alterConfig.data.connections["1"] = 2
   alterConfig.data.connections["2"] = 1
end


---@param bufnr string
---@return string
local function normalize_path(bufnr)
    -- make current buffers absolute path to relative with reference to 
    -- current project directory.
    return Path:new(bufnr):make_relative(project_key())
end

local function save_to_cache()
    Path:new(cache_config):write(vim.fn.json_encode(alterConfig.data), "w")
end

local function set_current_buffer()
    local slot = normalize_path( vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
    local data = create_mark(slot)
    table.insert(alterConfig.data.tbl, data)
end

local function current_buf_num() 
    local slot = normalize_path( vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
end

---@param num integer
local function set_bufnr(num)
    local store = tostring(num)
    num = alterConfig.data.connections[store]
    if num > #alterConfig.data.tbl then
        print"No filename at that range"
        return
    end
    local bufnr = vim.fn.bufnr(alterConfig.data.tbl[num]["filename"])
    if bufnr == -1 then
         bufnr = vim.fn.bufnr(alterConfig.data.tbl[num]["filename"], true)
    end

    -- have to make it work
    -- vim.api.nvim_command('buffer ' .. bufnr)
    -- vim.api.nvim_buf_is_loaded(bufnr)

    if not vim.api.nvim_set_current_buf(bufnr) then
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_option_value("buflisted", true, {
            buf = bufnr,
        })
    end
end




return {
    cur = set_current_buffer,
    set = set_bufnr,
    cac = save_to_cache,
    alterData = alterData,
    alterConfig = alterConfig,
    connection = connection_maker,
}
