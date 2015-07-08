page = require('webpage').create()

fget_plays = (status) ->
  if status != "success" then throw "failed to load page"
  console.log("Parsing page")
  innings = page.evaluate( ->
    document.querySelector(".inning_nav"))
  console.log(innings)
  console.log("Number of innings" + innings.children.length)
page.open("http://mlb.mlb.com/mlb/gameday/index.jsp?gid=2015_06_02_tormlb_wasmlb_1#game=2015_06_02_tormlb_wasmlb_1,game_state=Wrapup,game_tab=play-by-play", (status) => fget_plays(status))
