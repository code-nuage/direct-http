local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local table = _tl_compat and _tl_compat.table or table

local response = {}










function response.new()
   return setmetatable({
      version = "1.1",
      code = 200,
      headers = {},
      body = "",
   }, { __index = response })
end

function response:add_header(key, value)
   table.insert(self.headers, { key = key, value = value })
   return self
end

return response
