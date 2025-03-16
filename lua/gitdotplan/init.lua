local M = {}

-- Our short repo variable for updating our gitdotplan file
local short_repo = nil

-- Gets the runtime path of our filename
local function get_runtime_path(filename)
  local paths = vim.api.nvim_get_runtime_file(filename, true)
  if #paths > 0 then
    return paths[1]
  else
    error("Cannot locate path for " .. filename)
  end
end

-- Process our gitdotplan result to convert the string into a table, separated
-- by newlines
local function process_gitdotplan_result(result_string)
  local return_value = {}
  -- We want to match all non-newline strings, but include blank lines as
  -- well, as they will be part of the gitdotplan content
  for line in string.gmatch(result_string .. "\n", "(.-)\n") do
    table.insert(return_value, line)
  end
  return return_value
end

-- Function to finger a URL
function M.finger()
    -- !!! The short repo is for updating, but we are using it for fingering, temporarily
    -- !!! Maybe we can build some sort of tab completion in with a pre-specified list in the opts?
    if short_repo then
      -- Get the full path to our finger.py script, so we can run it with python
      local finger_path = get_runtime_path("finger.py")
      -- Run our finger command using our external Python script
      -- !!! We need to process the return code here to make sure the command succeeded
      local command_result = vim.fn.system {"python", finger_path, "--short-repo", short_repo}
      -- Set our buffer's content to our finger result
      vim.api.nvim_buf_set_lines(0, 0, 0, false, process_gitdotplan_result(command_result))
      -- Set our buffer name
      vim.api.nvim_buf_set_name(0, ".gitdotplan")
      -- Set our buffer to readonly
      vim.api.nvim_buf_set_option(0, "readonly", true)
      -- Set our buffer to not be allowed to be modifiable
      vim.api.nvim_buf_set_option(0, "modifiable", false)
      -- Set our modified boolean to false on the buffer to avoid an
      -- nvim warning when we close the buffer
      vim.api.nvim_buf_set_option(0, "modified", false)
      -- Jump to the top of our buffer
      vim.cmd("norm! gg")
    else
      -- Throw an error if we have no short_repo supplied
      error("No repo supplied, please set with the opts.short_repo variable")
    end
end

function M.setup(opts)
  -- Set our short repo if we have it
  if opts.short_repo then
    short_repo = opts.short_repo
  end
end

return M
