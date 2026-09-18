local type i_header = require("direct-http.i_header")

local record response
    version: string
    code: integer
    headers: {i_header}
    body: string

    new: function(): response

    add_header: function(self, key: string, value: string): response
end

return response
