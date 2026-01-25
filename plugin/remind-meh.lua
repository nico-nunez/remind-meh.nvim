if vim.g.loaded_remind_meh then
  return
end
vim.g.loaded_remind_meh = true

vim.api.nvim_create_user_command("RemindMeh", function()
  require("remind-meh").open()
end, { desc = "Open reminder list" })

vim.api.nvim_create_user_command("RemindMehToggle", function()
  require("remind-meh").toggle()
end, { desc = "Toggle reminder list" })

vim.api.nvim_create_user_command("RemindMehRefresh", function()
  require("remind-meh").refresh()
end, { desc = "Refresh reminder list" })

vim.api.nvim_create_user_command("RemindMehClose", function()
  require("remind-meh").close()
end, { desc = "Close reminder list" })

vim.api.nvim_create_user_command("RemindMehInsert", function()
  require("remind-meh").insert_todo()
end, { desc = "Insert TODO at cursor" })

vim.api.nvim_create_user_command("RemindMehInput", function()
  require("remind-meh").input_todo()
end, { desc = "Open TODO input window" })

vim.api.nvim_create_user_command("RemindMehNext", function()
  require("remind-meh").next_todo()
end, { desc = "Jump to next TODO in buffer" })

vim.api.nvim_create_user_command("RemindMehPrev", function()
  require("remind-meh").prev_todo()
end, { desc = "Jump to previous TODO in buffer" })

local group = vim.api.nvim_create_augroup("RemindMehPlugin", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    vim.defer_fn(function()
      local remind_meh = require("remind-meh")
      if remind_meh._initialized then
        remind_meh.auto_open()
      end
    end, 100)
  end,
  desc = "Auto-open reminders on startup",
})
