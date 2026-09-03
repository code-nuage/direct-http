local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local string = _tl_compat and _tl_compat.string or string; local uv = require("luv")

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
   local host = self.host
   local port = self.port

   local tcp_server = uv.new_tcp(nil)

   assert(tcp_server:bind(host, port, nil))
   tcp_server:listen(128, function()
      local tcp_client = uv.new_tcp(nil)
      tcp_server:accept(tcp_client)

      tcp_client:read_start(function(err, chunk)
         assert(not err, err)
         if chunk then
            tcp_client:write(chunk, nil)
         else
            tcp_client:shutdown(nil)
            tcp_client:close()
         end
      end)
   end)

   print(string.format("Server listening at %s:%d", host, port))

   uv.run("default")
end

return server
