local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local io = _tl_compat and _tl_compat.io or io; local string = _tl_compat and _tl_compat.string or string


local server = require("direct-http.server")

server.new("127.0.0.1", 1337):
start(function(req, res)
   io.write(string.format("%s HTTP/%s %s\n%s\n", req.method, req.version, req.target, req.body or "No body"))
   io.flush()
   res.body = [[{"test": "test"}]]
   res:add_header("Content-Type", "application/json")
end)
