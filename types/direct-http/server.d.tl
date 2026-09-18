local type request = require("direct-http.request")
local type response = require("direct-http.response")

local record server
    host: string
    port: integer

    new: function(host: string, port: integer): server

    start: function(self, function(req: request, res: response)): boolean
end

return server
