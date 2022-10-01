local M = {}

local specialShellChars = '([??$?!?\'?(?)?;?`?*?{?}?<?>?|?&?%?#?~?@?%[?%]?\\?"?]+)'
local function escape(c) return '\\' ..  c end

local function preparePriority(priorities)
	for i = 1, #priorities do
		local priority = string.upper(priorities[i])
		if priority == 'H' or priority == 'M' or priority == 'L' then
			return priority
		end
	end
	return ''
end

local function getMetadataCmd(checklist)
	local projects = ' project:' .. table.concat(checklist.projects, ',')
	local contexts = ''
	if #checklist.contexts ~= 0 then
		contexts = ' +' .. table.concat(checklist.contexts, ' +')
	end
	local priority = ' priority:'
	if checklist.priority then
		priority = priority .. preparePriority(checklist.priority)
	end
	return ' ' .. projects .. contexts .. priority .. ' '
end

function M.addTasks(checklist, defaultContext)
	local feedbackMsg = 'Created:\n'
	local metadataCmd = getMetadataCmd(checklist)
	if defaultContext ~= '' then
		defaultContext = ' +' .. defaultContext
	end

	local tasks = checklist.tasks
	for i = #tasks, 1, -1 do
		local task = tasks[i]
		local description = task.description:gsub(specialShellChars, escape)
		local depends = ' depends:' .. table.concat(task.children, ',')
		vim.fn.system 'task context none'
		vim.fn.system('task add ' .. defaultContext .. metadataCmd .. description .. depends)
		local uuid = vim.fn.system('task +LATEST uuids'):gsub('\n', '')

		local annotation = task.annotation
		if annotation and annotation ~= '' then
			annotation = annotation:gsub(specialShellChars, escape)
			vim.fn.system('task ' .. uuid .. ' annotate ' .. annotation)
		end
		local parentIndex = task.parent
		if parentIndex ~= 0 then
			table.insert(tasks[parentIndex].children, uuid)
		end
		feedbackMsg = feedbackMsg .. task.description .. '\n'
	end
	return feedbackMsg
end

return M
