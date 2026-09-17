local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table



local decoder = {}



















function decoder.new()
   local i = setmetatable({}, { __index = decoder })

   i:reset()

   return i
end

function decoder:reset()
   self.state = "start_line"
   self.buffer = ""
   self.bytes_read = 0
   self.body_chunks = {}
   self.content_length = 0
   self.is_chunked = false
end

function decoder:decode(req, chunk)
   self.buffer = self.buffer .. chunk

   while true do
      if not self.state then return false, "Parser has not state" end

      if self.state == "start_line" then
         return self:decode_start_line(req)
      elseif self.state == "headers" then
         return self:decode_headers(req)
      elseif self.state == "body" then
         return self:decode_body()
      elseif self.state == "chunked_size" then
         return self:decode_chunked_size()
      elseif self.state == "chunked_data" then
         return self:decode_chunked_data()
      elseif self.state == "done" then
         req.body = table.concat(self.body_chunks)
         return true
      end
   end
end

function decoder:decode_start_line(req)
   local line_end = self.buffer:find("\r\n", 1, true)
   if not line_end then return true end

   local line = self.buffer:sub(1, line_end - 1)
   local method, target, version = line:match("^(%u+) (%S+) HTTP/(%d%.%d)$")

   if not method then return false, "Malformed request line:" .. line end

   req.method = method
   req.target = target
   req.version = version

   self.buffer = self.buffer:sub(line_end + 2)
   self.state = "headers"
   return true
end

function decoder:decode_headers(req)
   local line_end = self.buffer:find("\r\n", 1, true)
   if not line_end then return true end

   local line = self.buffer:sub(1, line_end - 1)
   self.buffer = self.buffer:sub(line_end + 2)

   if line == "" then
      local transfer_encoding = req:get_header("transfer-encoding")
      local content_length = req:get_header("content-length")

      if transfer_encoding and transfer_encoding.value:find("chunked") then
         self.is_chunked = true
         self.state = "chunked_size"
      elseif content_length then
         self.content_length = tonumber(content_length.value) or 0
         self.state = self.content_length > 0 and "body" or "done"
      else
         self.state = "done"
      end
   else
      local key, value = line:match("^([^:]+):%s*(.*)$")
      if not key then return false, "Malformed header: " .. line end
      table.insert(req.headers, { key = key:lower(), value = value:lower() })
   end
   return true
end

function decoder:decode_body()
   local remaining = self.content_length - self.bytes_read

   if #self.buffer < remaining then
      table.insert(self.body_chunks, self.buffer)
      self.bytes_read = self.bytes_read + #self.buffer
      self.buffer = ""
      return true
   else
      table.insert(self.body_chunks, self.buffer:sub(1, remaining))
      self.buffer = self.buffer:sub(remaining + 1)
      self.bytes_read = self.content_length
      self.state = "done"
   end
   return true
end

function decoder:decode_chunked_size()
   local line_end = self.buffer:find("\r\n", 1, true)
   if not line_end then return true end


   local size_line = self.buffer:sub(1, line_end - 1)

   local size = tonumber(size_line:match("^(%x+)"), 16)
   if not size then return false, "Invalid chunk size" end

   self.buffer = self.buffer:sub(line_end + 2)

   if size == 0 then
      self.state = "done"
   else
      self.content_length = 0
      self.bytes_read = 0
      self.state = "chunked_data"
   end
   return true
end

function decoder:decode_chunked_data()
   local remaining = self.content_length - self.bytes_read

   if #self.buffer < remaining + 2 then return true end

   table.insert(self.body_chunks, self.buffer:sub(1, remaining))
   self.state = "chunked_size"
   return true
end

return decoder
