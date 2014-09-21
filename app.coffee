###################################
#        Load dependencies        #
###################################

fs = require 'fs'

###################################
# Initialize and configure casper #
###################################

casper = require('casper').create(
  verbose: true
  logLevel: 'warning'
  pageSettings: (
    userAgent: 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.120 Safari/537.36'
  )
  clientScripts: ['node_modules/jquery/dist/jquery.min.js']
  viewportSize: (
    width: 1920
    height: 1080
  )
)
casper.on 'remote.message', (msg) ->
  @echo 'Remote message: ' + msg
  return
casper.on 'page.error', (msg, trace) ->
  @echo 'Page Error: ' + msg, 'ERROR'
  @echo 'Saving Page Error screenshot.', 'ERROR'
  @capture 'pageError.jpg', undefined, (
    format: 'jpg'
    quality: 100
  )
  return
casper.on 'error', (msg, trace) ->
  @echo 'Saving CasperError screenshot.', 'ERROR'
  @capture 'casperError.jpg', undefined, (
    format: 'jpg'
    quality: 100
  )
  return

###################################
#          Set variables          #
###################################

ratingsList = []

outputFile = casper.cli.get('file')

account =
  user: casper.cli.get('username')
  pass: casper.cli.get('password')

getPageRatings = ->
  ratings = []
  $('form[id^="j_id"][enctype="application/x-www-form-urlencoded"][accept-charset="UTF-8"][method="post"]')
    .find('div[id^="ratings_row"]')
    .each((index, element) ->
      $element = $(element)
      mediaPageData = __utils__.sendAJAX($element.find('div.ratings_cell2>a').attr('href'), 'GET', null, false)
      ratingText = $element.find('div.ratings_cell3').find('span.rate_text').text()
      dateSplit = $element.find('div.ratings_cell4>span').text().split('/')
      media =
        title: $element.find('div.ratings_cell2').attr('title')
        rating: switch
          when ratingText is 'Not For Me' then -1
          when ratingText is 'Likely To See' then 0
          when ratingText is 'Awful' then 1
          when ratingText is 'Bad' then 2
          when ratingText is 'Poor' then 3
          when ratingText is 'Disappointing' then 4
          when ratingText is 'So-so' then 5
          when ratingText is 'Okay' then 6
          when ratingText is 'Good' then 7
          when ratingText is 'Great' then 8
          when ratingText is 'Amazing' then 9
          when ratingText is 'Must See' then 10
          else -2
        date: new Date(parseInt('20' + dateSplit[2], 10), Math.max(parseInt(dateSplit[0], 10) - 1, 0), parseInt(dateSplit[1], 10))
        imdbID: $(mediaPageData).find('a.content_mainImdb').attr('href').replace(/^.+\/title\//, '').trim()
      ratings.push media
      console.log "Ratings processed for #{media.title}."
      return
    )
  return ratings

getAllRatings = ->
  ratingsList = ratingsList.concat casper.evaluate getPageRatings
  nextLink = 
    type: 'xpath'
    path: "descendant-or-self::a[contains(concat(' ', normalize-space(@class), ' '), ' fontUnderline ')][text()='Next >>']"
  if casper.visible nextLink
    casper.echo 'NEXT PAGE'
    casper.thenClick nextLink
    casper.then getAllRatings
  else
    casper.echo 'END'
  return

###################################
#         Start exporting         #
###################################

casper.start 'http://www.jinni.com/'

casper.then ->
  @click 'span.pointer[onclick*="login_show"]'
  @fill(
    'form#login_form',
    (
      user: account.user
      pass: account.pass
      rememberme: true
    ),
    true
  )
  return

casper.thenOpen "http://www.jinni.com/user/#{account.user}/ratings", ->
  @echo 'Logged in.'
  @echo @getTitle()
  @echo @getElementInfo('#ratings_titleSum').text + ' ratings to export.'
  return

casper.then getAllRatings

casper.then ->
  fs.write outputFile, JSON.stringify(ratingsList, undefined, 2), 'w'
  @echo 'DONE'
  @echo ratingsList.length + ' ratings exported.'
  return

casper.run(->
  casper.exit()
)
