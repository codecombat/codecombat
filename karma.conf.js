
module.exports = function(config) {

  config.set({
    // base path, that will be used to resolve files and exclude
    basePath : '',

    frameworks: ['jasmine'],

    // list of files / patterns to load in the browser
    files : [
      'public/javascripts/esper.modern.js', // Doesn't load properly from vendor.js.
      'public/javascripts/app/vendor/aether-python.modern.js',
      'public/javascripts/app/vendor/aether-coffeescript.modern.js',
      'public/javascripts/app/vendor/aether-lua.modern.js',
      'public/javascripts/test.js',
      // 'public/javascripts/chunks/TestView.bundle.js',
      // 'public/javascripts/vendor.js', // need for jade definition...
      // 'public/javascripts/whole-vendor.js',
      // 'public/lib/ace/ace.js',
      // 'public/javascripts/aether.js',
      // 'public/javascripts/whole-app.js',
      // 'public/javascripts/app/vendor/jasmine-mock-ajax.js',
      // 'public/javascripts/app/tests.js',
      // 'public/javascripts/run-tests.js'
    ],

    preprocessors : {
      '**/*.coffee': 'coffee',
      '**/javascripts/whole-app.js': 'coverage' // TODO: Webpack: get this working
    },

    // list of files to exclude
    exclude : [],

    // test results reporter to use
    // possible values: 'dots', 'progress', 'junit'
    reporters : ['progress', 'coverage'],

    // web server port
    port : 9050,

    // cli runner port
    runnerPort : 9051,

    // enable / disable colors in the output (reporters and logs)
    colors : true,

    // level of logging
    // possible values: LOG_DISABLE || LOG_ERROR || LOG_WARN || LOG_INFO || LOG_DEBUG
    logLevel : config.LOG_ERROR, // doesn't seem to work?

    // enable / disable watching file and executing tests whenever any file changes
    autoWatch : true,

    // Start these browsers, currently available:
    // - Chrome
    // - ChromeCanary
    // - Firefox
    // - Opera
    // - Safari (only Mac)
    // - PhantomJS
    // - IE (only Windows)
    browsers : ['Firefox'],

    // If browser does not capture in given timeout [ms], kill it
    captureTimeout : 15000,

    transports: ['polling'],

    // Continuous Integration mode
    // if true, it capture browsers, run tests and executing
    singleRun : false,

    coverageReporter : {
      type : 'html',
      dir : 'coverage/'
    },

    //browserConsoleLogOptions: {
    //  level: 'log',
    //  terminal: true
    //},

    plugins : [
      'karma-jasmine',
      //'karma-chrome-launcher',
      //'karma-phantomjs-launcher',
      'karma-coffee-preprocessor',
      'karma-coverage',
      'karma-firefox-launcher'
    ],

    retryLimit: 5,
    browserNoActivityTimeout: 60000,     // default 10,000ms
    browserDisconnectTolerance: 5
  });

};
