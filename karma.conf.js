// Testacular configuration
// Generated on Fri Feb 15 2013 18:38:33 GMT-0500 (EST)


// base path, that will be used to resolve files and exclude
basePath = '.';


// list of files / patterns to load in the browser
files = [
  JASMINE,
  JASMINE_ADAPTER,

  'public/javascripts/vendor.js',
  'public/lib/ace/ace.js',
  'public/javascripts/app.js',

  'test/app/**/*.coffee'
];


// list of files to exclude
exclude = [
  
];


// test results reporter to use
// possible values: 'dots', 'progress', 'junit'
reporters = ['progress', 'coverage'];
//reporters = ['progress'];


// web server port
port = 9050;


// cli runner port
runnerPort = 9051;


// enable / disable colors in the output (reporters and logs)
colors = true;


// level of logging
// possible values: LOG_DISABLE || LOG_ERROR || LOG_WARN || LOG_INFO || LOG_DEBUG
logLevel = LOG_INFO;


// enable / disable watching file and executing tests whenever any file changes
autoWatch = true;


// Start these browsers, currently available:
// - Chrome
// - ChromeCanary
// - Firefox
// - Opera
// - Safari (only Mac)
// - PhantomJS
// - IE (only Windows)
browsers = ['Chrome'];


// If browser does not capture in given timeout [ms], kill it
captureTimeout = 5000;


// Continuous Integration mode
// if true, it capture browsers, run tests and exit
singleRun = false;


preprocessors = {
  '**/*.coffee': 'coffee',
  '**/javascripts/app.js': 'coverage'
};

coverageReporter = {
  type : 'html',
  dir : 'coverage/'
};
