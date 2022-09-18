local M = {}

local function getPriority(priority)
	if #priority ~= 0 then
		return '(' .. string.upper(priority[1]) .. ') '
	end
	return ''
end

local function getMetadataCmd(checklist)
	local projects = ''
	if #checklist.projects ~= 0 then
		projects = ' +' .. table.concat(checklist.projects, ' ')
	end
	local contexts = ''
	if #checklist.contexts ~= 0 then
		contexts = ' @' .. table.concat(checklist.contexts, ' ')
	end
	return contexts .. projects
end

function M.addTasks(checklist, defaultContext)
	local feedbackMsg = 'Created:\n'
	local metadataCmd = getMetadataCmd(checklist)
	if defaultContext ~= '' then
		defaultContext = ' @' .. defaultContext
	end

	local tasks = checklist.tasks
	for i = 1, #tasks do
		local task = tasks[i]
		vim.fn.system(
			'todo.sh add "'
				.. getPriority(checklist.priority)
				.. task.description
				.. defaultContext
				.. metadataCmd
				.. '"'
		)
		feedbackMsg = feedbackMsg .. task.description .. '\n'
	end
	return feedbackMsg
end

return M
