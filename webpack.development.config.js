// Use this webpack config for development, with `webpack --config webpack.development.config.js`

// process.traceDeprecation = true;
const webpack = require('webpack');
const _ = require('lodash');
const LiveReloadPlugin = require('webpack-livereload-plugin');
const SpeedMeasurePlugin = require("speed-measure-webpack-plugin");

const smp = new SpeedMeasurePlugin({
  disable: !process.env.MEASURE
});

const baseConfigFn = require('./webpack.base.config')
// Development webpack config
module.exports = (env) => {
  if (!env) env = {};
  const baseConfig = baseConfigFn(env);
  const prePlugins = [
    // Enable IgnorePlugins for development to speed webpack
    //new webpack.IgnorePlugin({resourceRegExp: /\!locale/}),
    //new webpack.IgnorePlugin({resourceRegExp: /admin\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /artisans?\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /clans\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /contribute\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /courses\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /editor\/(?!autocomplete)/}),
    //new webpack.IgnorePlugin({resourceRegExp: /ladder\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /teachers\//}),
    //// new webpack.IgnorePlugin({resourceRegExp: /play\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /user\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /payments\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /podcast\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /account\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /docs\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /funding\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /HomeView\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /special_event\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /outcomes-report\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /library\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /efficacy\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /sel\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /school-administrator\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /pd\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /partners\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /minigames\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /landing-pages\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /dei\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /impact\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /assets\//}),
    //new webpack.IgnorePlugin({resourceRegExp: /\.ozar/}),
  ]
  const plugins = [
    new webpack.BannerPlugin({ // Label each module in the output bundle
      banner: "hash:[fullhash], chunkhash:[chunkhash], name:[name], filebase:[base], query:[query], file:[file]"
    }),
    new LiveReloadPlugin({ // Reload the page upon rebuild
      appendScriptTag: true,
      useSourceHash: true,
      port: process.env.WEBPACK_LIVE_RELOAD_PORT || (process.env.COCO_PRODUCT == 'ozaria' ? 35729 : 35432)
    })
  ]
  return smp.wrap(
    _.merge(baseConfig, {
      output: _.merge({}, baseConfig.output, {
        chunkFilename: 'javascripts/chunks/[name].bundle.js',
      }),
      //devtool: 'eval-source-map', // Recommended choice for development builds with high quality SourceMaps. https://webpack.js.org/configuration/devtool/
      //devtool: 'eval-cheap-source-map', // Tradeoff choice for development builds.
      devtool: 'eval', // Recommended choice for development builds with maximum performance.
      plugins: prePlugins.concat(baseConfig.plugins).concat(plugins),
      watchOptions: {
        ignored: /node_modules(?!\/ai\/dist)|bower_components|\.#|~$/,
      },
      mode: 'development'
    })
  )
}
