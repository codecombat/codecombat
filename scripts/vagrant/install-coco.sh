#!/bin/bash
echo -------------------------------------------------------------------------
echo ----------Update software source
echo -------------------------------------------------------------------------
sleep 5s
sudo apt-get update
echo -------------------------------------------------------------------------
echo ----------Install compiler environment
echo -------------------------------------------------------------------------
sleep 5s
sudo apt-get -y install make build-essential curl git zlib1g-dev python-software-properties
echo -------------------------------------------------------------------------
echo ----------Download the codecombat git
echo -------------------------------------------------------------------------
sleep 5s
mkdir -p coco
cd coco
git clone https://github.com/codecombat/codecombat.git
echo -------------------------------------------------------------------------
echo ----------Install npm and Other runtime environments
echo -------------------------------------------------------------------------
sleep 5s
cd codecombat
sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get -y install nodejs
sudo npm install
echo -------------------------------------------------------------------------
echo ----------Install the new version
echo -------------------------------------------------------------------------
sleep 5s

# sudo npm install coffee-script@1.10.0 geoip-lite@1.1.6 grunt-cli@0.1.13 node-gyp@0.13.0 sendwithus@2.9.0 auto-reload-brunch@1.8.0 bower@1.5.2 brunch@1.8.5 nodemon@1.4.1

sudo npm install geoip-lite@1.1.6
sudo npm install grunt-cli@0.1.13
sudo npm install node-gyp@0.13.0
sudo npm install sendwithus@2.9.0
sudo npm install auto-reload-brunch@1.8.0
sudo npm install bower@1.5.2
sudo npm install brunch@1.8.5
sudo npm install nodemon@1.4.1
echo -------------------------------------------------------------------------
echo ----------Update npm and install ruby sass
echo -------------------------------------------------------------------------
sleep 5s
sudo npm update
sudo apt-get -y install ruby1.9.1 ruby1.9.1-dev
sudo gem install sass
echo -------------------------------------------------------------------------
echo ----------Install bower
echo -------------------------------------------------------------------------
sleep 5s
sudo ./node_modules/bower/bin/bower --allow-root install
sudo ./node_modules/bower/bin/bower --allow-root update
echo -------------------------------------------------------------------------
echo ----------Download and install mongodb 3.0.6
echo -------------------------------------------------------------------------
sleep 5s
cd ~/coco && mkdir -p mongodl
cd mongodl
curl -O https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1204-3.0.6.tgz
tar xfz mongodb-linux-x86_64-ubuntu1204-3.0.6.tgz
sudo cp mongodb-linux-x86_64-ubuntu1204-3.0.6/bin/* /usr/local/bin
echo -------------------------------------------------------------------------
echo ----------Download and unpack database
echo -------------------------------------------------------------------------
sleep 5s
cd ~/coco && mkdir -p db
cd db
wget http://analytics.codecombat.com:8080/dump.tar.gz
tar xzvf dump.tar.gz
echo -------------------------------------------------------------------------
echo ----------Update CreateJS
echo -------------------------------------------------------------------------
sleep 5s
cd ~/coco && mkdir -p CreateJS
cd CreateJS
git clone https://github.com/CreateJS/EaselJS.git
cd EaselJS
sudo npm update
cd build
sudo npm update
echo -------------------------------------------------------------------------
echo ----------building EaselJS
echo -------------------------------------------------------------------------
sleep 5s
sudo ~/coco/codecombat/node_modules/grunt-cli/bin/grunt combine

cd ~/coco/CreateJS
git clone https://github.com/CreateJS/PreloadJS.git
cd PreloadJS
sudo npm update
cd build
sudo npm install
sudo npm update
echo -------------------------------------------------------------------------
echo ----------building PreloadJS
echo -------------------------------------------------------------------------
sleep 5s
sudo ~/coco/codecombat/node_modules/grunt-cli/bin/grunt combine

git clone https://github.com/CreateJS/SoundJS.git
cd SoundJS
sudo npm update
cd build
sudo npm install
sudo npm update
echo -------------------------------------------------------------------------
echo ----------building SoundJS
echo -------------------------------------------------------------------------
sleep 5s
sudo ~/coco/codecombat/node_modules/grunt-cli/bin/grunt combine

git clone https://github.com/CreateJS/TweenJS.git
cd TweenJS
sudo npm update
cd build
sudo npm install
sudo npm update
echo -------------------------------------------------------------------------
echo ----------building TweenJS
echo -------------------------------------------------------------------------
sleep 5s
sudo ~/coco/codecombat/node_modules/grunt-cli/bin/grunt combine
echo -------------------------------------------------------------------------
echo ----------moving to CoCo
echo -------------------------------------------------------------------------
sleep 5s
cp ~/coco/CreateJS/EaselJS/build/output/easeljs-NEXT.combined.js ~/coco/codecombat/vendor/scripts
cp ~/coco/CreateJS/EaselJS/build/output/movieclip-NEXT.combined.js ~/coco/codecombat/vendor/scripts
cp ~/coco/CreateJS/EaselJS/src/easeljs/display/SpriteStage.js ~/coco/codecombat/vendor/scripts/
cp ~/coco/CreateJS/EaselJS/src/easeljs/display/SpriteContainer.js ~/coco/codecombat/vendor/scripts/
cp ~/coco/CreateJS/SoundJS/lib/soundjs-NEXT.combined.js ~/coco/codecombat/vendor/scripts
cp ~/coco/CreateJS/PreloadJS/build/output/preloadjs-NEXT.combined.js ~/coco/codecombat/vendor/scripts
cp ~/coco/CreateJS/TweenJS/build/output/tweenjs-NEXT.combined.js ~/coco/codecombat/vendor/scripts
echo -------------------------------------------------------------------------
echo ----------Install database snapshot
echo -------------------------------------------------------------------------
sleep 5s
cd ~/coco && mkdir -p log
sudo ./codecombat/bin/coco-mongodb >~/coco/log/mongodb.log 2>&1 &
echo Wait 120 seconds
sleep 120s
cd db && sudo mongorestore --drop dump
echo -------------------------------------------------------------------------
echo ----------Generate run-coco file
echo -------------------------------------------------------------------------
sleep 5s
cd ~/coco
cat <<- EOF > run-coco.sh
#!/bin/bash
nohup  ~/coco/codecombat/bin/coco-mongodb >~/coco/log/mongodb.log 2>&1 &
sleep 5s
nohup  ~/coco/codecombat/bin/coco-brunch >~/coco/log/brunch.log 2>&1 &
sleep 5s
nohup  ~/coco/codecombat/bin/coco-dev-server >~/coco/log/dev_server.log 2>&1 &
EOF
chmod 777 run-coco.sh
echo -------------------------------------------------------------------------
echo ----------ok!now ,reboot your computer and run run-coco.sh
echo -------------------------------------------------------------------------
