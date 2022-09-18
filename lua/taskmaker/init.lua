local parser = require 'taskmaker.parser'
local selector = require 'taskmaker.selector'
local todo = require 'taskmaker.todo'
local taskwarrior = require 'taskmaker.taskwarrior'

local M = {}
local config = {
	app = 'taskwarrior', -- {'taskwarrior', 'todo.txt'}
	feedback = false, -- confirmation message feedback
	default_context = '',
	sync = false, -- synchronization
	spaces_number = 2,
	prefix = {
		project = '#',
		context = '+',
		priority = '!',
		annotation = 'ann:',
	},
}

function M.setup(customConfig)
	if customConfig and type(customConfig) == 'table' then
		for name, val in pairs(customConfig) do
			if name == 'prefix' then
				for prefixName, prefix in pairs(val) do
					config.prefix[prefixName] = prefix
				end
			else
				config[name] = val
			end
		end
	end
end

function M.addTasks()
	local checklist = parser.getChecklist(selector.getVisualSelection(), config)
	if #checklist.tasks == 0 then
		vim.notify("Couldn't parse any task.", vim.log.levels.WARN)
		return
	end

	local feedbackMsg = ''
	if config.app == 'taskwarrior' and vim.fn.executable 'task' == 1 then
		feedbackMsg = taskwarrior.addTasks(checklist, config.default_context)
		if config.sync then
			vim.fn.system 'task synchronize'
		end
	elseif config.app == 'todo' and vim.fn.executable 'todo.sh' == 1 then
		feedbackMsg = todo.addTasks(checklist, config.default_context)
	end

	if config.feedback then
		vim.notify(feedbackMsg, vim.log.levels.INFO)
	end
end
return M
