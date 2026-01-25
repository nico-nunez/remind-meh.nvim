-- Minimal init for running tests
local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
if not vim.loop.fs_stat(plenary_path) then
  plenary_path = vim.fn.stdpath("data") .. "/site/pack/vendor/start/plenary.nvim"
end

if vim.loop.fs_stat(plenary_path) then
  vim.opt.runtimepath:append(plenary_path)
end

-- Add the plugin to runtimepath
local plugin_path = vim.fn.fnamemodify(vim.fn.expand("<sfile>:p:h"), ":h")
vim.opt.runtimepath:append(plugin_path)

-- Load plugin
vim.cmd("runtime plugin/remind-meh.lua")
