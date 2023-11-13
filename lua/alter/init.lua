local Path = require("plenary.path")
local config_path = vim.fn.stdpath("config")
local data_path = vim.fn.stdpath("data")
local user_config =  string.format("%s/alter.json", config_path)
local cache_config =  string.format("%s/alter.json", data_path)

local M = {}

function M.project_key()
    return vim.loop.cwd()
end

local function make_relative_path(item)
    print(Path:new(item):make_relative(M.project_key()))
end


local function get_buf_name(id)
    if id == nil then
        return make_relative_path(vim.api.nvim_buf_get_name(0))
    end
    return ""
end

function M.add_file(file_name_or_id)
    local buf_name = get_buf_name(file_name_or_id)
end

local greet = function()
    print(Path.new("hallowen"):_fs_filename())
    print("Helo from greeting")
end

local function validate_buf_name(buf_name)
    if buf_name == "" or buf_name == nil then
        error("Couldn't find a valid file name to mark, sorry.")
        return
    end
end

local function create_mark(filename)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)

    print(cursor_pos[1], cursor_pos[2])

    return {
        filename = filename,
        row = cursor_pos[1],
        col = cursor_pos[2],
    }
end

return {
    greet = greet,
    path = make_relative_path,
    mark = create_mark
}
