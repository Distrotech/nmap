id = "IRC zombie"
description = [[
Checks for an IRC zombie.

If port 113 responds before we ask it then something is fishy. Usually this
means that the host is an IRC zombie.
]]

author = "Diman Todorov <diman.todorov@gmail.com>"

license = "Same as Nmap--See http://nmap.org/book/man-legal.html"

categories = {"malware"}

require "comm"
require "shortport"

portrule = shortport.port_or_service(113, "auth")

action = function(host, port)
	local status, owner = comm.get_banner(host, port, {lines=1})

	if not status then
		return
	end

	return owner
end

