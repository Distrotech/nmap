id = "OS from SMB"
description = [[
Attempts to determine the operating system over the SMB protocol (ports 445 and
139).  Although the standard smb arguments can be used (for username/password), and
are respected by this script, they likely won't change the outcome in any meaningful 
way. 

See nselib/smb.lua for more information on this protocol. 
]]

---
--@usage
-- nmap --script smb-os-discovery.nse -p445 127.0.0.1
-- sudo nmap -sU -sS --script smb-os-discovery.nse -p U:137,T:139 127.0.0.1
--
--@output
-- |  OS from SMB: Windows 2000
-- |  LAN Manager: Windows 2000 LAN Manager
-- |  Name: WORKGROUP\TEST1
-- |_ System time: 2008-09-09 20:55:55 UTC-5
-- 
--@args  smbusername The SMB username to log in with. The form DOMAIN\username and username@DOMAIN
--                   are NOT understood. To set a domain, use the smbdomain argument. 
--@args  smbdomain   The domain to log in with. If you aren't in a domained environment, then anything
--                   will (should?) be accepted by the server. 
--@args  smbpassword The password to connect with. Be cautious with this, since some servers will lock
--                   accounts if the incorrect password is given (although it's rare for the 
--                   'administrator' account to be lockoutable, in the off chance that it is, you could
--                   get yourself in trouble). 
--@args  smbhash     A password hash to use when logging in. This is given as a single hex string (32
--                   characters) or a pair of hex strings (2 x 32 characters, optionally separated by a 
--                   single character). These hashes are the Lanman or NTLM hash of the user's password,
--                   and are stored by systems, on the harddrive or memory. They can be retrived from memory
--                   using the fgdump or pwdump tools. 
--@args  smbguest    If this is set to 'true' or '1', a 'guest' login will be attempted if the normal one 
--                   fails. This should be harmless, but I thought I would disable it by default anyway
--                   because I'm not entirely sure of any possible consequences. 
--@args  smbtype     The type of SMB authentication to use. By default, NTLMv1 is used, which is a pretty
--                   decent compromise between security and compatibility. If you are paranoid, you might 
--                   want to use 'v2' or 'lmv2' for this (actually, if you're paranoid, you should be 
--                   avoiding this protocol altogether :P). If you're using an extremely old system, you 
--                   might need to set this to 'v1' or 'lm', which are less secure but more compatible. 
--
--                   If you want finer grained control, these are the possible options:
--                       * v1 -- Sends LMv1 and NTLMv1
--                       * LMv1 -- Sends LMv1 only
--                       * NTLMv1 -- Sends NTLMv1 only (default)
--                       * v2 -- Sends LMv2 and NTLMv2
--                       * LMv2 -- Sends LMv2 only
--
-----------------------------------------------------------------------

author = "Ron Bowes"
license = "Same as Nmap--See http://nmap.org/book/man-legal.html"
categories = {"default", "discovery", "safe"}

require 'smb'
require 'stdnse'

--- Check whether or not this script should be run.
hostrule = function(host)

	local port = smb.get_port(host)

	if(port == nil) then
		return false
	else
		return true
	end

end

--- Converts numbered Windows versions (5.0, 5.1) to the names (Windows 2000, Windows XP). 
--@param os The name of the OS
--@return The actual name of the OS (or the same as the 'os' parameter)
function get_windows_version(os)

	if(os == "Windows 5.0") then
		return "Windows 2000"
	elseif(os == "Windows 5.1")then
		return "Windows XP"
	end

	return os

end

action = function(host)

	local state
	local status, err

	-- Start up SMB
	status, state = smb.start(host)

	if(status == false) then
		if(nmap.debugging() > 0) then
			return "ERROR: " .. state
		else
			return nil
		end
	end

	-- Negotiate protocol
	status, err = smb.negotiate_protocol(state)

	if(status == false) then
		stdnse.print_debug(2, "Negotiate session failed")
		smb.stop(state)
		if(nmap.debugging() > 0) then
			return "ERROR: " .. err
		else
			return nil
		end
	end

	-- Start a session
	status, err = smb.start_session(state, "")
	if(status == false) then
		smb.stop(state)
		if(nmap.debugging() > 0) then
			return "ERROR: " .. err
		else
			return nil
		end
	end

	-- Kill SMB
	smb.stop(state)

	return string.format("%s\nLAN Manager: %s\nName: %s\\%s\nSystem time: %s %s\n", get_windows_version(state['os']), state['lanmanager'], state['domain'], state['server'], state['date'], state['timezone_str'])
end


