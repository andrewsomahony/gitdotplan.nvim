local M = {}

-- !!! We have to have this as nvim currently uses an older Lua as its internal Lua
table.unpack = table.unpack or unpack

-- Our short repo variable for updating our gitdotplan file
local repo_to_update = nil
-- This variable stores the buffer id corresponding to our current update,
-- if we are in the process of one
-- !!! Should we make this an array
local current_buffer_update_number = nil
-- This variable stores the update type of the current update buffer,
-- which isn't the filename, but the type that we pass into the update script
local current_buffer_update_filename = nil

local name_to_filename_map = {
  ["plan"] = ".plan",
  ["project"] = ".project",
  ["profile"] = ".profile"
}

-- Gets the runtime path of the specified filename
local function get_runtime_path(filename)
  local paths = vim.api.nvim_get_runtime_file(filename, true)
  if #paths > 0 then
    return paths[1]
  else
    error("Cannot locate path for " .. filename)
  end
end

-- Runs a Python script with the given name and parameters
-- The method finds the actual runtime path automatically, and prepends it
-- and the "python" command to the final command table
local function run_gitdotplan_python_script(script_name, parameters, stdin_string)
  -- Get the full path to our Python script
  local runtime_path = get_runtime_path(script_name)

  -- Run our command
  -- !!! Why is there no easy way to concatenate arrays in Lua??
  return vim.system({"python", runtime_path, table.unpack(parameters)}, {text = true, stdin = stdin_string or false}):wait()
end

-- Convert a string separated by newlines to a table, with each line
-- as a table entry
local function convert_string_to_table(result_string)
  local return_value = {}
  -- We want to match all non-newline strings, but include blank lines as
  -- well, as they will be part of the gitdotplan content
  for line in string.gmatch(result_string .. "\n", "(.-)\n") do
    table.insert(return_value, line)
  end
  return return_value
end

-- Utility function to fill a buffer, set its name, and set if it's readonly or not
local function fill_buffer(buffer_number, buffer_name, result_string, is_readonly)
  vim.api.nvim_buf_set_lines(buffer_number, 0, 0, false, convert_string_to_table(result_string))
  -- Set our buffer name
  vim.api.nvim_buf_set_name(buffer_number, buffer_name)
  if is_readonly then
    -- Set our buffer to readonly
    vim.api.nvim_buf_set_option(buffer_number, "readonly", true)
    -- Set our buffer to not be allowed to be modifiable
    vim.api.nvim_buf_set_option(buffer_number, "modifiable", false)
    -- Set our modified boolean to false on the buffer to avoid an
    -- nvim warning when we close the buffer
    vim.api.nvim_buf_set_option(buffer_number, "modified", false)
  else
    -- Set our modified boolean to false on the buffer to avoid an
    -- nvim warning when we close the buffer
    vim.api.nvim_buf_set_option(buffer_number, "modified", false)
  end
  -- Jump to the top of our buffer
  vim.cmd("norm! gg")
end

-- Loads an update into a new buffer.  The "update" function performs the actual update
function M.prepare_update(name)
  if not repo_to_update then
    error("No gitdotplan repo configured.  Please set with the repo_to_update setup parameter")
  else
    if not name_to_filename_map[name] then
      error("No filename for " .. name)
    else
      -- Set our filename
      local filename = name_to_filename_map[name]
      local fetch_result = run_gitdotplan_python_script("finger.py", {"--repo", repo_to_update, "--file", filename})

      -- Open a new buffer in the current window
      vim.api.nvim_cmd({cmd = "enew"}, {output = false})
      -- Set the current buffer to readonly
      current_buffer_update_number = vim.api.nvim_get_current_buf()
      current_buffer_update_filename = filename

      -- Set our buffer's content to our finger result
      -- !!! Make a better title!
      fill_buffer(0, filename, fetch_result.stdout, false)

      vim.api.nvim_buf_set_option(current_buffer_update_number, "buftype", "nofile")
      vim.api.nvim_buf_set_option(current_buffer_update_number, "modifiable", true)
    end
  end
end

-- The update function performs the actual update.  The name 
function M.update()
  if not current_buffer_update_number or not current_buffer_update_filename then
    error("No update buffer present.  Please run prepare_update to make one")
  end
  local current_buffer_id = vim.api.nvim_get_current_buf()
  if current_buffer_id ~= current_buffer_update_number then
    error("Current buffer is not an update buffer")
  else
    -- Our buffer's contents are what we want to pipe into our update script
    local buffer_contents = vim.api.nvim_buf_get_lines(current_buffer_id, 0, -1, false)
    -- Run our update script by piping the buffer contents into the update script
    run_gitdotplan_python_script("update.py", {"--repo", repo_to_update, "--file", current_buffer_update_filename}, buffer_contents)
    -- Mark our buffer as modified
    vim.api.nvim_buf_set_option(current_buffer_id, "modified", false)
  end
end

-- Function to finger a URL
function M.finger(repo_url)
  local finger_result = run_gitdotplan_python_script("finger.py", {"--repo", repo_url})

  -- Open a new buffer in the current window
  vim.api.nvim_cmd({cmd = "enew"}, {output = false})
  -- Set our buffer's content to our finger result
  -- !!! Make a better title!
  fill_buffer(0, repo_url .. ".gitdotplan", finger_result.stdout, true)
end

function M.setup(opts)
  -- Set our short repo if we have it
  if opts.repo_to_update then
    repo_to_update = opts.repo_to_update
  end
end

return M
