local ts = vim.treesitter

M = {}

M.parse_css_string = function(filepath)
	local file = assert(io.open(filepath, "r"))
	local source = file:read("*a")
	file:close()

	local langtree = ts.get_string_parser(source, "css"):parse()
	local root = langtree[1]:root()
	local query = vim.treesitter.query.parse(
		"css",
		[[
    (rule_set 
      (selectors [
          (class_selector
              (tag_name)? @css.tag_name
              (class_name) @css.class_name)
          (_ 
            (class_selector
              (tag_name)? @css.tag_name
              (class_name) @css.class_name))
        ])) @css.rule
    ]]
	)
	local classes = {}
	for pattern, match, metadata in query:iter_matches(root, source, 0, -1) do
		local info = {}
		for id, node in pairs(match) do
			local capture_name = query.captures[id]

			if capture_name == "css.rule" then
				info.rule_set = ts.get_node_text(node, source)
			end

			if capture_name == "css.class_name" then
				local class_name = ts.get_node_text(node, source)
				if not classes[class_name] then
					classes[class_name] = {}
				end
				table.insert(classes[class_name], info)
			end
		end
	end
	return classes
end

---@return string
M.get_lang_at_cursor = function()
	local res, lang = pcall(function()
		local node = ts.get_node()
		if not node then
			return nil
		end
		local range4 = { ts.get_node_range(node) }
		local langtree = ts.get_parser()
		return langtree:language_for_range(range4):lang()
	end)
	if res then
		---@diagnostic disable-next-line: return-type-mismatch
		return lang
	else
		return vim.bo.filetype
	end
end

return M
