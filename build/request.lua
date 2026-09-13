local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table

local request = {}






































function request.new()
   return setmetatable({}, { __index = request })
end


function request:set_method(method)
   self.method = method
   return self
end

function request:set_target(target)
   self.target = target
   return self
end

function request:set_version(version)
   self.version = version
   return self
end
function request:set_headers(headers)
   self.headers = headers
   return self
end

function request:add_header(header)
   table.insert(self.headers, header)
   return self
end

function request:set_body(body)
   self.body = body
   return self
end



function request:get_header(key)
   for _, header in ipairs(self.headers) do
      if header.key == key:lower() then return header end
   end
end

return request
