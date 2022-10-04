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

function M.getChecklist(lines, config)
	local OUT = { tasks = {}, contexts = {}, projects = {} }
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
			local _, splitDesc = line:find ']%s'
			local description = line:sub(splitDesc + 1, #line)
			local startIndexAnno, endIndexAnno = description:find(config.prefix.annotation)
			local annotation = ''
			if startIndexAnno and endIndexAnno then
				annotation = description:sub(endIndexAnno + 1, #description)
				description = description:sub(1, startIndexAnno - 2)
			end
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
