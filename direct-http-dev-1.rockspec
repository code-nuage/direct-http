package = "direct-http"
version = "dev-1"
source = {
   url = "git+https://www.github.com/code-nuage/direct-http",
   -- tag = "dev-1"
}
description = {
   homepage = "https://www.github.com/code-nuage/direct-http",
   license = "MIT"
}
dependencies = {
   "luv >= 1.52.1-0",
}
build = {
   type = "builtin",
   modules = {
      ["direct-http.server"] = "build/server.lua",
   }
}
