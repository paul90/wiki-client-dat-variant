module.exports = function (grunt) {
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-mocha-test');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-uglify-es');
  grunt.loadNpmTasks('grunt-git-authors');
  grunt.loadNpmTasks('grunt-retire');

  // N.B. The development build includes paths in the mapfile, at the browserify step, that are not accessable
  //      from the browser.



  grunt.initConfig({

    pkg: grunt.file.readJSON('package.json'),

    authors: {
      prior: [
        "Ward Cunningham <ward@c2.com>",
        "Stephen Judkins <stephen.judkins@gmail.com>",
        "Sam Goldstein <sam@aboutus.org>",
        "Steven Black <steveb@stevenblack.com>",
        "Don Park <don@donpark.org>",
        "Sven Dowideit <SvenDowideit@fosiki.com>",
        "Adam Solove <asolove@gmail.com>",
        "Nick Niemeir <nick.niemeir@gmail.com>",
        "Erkan Yilmaz <erkan77@gmail.com>",
        "Matt Niemeir <matt.niemeir@gmail.com>",
        "Daan van Berkel <daan.v.berkel.1980@gmail.com>",
        "Nicholas Hallahan <nick@theoutpost.io>",
        "Ola Bini <ola.bini@gmail.com>",
        "Danilo Sato <dtsato@gmail.com>",
        "Henning Schumann <henning.schumann@gmail.com>",
        "Michael Deardeuff <michael.deardeuff@gmail.com>",
        "Pete Hodgson <git@thepete.net>",
        "Marcin Cieslak <saper@saper.info>",
        "M. Kelley Harris (http://www.kelleyharris.com)",
        "Ryan Bennett <nomad.ry@gmail.com>",
        "Paul Rodwell <paul.rodwell@btinternet.com>",
        "David Turnbull <dturnbull@gmail.com>",
        "Austin King <shout@ozten.com>"
      ]
    },

    retire: {
      js: ['client/js/*.js'],
      options: {}
    },

    // tidy-up before we start the build
    clean: ['build/*', 'client/client.js', 'client/client.map', 'client/client.*.js', 'client/client.*.map', 'client/test/testclient.js'],

    browserify: {
      // build the client that we will include in the package
      packageClient: {
        src: ['./client.coffee'],
        dest: 'client/client.js',
        options: {
          transform: ['coffeeify', 'browserify-versionify'],
          transform: [['coffeeify', {transpile: {presets: ['@babel/preset-env']}}]],
          browserifyOptions: {
            extensions: ".coffee"
          }
        }
      },
      // build for local development version of the client will go here (once mapfile issues are resolved)

      // build the browser testclient
      testClient: {
        src: ['./testclient.coffee'],
        dest: 'client/test/testclient.js',
        options: {
          transform: [['coffeeify', {transpile: {presets: ['@babel/preset-env']}}]],
          browserifyOptions: {
            extensions: ".coffee"
          }
        }
      }
    },

    mochaTest: {
      test: {
        options: {
          timeout: false,
          reporter: 'spec',
          require: 'coffeescript/register'
        },
        src: [
          'test/util.coffee',
          'test/random.coffee',
          'test/page.coffee',
          'test/lineup.coffee',
          'test/drop.coffee',
          'test/revision.coffee',
          'test/resolve.coffee',
          'test/wiki.coffee'
        ]
      }
    },

    watch: {
      all: {
        files: ['test/*.coffee', 'lib/*.coffee', '*.coffee'],
        tasks: ['build']
      }
    }
  });

  // build without sourcemaps
  grunt.registerTask('build', ['clean', 'browserify:packageClient', 'browserify:testClient']);

  // check for out-of-date libraries and known vulnerabilities

  grunt.registerTask('check', ['retire']);


  // the default is to do the production build.
  grunt.registerTask('default', ['build']);

};
