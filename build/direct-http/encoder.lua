local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table

local reasons = require("direct-http.reasons")

local encoder = {}









function encoder.new()
   return setmetatable({}, { __index = encoder })
end

function encoder:encode(res)
   local steps = {
      self.encode_start_line,
      self.encode_headers,
      self.encode_body,
   }

   local parts = {}

   for _, step in ipairs(steps) do
      local ok, part = step(self, res)
      if not ok then return false, part end
      table.insert(parts, part)
   end

   return true, table.concat(parts)
end

function encoder:encode_start_line(res)
   local ok, reason = reasons.get_reason(res.code)
   if not ok then return false, "Unknown HTTP status code" end

   return true, string.format("HTTP/%s %d %s\r\n", res.version, res.code, reason)
end

function encoder:encode_headers(res)
   local headers = {}

   for _, h in ipairs(res.headers) do
      table.insert(headers, string.format("%s: %s\r\n", h.key, h.value))
   end

   table.insert(headers, "\r\n")
   return true, table.concat(headers)
end

function encoder:encode_body(res)
   return true, res.body
end

return encoder
