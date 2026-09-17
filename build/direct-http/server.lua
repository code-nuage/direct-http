local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local debug = _tl_compat and _tl_compat.debug or debug; local io = _tl_compat and _tl_compat.io or io; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local xpcall = _tl_compat and _tl_compat.xpcall or xpcall; local uv = require("luv")

local request = require("direct-http.request")
local response = require("direct-http.response")
local decoder = require("direct-http.decoder")
local encoder = require("direct-http.encoder")

local server = {}








function server.new(host, port)
   host = host and host or "127.0.0.1"
   port = port and port or 1337

   return setmetatable({
      host = host,
      port = port,
   }, { __index = server })
end

function server:start(callback)
   local tcp_server = uv.new_tcp(nil)
   tcp_server:bind(self.host, self.port, nil)

   local listen_ok, listen_err = tcp_server:listen(128, function()
      local tcp_client = uv.new_tcp(nil)
      local dec = decoder.new()

      local accept_ok, accept_err = tcp_server:accept(tcp_client)
      if not accept_ok then
         print(accept_err)
         tcp_client:shutdown(nil)
         tcp_client:close()
      end

      tcp_client:read_start(function(err, chunk)
         assert(not err, err)
         local req = request.new()
         local res = response.new()
         local enc = encoder.new()

         if not chunk then
            tcp_client:shutdown(nil)
            tcp_client:close()
            return
         end

         local decode_ok, decode_succeeded, decode_err = xpcall(dec.decode, function(traceback_err)
            return debug.traceback(traceback_err)
         end, dec, req, chunk)

         if not decode_ok then
            print("Decode error: ", decode_succeeded)
            tcp_client:write("HTTP/1.1 500 Internal Server Error\r\n\r\n", nil)
            tcp_client:shutdown(nil)
            tcp_client:close()
            return
         end

         if not decode_succeeded then
            print("Decode error: ", decode_err)
            tcp_client:write("HTTP/1.1 400 Bad Request\r\n\r\n", nil)
            tcp_client:shutdown(nil)
            tcp_client:close()
            return
         end

         callback(req, res)
         dec:reset()

         table.insert(res.headers, { key = "Content-Length", value = tostring(#res.body) })

         local encode_ok, encode_succeeded, encode_body = xpcall(enc.encode, function(traceback_err)
            return debug.traceback(traceback_err)
         end, enc, res)

         if not encode_ok or not encode_succeeded then
            tcp_client:write("HTTP/1.1 500 Internal Server Error\r\n\r\n", nil)
            tcp_client:shutdown(nil)
            tcp_client:close()
            return
         end

         tcp_client:write(encode_body, nil)
         local connection = req:get_header("connection")
         if connection and connection.value:find("closed") then
            tcp_client:shutdown(nil)
            tcp_client:close()
         end
         return
      end)
   end)

   if not listen_ok then
      error(listen_err)
   end

   io.stdout:write(string.format("Server listening at %s:%d\n", self.host, self.port))
   io.flush()

   uv.run("default")
end

return server
