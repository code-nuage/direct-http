local server = require("server")

local app = server.new("127.0.0.1", 1337)

app:start()
