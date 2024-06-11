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
    inplace = {
        cpp = { "h", "hpp" },
        h   = { "c", "cpp" },
        c   = { "h" },
        hpp = { "cpp" }
    },
    projectKey = ""
}

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

---@return table
local function create_mark()
    local cursor_pos = vim.api.nvim_win_get_cursor(0)

    print(cursor_pos[1], cursor_pos[2])

    return {
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
    Path:new(cache_config):write(vim.json.encode(alterConfig.data), "w")
end

-- Sets primary holder to the current buffer
function alterConfig:AddFile()
    local slot = current_buf_num()
    local current_project_tbl = self.data.tbl[self.projectKey]
    local mark = create_mark()

    if current_project_tbl[slot] == nil then
        current_project_tbl[slot] = {}
    end
    current_project_tbl[slot].connected = ""
    current_project_tbl[slot].row = mark.row
    current_project_tbl[slot].col = mark.col
    self.data.primary = slot
end

-- Connects Current buffer with the primary holder
function alterConfig:ConnectFile()
    local slot = current_buf_num()
    local primary = self.data.primary
    local current_project_tbl = self.data.tbl[self.projectKey]
    local mark = create_mark()

    if primary == slot then
        print("Cannot choose the same file")
        return
    elseif primary == "" then
        print("choose a primary holder first")
        return
    end

    if current_project_tbl[slot] == nil then
        current_project_tbl[slot] = {}
    end
    current_project_tbl[slot].connected = ""
    current_project_tbl[slot].row = mark.row
    current_project_tbl[slot].col = mark.col

    current_project_tbl[primary]["connected"] = slot
    current_project_tbl[slot]["connected"] = primary
    self.data.primary = ""

    self:SaveConfig()
end

-- Clears the entire table
function alterConfig:ClearTable()
    self.data.tbl = {}
end

-- clear project table
function alterConfig:ClearCurrentProject()
    self.data.tbl[self.projectKey] = {}
end

function alterConfig:ClearCurrentFile()
    local slot = current_buf_num()
    local current_project_tbl = self.data.tbl[self.projectKey]
    if current_project_tbl[slot]["connected"] ~= "" then
        local alternate = current_project_tbl[slot]["connected"]
        current_project_tbl[alternate]["connected"] = ""
    end
    self.data.tbl[self.projectKey][slot] = nil
end

-- Sets primary holder to nothing
function alterConfig:DeleteMark()
    self.data.primary = ""
end

-- Deletes the Connection between the current open file and it's alternative
function alterConfig:DeleteConnection()
    local slot = current_buf_num()
    local current_project_tbl = self.data.tbl[self.projectKey]

    if current_project_tbl[slot] == nil then
        print "File not indexed"
        return
    end
    local alternateFile = current_project_tbl[slot]["connected"]
    if alternateFile == "" then
        print "no Connection found"
        return
    end
    current_project_tbl[slot]["connected"] = ""
    current_project_tbl[alternateFile]["connected"] = ""
end

-- Returns 0 if file and connection is found
-- else returns -1
local function conditionChecking(current_project_tbl, slot)
    if current_project_tbl[slot] == nil then
        print "file not added to tbl"
        return -1
    end
    if current_project_tbl[slot]["connected"] == nil then
        print "slot not found"
        return -1
    elseif current_project_tbl[slot]["connected"] == "" then
        print "No file connected yet"
        return -1
    end
    return 0
end

-- go to alternatte file
function alterConfig:Alternate()
    local slot = current_buf_num()
    local current_project_tbl = self.data.tbl[self.projectKey]

    local foundFile = conditionChecking(current_project_tbl, slot)

    if foundFile ~= 0 then
        return
    end

    local bufnr = vim.fn.bufnr(current_project_tbl[slot]["connected"])
    local position = false

    if bufnr == -1 then
        position = true
        bufnr = vim.fn.bufnr(current_project_tbl[slot]["connected"], true)
    end

    if not vim.api.nvim_set_current_buf(bufnr) then
        vim.fn.bufload(bufnr)
        vim.api.nvim_set_option_value("buflisted", true, {
            buf = bufnr,
        })
    end

    if position then
        vim.api.nvim_win_set_cursor(0, { current_project_tbl[slot]["row"], current_project_tbl[slot]["col"] })
    end
end

local function file_exists(filepath)
    local stat = vim.loop.fs_stat(filepath)
    return stat ~= nil
end

function alterConfig:InPlace()
    local slot = current_buf_num()
    local pattern = [[%.]]

    local splitSlot = vim.split(slot, pattern)
    local lastIndex = #splitSlot
    local targetTbl = self.inplace[splitSlot[lastIndex]]

    local bufnr
    for _, element in ipairs(targetTbl) do
        local target = splitSlot[1] .. "." .. element
        local fileExists = file_exists(target)
        if fileExists then
            bufnr = vim.fn.bufnr(target)

            if bufnr == -1 then
                bufnr = vim.fn.bufnr(target, true)
                vim.api.nvim_set_option_value("buflisted", true, {
                    buf = bufnr,
                })
            end
            vim.api.nvim_set_current_buf(bufnr)
            break
        end
    end

    if bufnr == nil then
        print("no in place file")
    end
end

function alterConfig:Split(isSplit)
    local slot = current_buf_num()
    local current_project_tbl = self.data.tbl[self.projectKey]

    local foundFile = conditionChecking(current_project_tbl, slot)

    if foundFile ~= 0 then
        return
    end

    if isSplit then
        vim.cmd('split')
    else
        vim.cmd('vsplit')
    end
    local win = vim.api.nvim_get_current_win()
    local bufnr = vim.fn.bufnr(current_project_tbl[slot]["connected"])

    if bufnr == -1 then
        bufnr = vim.fn.bufnr(current_project_tbl[slot]["connected"], true)
    end
    vim.api.nvim_win_set_buf(win, bufnr)
end

function alterConfig:PrintConnection()
    local slot = current_buf_num()
    local current_project_tbl = self.data.tbl[self.projectKey]
    if current_project_tbl[slot] == nil then
        print "file  not added to tbl"
        return
    end
    if current_project_tbl[slot]["connected"] == nil then
        print "No Connection has been made for this file"
        return
    end
    print(current_project_tbl[slot]["connected"])
end

function alterConfig:CreateWindow()
    local buf = vim.api.nvim_create_buf(false, true)
    local current_project_tbl = self.data.tbl[self.projectKey]
    local myTable = ""
    local count = 1
    for key, value in pairs(current_project_tbl) do
        myTable = count .. ". " .. key .. "  <-connected->  " .. value["connected"]
        vim.api.nvim_buf_set_lines(buf, -1, -1, true, { myTable })
        count = count + 1
    end
    local ui = vim.api.nvim_list_uis()[1]
    local col = 12
    if ui ~= nil then
        col = math.max(ui.width / 2 + 40, 0)
    end
    local opts = {
        relative = "editor",
        width = 80,
        height = 10,
        col = col,
        row = (vim.go.lines / 2),
        anchor = "SE",
        style = "minimal",
        title = "Alter Pairings",
        title_pos = "center",
        border = "rounded",
    }
    local win = vim.api.nvim_open_win(buf, false, opts)
    vim.api.nvim_set_option_value("winhl", "Normal:MyHighlight", { win = win })
    vim.api.nvim_set_current_win(win)
    vim.keymap.set("n", "q",
        function()
            vim.api.nvim_win_close(win, true)
        end, { buffer = buf, silent = true })
    vim.keymap.set("n", "ss",
        function()
            self:SaveConfig()
            print("Saved")
        end, { buffer = buf, silent = true })
end

function alterConfig:PrintAll()
    self:CreateWindow()
end

function alterConfig:setup(config)
    local key = project_key()
    self.inplace = config.InPlace
    if key ~= nil then
        self.projectKey = key
    end
    self:LoadConfig()
end

return alterConfig
