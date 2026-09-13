local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local io = _tl_compat and _tl_compat.io or io; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local uv = require("luv")

local parser = require("parser")

local server = {}
























function server.new(host, port)
   local self = setmetatable({}, { __index = server })

   self:set_host(host)
   self:set_port(port)

   return self
end


function server:set_host(host)
   self.host = host and host or "127.0.0.1"
   return self
end

function server:set_port(port)
   self.port = port and port or 1337
   return self
end


function server:start()
   local tcp_server = uv.new_tcp(nil)

   assert(tcp_server:bind(self.host, self.port, nil))
   tcp_server:listen(128, function()
      local tcp_client = uv.new_tcp(nil)
      tcp_server:accept(tcp_client)
      local message_parser = parser.new()

      tcp_client:read_start(function(err, chunk)
         assert(not err, err)

         if not chunk then
            tcp_client:shutdown(nil)
            tcp_client:close()
            return
         end

         local ok, parse_success, parse_err = pcall(message_parser.feed, message_parser, chunk)

         local connection_header = message_parser:get_header("connection")
         local keep_alive = not (connection_header and connection_header.value:lower() == "close")

         if not ok then
            tcp_client:write("HTTP/1.1 500 Internal server error", nil)
            tcp_client:shutdown(nil)
            tcp_client:close()
            return
         end

         if not parse_success then
            io.write(string.format("Parsing error: %s", parse_err))
            tcp_client:write("HTTP/1.1 400 Bad Request\r\n\r\n", nil)
            tcp_client:shutdown(nil)
            tcp_client:close()
            return
         end

         if message_parser.state ~= "done" then
            return
         end

         tcp_client:write("HTTP/1.1 200 Ok\r\nContent-Length: 0\r\n\r\n", nil)
         if not keep_alive then
            tcp_client:shutdown(nil)
            tcp_client:close()
         end
      end)
   end)

   io.write(string.format("Server listening at %s:%d", self.host, self.port))

   uv.run("default")
end

return server
