local type i_header = require("direct-http.i_header")

local record request
    method: string
    target: string
    version: string
    headers: {i_header}
    body: string

    new: function(): request

    get_header: function(self, key: string): i_header
end

return request
