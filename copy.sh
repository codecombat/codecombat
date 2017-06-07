echo "Activing magic duct tape power!"
cp bower_components/esper.js/esper-plugin-lang-python.js public/javascripts/app/vendor/aether-python.js
cp bower_components/esper.js/esper-plugin-lang-lua.js public/javascripts/app/vendor/aether-lua.js
cp bower_components/esper.js/esper-plugin-lang-coffeescript.js public/javascripts/app/vendor/aether-coffeescript.js
touch public/javascripts/app/vendor/aether-javascript.js
./node_modules/.bin/webpack --config aether.webpack.config.js 
