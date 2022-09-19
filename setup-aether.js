/**
 * Set up and build Aether. We build Aether as a separate artifact using
 * webpack. We also rename certain esper files here and move those files
 * into the public directory to be loaded dynamically at runtime by the
 * browser and service workers.
 *
 * Note:
 *  esper-modern requires modern language plugin to be loaded otherwise it won't
 *  work correctly.
 */
const fs = require("fs-extra");
const webpack = require("webpack");
const path = require("path");
const { publicFolderName } = require('./development/utils')

// List of esper langauge plugins we want to move into the public directory.
const targets = ["lua", "python", "coffeescript"];

const PWD = process.env.PWD || __dirname;  // __dirname might be undesirable if this is symlinked

const aether_webpack_config = {
  context: path.resolve(PWD),
  entry: {
    aether: "./app/lib/aether/aether.coffee",
    // We need to create the html parser ourselves and move it ourselves into
    // `/javascripts/app/vendor/aether-html.js`
    html: "./app/lib/aether/html.coffee"
  },
  output: {
    filename: "./aether/build/[name].js",
    path: path.resolve(PWD, 'bower_components'),
  },
  module: {
    rules: [
      {
        test: /\.coffee$/,
        use: ["coffee-loader"]
      },
      {
        test: /\.mjs$/, // https://github.com/formatjs/formatjs/issues/1395#issuecomment-518823361
        include: /node_modules/,
        type: "javascript/auto"
      },
      { test: /\.js$/,
        exclude: /(node_modules|bower_components|vendor)/,
        use: [{
          loader: 'babel-loader'
        }]
      }
    ]
  },
  resolve: {
    extensions: [".coffee", ".json", ".js"],
    fallback: {
      fs: false,
      buffer: require.resolve("buffer/")
    }
  },
  externals: {
    "esper.js": "esper",
    lodash: "_",
    "source-map": "SourceMap"
  },
  mode: process.env.BRUNCH_ENV === "production" ? 'production' : 'development'
};

webpack(aether_webpack_config, function(err, stats) {
  if (err) {
    console.log(err);
  } else {
    console.log("Packed aether!");
    if (stats.compilation.errors.length) {
      console.error("Compilation errors:", stats.compilation.errors);
    }
    copyLanguagesFromEsper(targets);
  }
});

function copyLanguagesFromEsper(targets) {
  // Get a list of the regular and modern language plugin paths.
  const target_paths = targets
    .map(lang => [
      [
        path.join(
          PWD,
          "bower_components",
          "esper.js",
          `esper-plugin-lang-${lang}.js`
        ),
        path.join(
          PWD,
          publicFolderName,
          "javascripts",
          "app",
          "vendor",
          `aether-${lang}.js`
        )
      ],
      [
        path.join(
          PWD,
          "bower_components",
          "esper.js",
          `esper-plugin-lang-${lang}-modern.js`
        ),
        path.join(
          PWD,
          publicFolderName,
          "javascripts",
          "app",
          "vendor",
          `aether-${lang}.modern.js`
        )
      ]
    ])
    .reduce((l, paths) => l.concat(paths));

  for (let [src, dest] of target_paths) {
    // const src = path.join(PWD, 'bower_components', 'esper.js', `esper-plugin-lang-${target}.js`);
    // const dest = path.join(PWD, 'bower_components', 'aether', 'build', `${target}.js`);
    console.log(`Copy ${src}, ${dest}`);
    fs.copySync(src, dest);
  }

  // Finally copy html as we globally load these within the html iframe.
  const src = path.join(
    PWD,
    "bower_components",
    "aether",
    "build",
    "html.js"
  );
  const dest = path.join(
    PWD,
    publicFolderName,
    "javascripts",
    "app",
    "vendor",
    "aether-html.js"
  );
  fs.copySync(src, dest);
  console.log(`Copy ${src}, ${dest}`);
}
