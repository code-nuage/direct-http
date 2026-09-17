local type request = require("direct-http.request")
local type response = require("direct-http.response")

local server = require("direct-http.server")

server.new("127.0.0.1", 1337)
    :start(function(req: request, res: response)
        io.write(string.format("%s HTTP/%s %s\n%s\n", req.method, req.version, req.target, req.body or "No body"))
        io.flush()
        res.body = [[{"test": "test"}]]
        res:add_header("Content-Type", "application/json")
    end)
