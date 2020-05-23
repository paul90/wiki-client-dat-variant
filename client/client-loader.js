// this loads the wiki client
'use strict'

var myVersion = "20.05.19"
console.log('+++ Client Loader Version: ', myVersion)

var clientOrigin = new URL(document.currentScript.src).origin
console.log('+++ loading client from: ', clientOrigin)

async function setupClient () {
  var clientOrigin = undefined
  // are we using a mounted frontend?
  var usingFrontend = new URL(document.currentScript.src).href.includes('.ui')

  if (usingFrontend) {
    clientOrigin = '/.ui'
  } else {
    clientOrigin = new URL(document.currentScript.src).origin
    var wikiOrigin = window.location.origin

    var clientRawKey = await beaker.hyperdrive.getInfo(clientOrigin).then(x => { return x.key })
    var wikiRawKey = await beaker.hyperdrive.getInfo(wikiOrigin).then(x => { return x.key })

/*     console.log("client origin", clientOrigin)
    console.log("wiki origin", wikiOrigin)
    console.log("client Key RAW", clientRawKey)
    console.log("wiki Key RAW", wikiRawKey) */

    if (clientRawKey === wikiRawKey) {
      clientOrigin = ''
    }
  }

  var clientHTML = `
    <!DOCTYPE html>
    <html class='no-js'>
      <head>
        <title>Federated Wiki</title>
        <meta content='text/html; charset=UTF-8' http-equiv='Content-Type'>
        <meta content='width=device-width, height=device-height, initial-scale=1.0, user-scalable=no' name='viewport'>
        <link id='favicon' href='/favicon.png' rel='icon' type='image/png'>

        <link href='${clientOrigin}/style/style.css' rel='stylesheet' type='text/css' media='screen'>
        <link href='/theme/style.css' rel='stylesheet' type='text/css' media='screen'>
        <link href='${clientOrigin}/style/print.css' rel='stylesheet' type='text/css' media='print'>
        <link href='${clientOrigin}/js/jquery-ui/1.11.4/jquery-ui.min.css' rel='stylesheet' type='text/css'>

        <script src='${clientOrigin}/js/jquery-2.2.4.min.js' type='text/javascript'></script>
        <script src='${clientOrigin}/js/jquery-migrate-1.4.1.min.js' type='text/javascript'></script>
        <script src='${clientOrigin}/js/jquery-ui/1.11.4/jquery-ui.min.js' type='text/javascript'></script>
        <script src='${clientOrigin}/js/jquery.ui.touch-punch.min.js' type='text/javascript'></script>
        <script src='${clientOrigin}/js/underscore-min.js' type='text/javascript'></script>

        <script src='${clientOrigin}/client.js' type='text/javascript'></script>
      </head>
      <body>
        <section class='main'>
          <div id="welcome-visitors" class="page active" tabindex="-1"></div>
        </section>
        <footer>
          <div id='site-owner' class='footer-item'>
          </div>

          <div id='security' class='footer-item'></div>

          <span class='searchbox' class='footer-item'>
            &nbsp;
            <input class='search' name='search' type='text' placeholder="Search">
            &nbsp;
            <span class='pages'></span>
          </span>

          <span class='neighborhood'></span>
        </footer>

      <script>
      var isAuthenticated = false;
      var isClaimed = true;
      var isOwner = false;
      var ownerName = '';
      var seedNeighbors = '';
      var user = ''
      wiki.security(user);
      </script>
      </body>
    </html>
  `
  document.open()
  document.write(clientHTML)
  document.close()
}

setupClient()
