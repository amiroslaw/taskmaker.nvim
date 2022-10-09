local M = {}
local function parseTitle(str, prefix)
	local meta = {}
	for token in str:gmatch(prefix .. '(.-)%f[%z%s]') do
		if token ~= '' then
			table.insert(meta, token)
		end
	end
	return meta
end

local function reduceToOne(tab)
	if #tab ~= 0 then
		return tab[1]
	end
	return ''
end

local function getMetadata(line, prefixes)
	local contexts = parseTitle(line, prefixes.context)
	local projects = parseTitle(line, prefixes.project)
	local priority = parseTitle(line, prefixes.priority)
	local wait = parseTitle(line, prefixes.wait)
	local due = parseTitle(line, prefixes.due)
	return contexts, projects, reduceToOne(priority), reduceToOne(due), reduceToOne(wait)
end

local function getHierarchyLevel(line, format, spaces)
	if format == 'adoc' then
		return line:find '%s' - 1
	elseif format == 'md' then
		if line:match '^-' then
			return 1
		elseif line:match '^\t' then
			return line:find '\t%-' + 1
		else
			return line:find '%s%-' / spaces + 1
		end
	end
end

local function getTaskFormat(line)
	if line:match '^*+%s%[%s]' then
		return 'adoc'
	elseif line:match '^\t*%s*%-+%s%[%s]' then
		return 'md'
	end
end

local function parseAnnotation(task, prefix)
	local _, splitDesc = task:find ']%s'
	local description = task:sub(splitDesc + 1, #task)
	local annotation = ''

	local startIndexAnno, endIndexAnno = task:find(prefix)
	if startIndexAnno and endIndexAnno then
		annotation = task:sub(endIndexAnno + 1, #task)
		description = task:sub(1, startIndexAnno - 2)
		return description, annotation
	end
	local urlPattern = '(https?://([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w%w%w?%w?)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))'
	for match in description:gmatch(urlPattern) do
		annotation = annotation .. ' ' .. match
		description = description:gsub(match, '')
	end
	return description, annotation
end

function M.getChecklist(lines, config)
	local OUT = { tasks = {}, contexts = {}, projects = {}, priority = '', due = '', wait = '' }
	local parentHierarchy = 1
	local parentIndex = 0
	local index = 0
	for _, line in ipairs(lines) do
		local taskFormat = getTaskFormat(line)
		if line:match '^%.%a' then
			OUT.contexts, OUT.projects, OUT.priority, OUT.due, OUT.wait = getMetadata(line, config.prefix)
		end
		if taskFormat then
			local hierarchy = getHierarchyLevel(line, taskFormat, config.spaces_number)
			if hierarchy > parentHierarchy then
				parentHierarchy = hierarchy
				parentIndex = index
			elseif hierarchy == 1 then
				parentIndex = 0
				parentHierarchy = 1
			elseif hierarchy < parentHierarchy then
				for i = index, 1, -1 do
					local previousTask = OUT.tasks[i]
					if previousTask.hierarchy == hierarchy then
						parentIndex = previousTask.parent
						parentHierarchy = hierarchy
						break
					end
				end
			end
			local description, annotation = parseAnnotation(line, config.prefix.annotation)
			table.insert(OUT.tasks, {
				parent = parentIndex,
				hierarchy = hierarchy,
				description = description,
				annotation = annotation,
				children = {},
			})
			index = index + 1
		end
	end
	return OUT
end

return M
