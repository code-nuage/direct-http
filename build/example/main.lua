


local server = require("direct-http.server")

server.new("127.0.0.1", 1337):
start(function(_req, res)
   res.body = [[{"test": "test"}]]
   res:add_header("Content-Type", "application/json")
end)
