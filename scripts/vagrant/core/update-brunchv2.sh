#!/bin/bash -e
# Original content copyright (c) 2014 dpen2000 licensed under the MIT license

echo "updating brunch to v2..."
cd /vagrant
npm install \
    brunch@">=2.0.0" \
    auto-reload-brunch@">=2.0.0" \
    coffee-script-brunch@">=2.0.0" \
    coffeelint-brunch@">=2.0.0" \
    css-brunch@">=2.0.0" \
    javascript-brunch@">=2.0.0" \
    sass-brunch@">=2.0.0" --no-bin-links