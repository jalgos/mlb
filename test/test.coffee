page = require('webpage').create()

fstatus = (status) ->
  console.log("Status: " + status)
  if status == "success"
    console.log(page.content)
  phantom.exit()

fget_wrap_links = (status) ->
  console.log("Status: " + status)
  if status == "success"
    wraplinks = page.evaluate( ->
      document.querySelectorAll(".wraplink"))
    console.log("Number of games:" + wraplinks.length)
    [].forEach.call(wraplinks, (wraplink) ->
      console.log(wraplink)
      if !wraplink? then return
      console.log(wraplink.nodeType)
      link = wraplink.href
      console.log(link))
  phantom.exit()


page.open("http://mlb.mlb.com/mlb/scoreboard/index.jsp#date=5/1/2015", fget_wrap_links)
