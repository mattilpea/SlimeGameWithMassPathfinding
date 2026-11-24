local Debugger = {}

local doPrint = true

function Debugger.Print(msg : string)
	if not doPrint then return end
	print(msg)
	doPrint = false
	task.wait(2)
	doPrint = true
end

return Debugger
