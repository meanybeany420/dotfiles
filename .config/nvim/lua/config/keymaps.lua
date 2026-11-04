-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Prevent accidental arrow-key movement while editing, including Shift+arrows.
for _, key in ipairs({ "Up", "Down", "Left", "Right" }) do
  vim.keymap.set({ "n", "i", "v" }, "<" .. key .. ">", "<Nop>")
  vim.keymap.set({ "n", "i", "v" }, "<S-" .. key .. ">", "<Nop>")
end
