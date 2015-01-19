###################################
#        Load dependencies        #
###################################

fs = require 'fs'

###################################
# Initialize and configure casper #
###################################

casper = require('casper').create(
  verbose: true
  logLevel: 'debug'
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

wishList = []

outputFile = casper.cli.get('file')

account =
  user: casper.cli.get('username')
  pass: casper.cli.get('password')

getWishListItems = ->
  wishListItems = []
  $('form[id^="wishList_form"][enctype="application/x-www-form-urlencoded"][accept-charset="UTF-8"][method="post"]')
    .find('div[id^="wishList_row"]')
    .each((index, element) ->
      $element = $(element)
      media =
        tags: $element.find('span.wishList_markText').text().trim()
        match: $element.find('span.rate_matchGrade').text().trim()
        title: $element.find('div.wishList_cell2').find('a.title4').text().trim()
      wishListItems.push media
      console.log "Wish list item processed for #{media.title}."
      return
    )
  return wishListItems

getAllWishListItems = ->
  wishList = wishList.concat casper.evaluate getWishListItems
  nextLink =
    type: 'xpath'
    path: "descendant-or-self::a[contains(concat(' ', normalize-space(@class), ' '), ' fontUnderline ')][text()='Next >>']"
  if casper.visible nextLink
    casper.echo 'NEXT PAGE'
    casper.thenClick nextLink
    casper.then getAllWishListItems
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

casper.thenOpen "http://www.jinni.com/user/#{account.user}/wish-list", ->
  @echo 'Logged in.'
  return

casper.then getAllWishListItems

casper.then ->
  fs.write outputFile, JSON.stringify(wishList, undefined, 2), 'w'
  @echo 'DONE'
  @echo wishList.length + ' wish list items exported.'
  return

casper.run(->
  casper.exit()
)
