*coffeegame* v0.1
=================

A CoffeeScript HTML5 2D game engine.

Setup
-----

*coffeegame* uses [node.js](http://nodejs.org/),
[CoffeeScript](http://coffeescript.org/),
[jQuery](http://jquery.com/),
[RequireJS](http://requirejs.org/),
[Tiled](http://www.mapeditor.org/), and optionally
[Python 2.x](http://python.org/) and
[Docco](http://jashkenas.github.com/docco/).

Python 3 unfortunately does not seem to support Pygments at the moment
so using Docco relies on having a recent version of Python 2.x.

### Windows

Install node.js from the node.js website using the installer. You will
also want to have [git](http://git-scm.com/downloads/) installed.

### Ubuntu

node.js is available with the `nodejs` package. Install it using the
package manager of your choice.

If you want to generate documentation as you develop, you will want to
grab Pygments via the `python-pygments` package, assuming you're
running Python 2.x.

Now check the *Common* section.

### Common

Theoretically this should work for Mac as well once node.js is
installed. I've only tested this on Windows and Ubuntu so far.

Open up your handy console or terminal and
[install CoffeeScript](http://coffeescript.org/#installation):

    npm install -g coffee-script

To set up the engine for optimal deployment, you will want to install
[r.js](http://requirejs.org/docs/optimization.html#download).

    npm install -g requirejs

Now, if you wish to generate documentation as you develop, you may
[install Docco](http://jashkenas.github.com/docco/):

    npm install -g docco

If you wish to only install these node packages locally, you may leave
off the `-g` flags, but this will make using the engine more difficult.

Finally, grab *coffeegame* and put it in a directory somewhere.

Development
-----------

So you're all fired up and ready to go!... but wat do?

You will want a local server for development. If you have Python and no
server, you can simply `cd` into your *coffeegame* directory and run
this one liner:

    python -m SimpleHTTPServer

For Python 3, use:

    python -m http.server

Python will start serving files from that directory to localhost
port:8000.

That shell instance will be all tied up serving files, so let's leave
it alone and open up another terminal. Go to the *coffeegame* directory
and type:

    cake watch

CoffeeScript will start compiling all the `coffee` files you put in the
`src` directory. Snoop around that `src` directory to get a feel for
how the engine works for now (until I or somebody super cool writes a
tutorial or something). Then go crazy and start coding!

To play what you're making, open up
[dev.html](http://localhost:8000/dev.html). Now, simply edit source,
refresh browser, rinse, and repeat until you're done.

Deployment
----------

Open up a terminal instance and type:

    cake build

`cake` will first do a CoffeeScript compile of `src`, and then it will
run `r.js` to optimize `js/main.js` (which is compiled from
`src/main.coffee`). This will be put into an Uglified `game.js` file,
which you can then test using the [index](http://localhost:8000/) page.

Then put on your web server your assets (images, sounds, and sprite and
map JSONs), `index.html`, `game.js`, and `require.js`.

Windows
-------

Unfortunately, `cake` doesn't seem to work well on Windows. Open
`watch.sh` for `cake watch` and `build.sh` for `cake build` instead.
You will need to have git installed so that the scripts open up in
git's `sh` type emulator.

Audio
-----

Currently, audio only works in Chrome and Safari, as these browsers use
WebKit, and WebKit is the only thing that has implemented the Web Audio
API thus far. I am shying away from using a flash/HTML5 audio solution
because they have sketchy browser implementations and are not as cool
as Web Audio.

Thanks
------

With regards to making *coffeegame*, I'd like to shower the following
people with my gratitude:

*   Jeremy Ashkenas for CoffeeScript
*   Jonathan "lonesock" Dummer for a Time-Corrected Verlet
    integration [tutorial](http://lonesock.net/article/verlet.html)
*   Paul Irish, Erik Möller, Jacob Rus, and Tino Zijdel for a
    CoffeeScript `requestAnimationFrame` polyfill
*   Thorbjørn Lindeijer for Tiled
*   Kevin Reid for a monotonic timer implementation reference
*   Boris Smus for a useful [Web Audio tutorial](http://www.html5rocks.com/en/tutorials/webaudio/intro/)
*   metanet for their [collision detection tutorial](http://www.metanetsoftware.com/technique/tutorialA.html)
*   vecna for the [Verge3 engine](http://verge-rpg.com/), from which I
    cut my game development teeth and took many ideas
    +   Along these lines, I'd also like to thank mcgrue and overkill
        for being inspirational and stuff
*   The mass of people I have missed because they have helped out
    like invisible ninjas in the production of this thingy

I'd like to thank everyone who has ever taught me stuff, jammed with
me, or just plain hung out with me. Your time is precious to me.

Last but not least, I'd like to thank my mom.

**Thank you.**

