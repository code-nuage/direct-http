local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table














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

function parser:set_path(path)
   self.path = path
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

function parser:append_body_chunks(body_chunk)
   table.insert(self.body_chunks, body_chunk)
   return self
end

function parser:set_bytes_read(bytes_read)
   self.bytes_read = bytes_read
   return self
end


function parser:reset()
   self:
   set_buffer(""):
   set_state("request_line"):
   set_method(nil):
   set_path(nil):
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

   local state = self.state

   while true do
      if not state then return false, "Parser has no state" end

      if state == "request_line" then
         local line_end = self.buffer:find("\r\n", 1, true)
         if not line_end then return true end

         local line = self.buffer:sub(1, line_end - 1)
         local method, path, version = line:match("^(%u+) (%S+) HTTP/(%d%.%d)$")

         if not method then return false, "Malformed request line" end

         self:
         set_method(method):
         set_path(path):
         set_http_version(version):
         set_buffer(self.buffer:sub(line_end + 2)):
         set_state("headers")
      end
   end
end

return parser
