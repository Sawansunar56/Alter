local Path = require("plenary.path")
local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")
local user_config = string.format("%s/alter.json", config_path)
local cache_config = string.format("%s/alter.json", data_path)

-- Class declarations sections

---@class AlterData
---@field tbl {}
---@field primary string
local alterData = {
    tbl = {},
    primary = ""
}

---@class Alter
---@field data AlterData
---@field primary string
local alterConfig = {
    data = alterData,
}

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

    return {
        filename = filename,
        row = cursor_pos[1],
        col = cursor_pos[2],
    }
end

---@return string| nil
local function project_key()
    return vim.loop.cwd()
end

---@param bufnr string
---@return string
local function normalize_path(bufnr)
    -- make current buffers absolute path to relative with reference to 
    -- current project directory.
    return Path:new(bufnr):make_relative(project_key())
end

---@return string
local function current_buf_num()
    return normalize_path( vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
end

-- class methods declarations

-- reads cache_config and puts it to alterData.tbl and prints out the values.
function alterConfig:LoadConfig()
    self.data = vim.json.decode(Path:new(cache_config):read())
    printAllElements(self.data)
end

function alterConfig:SaveConfig()
    Path:new(cache_config):write(vim.fn.json_encode(alterConfig.data), "w")
end

-- Sets primary holder to the current buffer
function alterConfig:AddFile()
    local slot = current_buf_num()
    local data = create_mark(slot)
    alterConfig.data.tbl[data.filename] = {
        row = data.row,
        col = data.col,
        connected = ""
    }
    alterConfig.data.primary = slot
end

-- Connects Current buffer with the primary holder
function alterConfig:ConnectFile()
    local slot = current_buf_num()
    if self.data.primary == slot then
        print("Cannot choose the same file")
        return
    end
    alterConfig.data.tbl[self.data.primary]["connected"] = slot
    alterConfig.data.tbl[slot]["connected"] = self.data.primary
    self.data.primary = ""
end

-- Sets primary holder to nothing
function alterConfig:DeleteMark()
    self.data.primary = ""
end

-- Deletes the Connection between the current open file and it's alternative
function alterConfig:DeleteConnection()
    local slot = current_buf_num()
    local alternateFile = self.data.tbl[slot]["connected"]
    self.data.tbl[slot]["connected"] = ""
    self.data.tbl[alternateFile]["connected"] = ""
    print(alternateFile)
end

function alterConfig:Alternate()
    local slot = current_buf_num()
    if self.data.tbl[slot]["connected"] == "" then
        print"No Connection made"
        return 
    end
    local bufnr = vim.fn.bufnr(self.data.tbl[slot]["connected"])

    if bufnr == -1 then
         bufnr = vim.fn.bufnr(self.data.tbl[slot]["connected"], true)
    end

    if not vim.api.nvim_set_current_buf(bufnr) then
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_option_value("buflisted", true, {
            buf = bufnr,
        })
    end
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

    if not vim.api.nvim_set_current_buf(bufnr) then
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_option_value("buflisted", true, {
            buf = bufnr,
        })
    end
end


return {
    set = set_bufnr,
    alterConfig = alterConfig,
}
