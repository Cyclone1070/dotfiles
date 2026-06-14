-- Auto-show stats page at startup
mp.add_timeout(0.5, function()
    mp.command("script-binding stats/display-stats-toggle")
end)
