-- This file is just for calling definitions in colorscheme.lua, required to make a colorscheme called minirandom with custom color generator
if _G.load_initial_random_hues then
	_G.load_initial_random_hues()
else
	print("Error, function _G.load_random_hues from lua/kickstart/plugins/colorscheme.lua not found")
end
