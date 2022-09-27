local cmd = vim.api.nvim_create_user_command

cmd("TaskmakerToggle", function()
	require("taskmaker").toggleTask()
end, {})

cmd("TaskmakerAddTasks", function()
	require("taskmaker").addTasks()
end, {})
