if vim.g.loaded_todos then
  return
end
vim.g.loaded_todos = true

vim.api.nvim_create_user_command("Todos", function()
  require("todos").open()
end, { desc = "Open TODO list" })

vim.api.nvim_create_user_command("TodosToggle", function()
  require("todos").toggle()
end, { desc = "Toggle TODO list" })

vim.api.nvim_create_user_command("TodosRefresh", function()
  require("todos").refresh()
end, { desc = "Refresh TODO list" })

vim.api.nvim_create_user_command("TodosClose", function()
  require("todos").close()
end, { desc = "Close TODO list" })

vim.api.nvim_create_user_command("TodosInsert", function()
  require("todos").insert_todo()
end, { desc = "Insert TODO at cursor" })

vim.api.nvim_create_user_command("TodosInput", function()
  require("todos").input_todo()
end, { desc = "Open TODO input window" })

vim.api.nvim_create_user_command("TodosNext", function()
  require("todos").next_todo()
end, { desc = "Jump to next TODO in buffer" })

vim.api.nvim_create_user_command("TodosPrev", function()
  require("todos").prev_todo()
end, { desc = "Jump to previous TODO in buffer" })

local group = vim.api.nvim_create_augroup("TodosPlugin", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    vim.defer_fn(function()
      local todos = require("todos")
      if todos._initialized then
        todos.auto_open()
      end
    end, 100)
  end,
  desc = "Auto-open TODOs on startup",
})
