print("Hello so")
local function make_relative_path(item)
    print(Path:new(item):make_relative(M.project_key()))
end


local function get_buf_name(id)
    if id == nil then
        return make_relative_path(vim.api.nvim_buf_get_name(0))
    end
    return ""
end

local function validate_buf_name(buf_name)
    if buf_name == "" or buf_name == nil then
        error("_validate_buf_name(): Couldn't find a valid filename to mark")
        return
    end
end

local function get_first_empty_slot()
    for idx = 1, M.get_length() do
        local filename = M.get_marked_file_name(idx)
        if filename == "" then
            return idx
        end
    end

    return M.get_length() + 1
end

function M.add_file(file_name_or_id)
    local buf_name = get_buf_name(file_name_or_id)
end

function M.get_marked_file_name(idx, marks)
    local mark 
    if marks ~= nil then
        mark = marks[idx]
    else 
    end

    return mark and mark.filename
end

function M.get_length(marks)
    if marks == nil then
    end
    return table.maxn(marks)
end


-- function M.refresh_projects_before_update()
--     local cwd = M.project_key()
--     local current_p_config =  {
--         projects = {
--             [cwd]
--         }
--     }
-- end
--
-- function M.ensure_correct_config(config)
--     local projects = config.projects
--     local mark_key = M.project_key()
--     if projects[mark_key] == nil then
--         projects[mark_key] = {
--             mark = { marks = {} },
--         }
--     end
--
--     return projects
-- end

local function merge_table_impl(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k]) == "table" then
                merge_table_impl(t1[k], v)
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
end

local function merge_tables(...)
    local out = {}
    for i = 1, select("#", ...) do
        merge_table_impl(out, select(i, ...))
    end
    return out
end


function M.save()
    M.refresh_projects_before_update()

    Path:new(cache_config):write(vim.fn.json_encode(AlterConfig), "w")
end

local function project_key ()
    return vim.loop.cwd()
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

local function read_config(local_config)
    return vim.json.decode(Path:new(local_config):read())
end

local function save_file_into_config(filename)
    local object = create_mark(filename)
    Path:new(cache_config):write(vim.fn.json_encode(object), 'w')
end

local function get_or_create_buffer(filename)
    local buf_exists = vim.fn.bufexists(filename) ~= 0
    if buf_exists then
        return vim.fn.bufnr(filename)
    end

    return vim.fn.bufadd(filename)
end

local function setup(config)
    if not config then
        config = {}
    end

    -- config = {
    --     marks = {
    --        "/home/sawan/projects/luaPlugin/alter/lua/alter/init.lua",
    --        "/home/sawan/projects/luaPlugin/alter/lua/alter/utils.lua",
    --     }
    -- }
    local ok, c_config = pcall(read_config, cache_config)
    if not ok then
        c_config = {}
    end
    

    AlterConfig = config
end

local function nav_file(id)
    local filename = AlterConfig.marks[id]
    local buf_id = get_or_create_buffer(filename)

    if buf_id ~= nil then
        vim.api.nvim_set_current_buf(buf_id)
    end
end

return {
    greet = greet,
    path = make_relative_path,
    mark = create_mark,
    save = save_file_into_config,
    setup = setup,
    nav_file = nav_file
}
