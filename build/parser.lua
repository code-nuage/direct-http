local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table










local parser = {}










































































function parser.new()
   local self = setmetatable({}, { __index = parser })

   self:reset()

   return self
end


function parser:set_buffer(buffer)
   self.buffer = buffer
   return self
end

function parser:append_buffer(chunk)
   self.buffer = self.buffer .. chunk
   return self
end

function parser:set_state(state)
   self.state = state
   return self
end

function parser:set_method(method)
   self.method = method
   return self
end

function parser:set_target(target)
   self.target = target
   return self
end

function parser:set_http_version(http_version)
   self.http_version = http_version
   return self
end

function parser:set_headers(headers)
   self.headers = headers
   return self
end

function parser:append_header(header)
   table.insert(self.headers, header)
   return self
end

function parser:set_content_length(content_length)
   self.content_length = content_length
   return self
end

function parser:set_is_chunked(is_chunked)
   self.is_chunked = is_chunked
   return self
end

function parser:set_body_chunks(body_chunks)
   self.body_chunks = body_chunks
   return self
end

function parser:append_body_chunk(body_chunk)
   table.insert(self.body_chunks, body_chunk)
   return self
end

function parser:set_bytes_read(bytes_read)
   self.bytes_read = bytes_read
   return self
end


function parser:get_header(key)
   for _, header in ipairs(self.headers) do
      if header.key == key:lower() then return header end
   end
end


function parser:reset()
   self:
   set_buffer(""):
   set_state("request_line"):
   set_method(nil):
   set_target(nil):
   set_http_version(nil):
   set_headers({}):
   set_content_length(nil):
   set_is_chunked(false):
   set_body_chunks({}):
   set_bytes_read(0)

   return self
end

function parser:feed(chunk)
   self:append_buffer(chunk)

   while true do
      local state = self.state
      if not state then return false, "Parser has no state" end

      if state == "request_line" then
         local line_end = self.buffer:find("\r\n", 1, true)
         if not line_end then return true end

         local line = self.buffer:sub(1, line_end - 1)
         local method, target, version = line:match("^(%u+) (%S+) HTTP/(%d%.%d)$")

         if not method then return false, "Malformed request line: " .. line end

         self:
         set_method(method):
         set_target(target):
         set_http_version(version):
         set_buffer(self.buffer:sub(line_end + 2)):
         set_state("headers")
      elseif state == "headers" then
         local line_end = self.buffer:find("\r\n", 1, true)
         if not line_end then return true end

         local line = self.buffer:sub(1, line_end - 1)
         self:set_buffer(self.buffer:sub(line_end + 2))

         if line == "" then
            local content_length = self:get_header("content-length")
            local transfer_encoding = self:get_header("transfer-encoding")

            if transfer_encoding and transfer_encoding.value:find("chunked") then
               self:
               set_is_chunked(true):
               set_state("chunked_size")
            elseif content_length then
               self:
               set_content_length(tonumber(content_length.value) or 0):
               set_state(self.content_length > 0 and "body" or "done")
            else
               self:set_state("done")
            end
         else
            local key, value = line:match("^([^:]+):%s*(.*)$")
            if not key then return false, "Malformed header: " .. line end
            self:append_header({ key = key:lower(), value = value })
         end
      elseif state == "body" then
         local remaining = self.content_length - self.bytes_read

         if #self.buffer < remaining then
            self:
            append_body_chunk(self.buffer):
            set_bytes_read(self.bytes_read + #self.buffer):
            set_buffer("")
            return true
         else
            self:
            append_body_chunk(self.buffer:sub(1, remaining)):
            set_buffer(self.buffer:sub(remaining + 1)):
            set_bytes_read(self.content_length):
            set_state("done")
         end
      elseif state == "chunked_size" then
         local line_end = self.buffer:find("\r\n", 1, true)
         if not line_end then
            return true
         end

         local size_line = self.buffer:sub(1, line_end - 1)

         local size = tonumber(size_line:match("^(%x+)"), 16)
         if not size then
            return false, "Invalid chunk size"
         end

         self:set_buffer(self.buffer:sub(line_end + 2))

         if size == 0 then
            self:set_state("done")
         else
            self:
            set_content_length(0):
            set_bytes_read(0):
            set_state("chunked_data")
         end
      elseif state == "chunked_data" then
         local remaining = self.content_length - self.bytes_read

         if #self.buffer < remaining + 2 then return true end

         self:
         append_body_chunk(self.buffer:sub(1, remaining)):
         set_buffer(self.buffer:sub(remaining + 2 + 1)):
         set_state("chunked_size")
      elseif state == "done" then
         return true
      end
   end
end

return parser
