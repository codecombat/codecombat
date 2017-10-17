if (process.env.COCO_TRAVIS_TEST){
  console.log("Automatically using Travis (testing) webpack config");
  module.exports = require('./webpack.testing.config')
} else if (process.env.BRUNCH_ENV == 'production'){
  console.log("Automatically using Production webpack config");
  module.exports = require('./webpack.production.config')
} else {
  console.log("Automatically using Development webpack config");
  module.exports = require('./webpack.development.config')
}
