// This is the first stage of the client loader.
//
// Here we check to see if we are running in a Hyperdrive 10 capable browser (one that
// supports the beaker.hyperdrive API).
//
// If the browser being used is not dat capable, we create a cover page, which
// includes a list of pages this wiki has, and a page flag that can be dragged
// into the lineup of the server based wiki client.

'use strict'

var myVersion = "20.05.19 (client wiki)"
console.log('+++ Client Bootstrap Version: ', myVersion)

// do we have the beaker.hyperdrive API?
if (!(typeof beaker !== 'undefined' && beaker !== null ? beaker.hyperdrive : void 0)) {
  // lets just check we are not in a frame first...
  var inFrame = (window.self !== window.top)

  // some helper from pfrazee's ui kit - https://github.com/pfrazee/pauls-ui-kit
  function $ (el, sel = undefined) {
    if (typeof sel === 'string') {
      return el.querySelector(sel)
    }
    return document.querySelector(el)
  }
  function $$ (el, sel = undefined) {
    if (typeof sel === 'string') {
      return Array.from(el.querySelectorAll(sel))
    }
    return Array.from(document.querySelectorAll(el))
  }
  function render (html) {
    var template = document.createElement('template')
    template.innerHTML = html
    return template.content
  }
  // end of helpers
  // add cover page style
  $('head').append(render(`
    <style type='text/css'>
      body {
        background-image: url("/images/linen2.jpg");
        background-size: repeat;
        font-family: "Helvetica Neue", Verdana, helvetica, Arial, Sans;
        padding: 0px;
        margin: 8px;
        top: 0px;
        left: 0px;
        right: 0px;
        bottom: 60px;
        position: absolute;
        overflow: hidden;
      }
      article {
        width: 490px;
        margin: 0px auto;
        padding: 30px;
        background-color: white;
        opacity: 0.7;
        height: 100%;
        overflow: auto;
        box-shadow: 2px 1px 24px rgba(0,0,0,0.4);
      }
      .favicon {
        position: relative;
        margin-bottom: -6px;
      }
    </style>`))

  // replace page with cover page content
  document.body.append(render(`
    <article id='cover'>
      <header>
        <h1><a href='/view/welcome-visitors'><img src='/favicon.png' class='favicon' height='32p'></a> Welcome Visitors</h1>
      </header>
      <main>
        <p>Welcome to this dat based Federated Wiki site.</p>
        <p>For more information about Federated Wiki a good place to start is <a href="http://fed.wiki.org/view/welcome-visitors/view/about-federated-wiki">About Federated Wiki</a>.</p>
      </main>
    </article>`))

  if (inFrame) {
    $('main').append(render(`
      <p>It looks as if you are seeing Federated Wiki in a browser frame. The Hyperdrive 10 API
      that we rely on is not currently available in this environment, so you are seeing a cover page.</p>
      <p>Press <a href='${window.location.href}' target='_blank'>HERE</a> to open this Federated Wiki in a new tab.</p>`))
  }

  // add list of pages

  fetch('/wiki/system/sitemap.json')
    .then(function(response) {
      return response.json()
    })
    .then(function(sitemap) {
      if (Array.isArray(sitemap)) {
        if (sitemap.length > 0) {
          $('main').append(render(`
          <p>The contents of this Federated Wiki site can be accessed either with: -</p>
          <ul>
            <li>a traditional web browser by dragging the page flag, above, to another Federated Wiki site, or</li>
            <li>by using a browser that has Hyperdrive 10 support, for example <a href='https://beakerbrowser.com'>Beaker Browser</a>, to open this site.</li>
          </ul>
          <p>This wiki contains the following pages:</p>
          <ul id='pages'>
          </ul>`))
          sitemap.forEach(function(page) {
            $('#pages').append(render(`<li>${page.title}</li>`))
          })

        } else {
          $('main').append(render(`
          <p>This Federated Wiki is empty.</p>`))
        }
      } else {
        $('main').append(render(`
          <p>There were problems reading the list of pages for this Federated Wiki.</p>`))
      }
    })
} else {
// we are using a dat capable browser, so lets get the client to load itself.
  async function launchWikiClient () {
    var wikiOrigin = window.location.origin
    var wikiArchive = beaker.hyperdrive.drive(wikiOrigin)
    // read wiki.json
    var data = await wikiArchive.readFile('/wiki.json')
    var wikiConfig = JSON.parse(data)
    // the wiki.json is expected to hold both the key to find the client.
    var rawClientURL = wikiConfig.client.key

    // import the client loader module
    var wikiClientLoaderURL = new URL('/client-loader.js', 'hyper://'+rawClientURL)

    var clientLoader = document.createElement('script')
    clientLoader.src = wikiClientLoaderURL
    clientLoader.type = 'text/javascript'
    document.head.appendChild(clientLoader)
  }

  launchWikiClient()
}
