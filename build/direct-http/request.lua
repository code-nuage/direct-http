local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string

local request = {}









function request.new()
   return setmetatable({
      headers = {},
   }, { __index = request })
end

function request:get_header(key)
   for _, h in ipairs(self.headers) do
      if h.key:lower() == key:lower() then
         return h
      end
   end
end

return request
