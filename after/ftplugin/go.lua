-- $VIMRUNTIME/ftplugin/go.vim sets 'keywordprg' to `:GoKeywordPrg`, which runs
-- `hor term go doc -C <dir> <cword>`: a terminal split at the bottom that also
-- fails on unexported symbols (`go doc` would need -u). That is what K falls
-- back to whenever the buffer has no K mapping of its own.
--
-- Neovim's own LspAttach default (K -> vim.lsp.buf.hover) is not a reliable
-- guard against it: vim.lsp._set_defaults() installs that mapping only when
-- 'keywordprg' looks untouched *and* maparg('K') is empty *and* a hover-capable
-- client actually attaches. Lose any of those (gopls not attached to this
-- buffer, or a stale buffer still carrying kp=:GoKeywordPrg from before this
-- file existed) and K silently shells out to `go doc` again.
--
-- So do both: clear 'keywordprg', and map K buffer-locally -- a buffer-local
-- mapping always wins over 'keywordprg', and it decides what to do at press
-- time rather than at attach time. The rest of the runtime ftplugin
-- (commentstring, comments, Go indent style, ]] ][ [[ [] motions) is worth
-- keeping, so only this one option is overridden.
vim.bo.keywordprg = ""

vim.keymap.set("n", "K", require("user.utils").hover, { buffer = true, desc = "Hover Documentation" })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "") .. " | setl kp< | silent! nunmap <buffer> K"
