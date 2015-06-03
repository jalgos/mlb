page = require('webpage').create()

fget_plays = (status) ->
  if status != "success" then throw "failed to load page"
  plays = page.evaluate( -> document.querySelectorAll(".play"))

page.open("http://mlb.mlb.com/mlb/gameday/index.jsp?gid=2015_06_02_tormlb_wasmlb_1#game=2015_06_02_tormlb_wasmlb_1,game_state=Wrapup,game_tab=play-by-play", fget_plays)
