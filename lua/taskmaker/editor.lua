local M = {}

function M.toggle()
	local currentLineNr = vim.fn.line '.'
	local line = vim.fn.getline(currentLineNr)

	local substitution = line
	if line:match '^*+%s%[%s]' or line:match '^\t*%s*%-+%s%[%s]' then
		substitution = line:gsub('%s%[%s]', ' [X]')
	elseif line:match '^\t*%s*%-+%s%[x]' or line:match '^*+%s%[x?X?]' then
		substitution = line:gsub('%s%[x?X?]', ' [ ]')
	end
	vim.fn.setline(currentLineNr, substitution)
end

return M
