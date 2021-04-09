function init()
	message.setHandler("pat_ruler_aimPosition", function(_, isLocal)
		if not isLocal then return end
		return tech.aimPosition()
	end)
	--message.setHandler("pat_ruler_args", function(_, isLocal)
	--	if not isLocal then return end
	--	return self.args
	--end)
end

--function update(args)
--	self.args = args.moves
--end