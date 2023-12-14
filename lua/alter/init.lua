local Path = require("plenary.path")
-- local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")
-- local user_config = string.format("%s/alter.json", config_path)
local cache_config = string.format("%s/alter.json", data_path)

-- Class declarations sections

---@class AlterData
---@field tbl {}
---@field primary string
local alterData = {
    tbl = {
    },
    primary = ""
}

---@class Alter
---@field data AlterData
---@field primary string
---@field projectKey string
local alterConfig = {
    data = alterData,
    projectKey = ""
}

-- util function sections
-- prints out all given table
local function printAllElements(tbl)
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            print("Table found at key:", key)
            printAllElements(value) -- Recursively call function for nested tables
        else
            print(key, value)       -- Print other types of values
        end
    end
end

---@param filename string
---@return table
local function create_mark(filename)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)

    print(cursor_pos[1], cursor_pos[2])

    return {
        filename = filename,
        row = cursor_pos[1],
        col = cursor_pos[2],
    }
end

---@return string|nil
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
    return normalize_path(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
end

-- class methods declarations

-- reads cache_config and puts it to alterData.tbl and prints out the values.
function alterConfig:LoadConfig()
    local path = Path:new(cache_config)
    local exists = path:exists()
    if not exists then
        self.data = {
            tbl = {
            },
            primary = ""
        }
        self.data.tbl[self.projectKey] = {}
        return
    end
    self.data = vim.json.decode(path:read())
    if self.data.tbl[self.projectKey] == nil then
        self.data.tbl[self.projectKey] = {}
    end
end

function alterConfig:SaveConfig()
    Path:new(cache_config):write(vim.fn.json_encode(alterConfig.data), "w")
end

-- Sets primary holder to the current buffer
function alterConfig:AddFile()
    local slot = current_buf_num()
    if alterConfig.data.tbl[self.projectKey][slot] == nil then
        local data = create_mark(slot)
        alterConfig.data.tbl[self.projectKey][data.filename] = {
            row = data.row,
            col = data.col,
            connected = ""
        }
    end
    alterConfig.data.primary = slot
end

-- Connects Current buffer with the primary holder
function alterConfig:ConnectFile()
    local slot = current_buf_num()
    if self.data.primary == slot then
        print("Cannot choose the same file")
        return
    elseif self.data.primary == "" then
        print("choose a primary holder first")
        return
    end
    if alterConfig.data.tbl[self.projectKey][slot] == nil then
        local data = create_mark(slot)
        alterConfig.data.tbl[self.projectKey][data.filename] = {
            row = data.row,
            col = data.col,
            connected = ""
        }
    end
    self.data.tbl[self.projectKey][self.data.primary]["connected"] = slot
    self.data.tbl[self.projectKey][slot]["connected"] = self.data.primary
    self.data.primary = ""
    self:SaveConfig()
end


-- Clears the entire table
function alterConfig:ClearTbl()
    self.data.tbl = {}
end

-- clear project table
function alterConfig:ClearCurrentProject()
    self.data.tbl[self.projectKey] = {}
end

-- Sets primary holder to nothing
function alterConfig:DeleteMark()
    self.data.primary = ""
end

-- Deletes the Connection between the current open file and it's alternative
function alterConfig:DeleteConnection()
    local slot = current_buf_num()
    local alternateFile = self.data.tbl[self.projectKey][slot]["connected"]
    self.data.tbl[self.projectKey][slot]["connected"] = ""
    self.data.tbl[self.projectKey][alternateFile]["connected"] = ""
end

-- go to alternatte file
function alterConfig:Alternate()
    local slot = current_buf_num()

    if self.data.tbl[self.projectKey][slot] == nil then
        print"file not added to tbl"
        return
    end
    if self.data.tbl[self.projectKey][slot]["connected"] == nil then
        print "slot not found"
        return
    elseif self.data.tbl[self.projectKey][slot]["connected"] == "" then
        print "No file connected yet"
        return
    end

    local bufnr = vim.fn.bufnr(self.data.tbl[self.projectKey][slot]["connected"])
    local position = false

    if bufnr == -1 then
        position = true
        bufnr = vim.fn.bufnr(self.data.tbl[self.projectKey][slot]["connected"], true)
    end

    if not vim.api.nvim_set_current_buf(bufnr) then
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_option_value("buflisted", true, {
            buf = bufnr,
        })
    end

    if position then
        vim.api.nvim_win_set_cursor(0, {self.data.tbl[self.projectKey][slot]["row"], self.data.tbl[self.projectKey][slot]["col"]})
    end
end

function alterConfig:PrintConnection()
    local slot = current_buf_num()
    if self.data.tbl[self.projectKey][slot] == nil then
        print"file  not added to tbl"
        return
    end
    if self.data.tbl[self.projectKey][slot]["connected"] == nil then
        print"No Connection has been made for this file"
        return
    end
    print(self.data.tbl[self.projectKey][slot]["connected"])
end


function alterConfig:CreateWindow()
    local buf = vim.api.nvim_create_buf(false, true)
    local myTable = ""
    for key, value in pairs(self.data.tbl[self.projectKey]) do
        myTable = key .. " connected " .. value["connected"]
        vim.api.nvim_buf_set_lines(buf, -1, -1, true, { myTable })
    end
	local opts = {
		relative = "editor",
		width = 70,
		height = 10,
		col = (vim.go.columns/ 2) + 30,
		row = (vim.go.lines / 2),
		anchor = "SE",
		style = "minimal",
		title = "Alter Pairings",
		border = "rounded",
	}
	local win = vim.api.nvim_open_win(buf, false, opts)
	vim.api.nvim_set_option_value("winhl", "Normal:MyHighlight", { win = win })
    vim.api.nvim_set_current_win(win)
    vim.keymap.set("n", "q",
    function()
        vim.api.nvim_win_close(win, true)
    end, {buffer = buf, silent = true})
end

function alterConfig:PrintAll()
    self:CreateWindow()
end

function alterConfig:setup()
    local key = project_key()
    if key ~= nil then
        self.projectKey = key
    end
    self:LoadConfig()
end

return alterConfig
