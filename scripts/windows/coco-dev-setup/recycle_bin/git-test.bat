@echo off
setlocal EnableDelayedExpansion

::  + Configuraton and installation checklist:
::      1) cd codecombat
::      2) npm install -g bower brunch nodemon sendwithus
::      3) bower install
::      4) gem install sass
::      5) npm install
::      6) brunch -w
::      Extra... @ Fail run npm install

echo "Moving to your git repository..."
C:
cd C:\CodeCombat

PAUSE

SET "PATH=%PATH%;C:\Program Files\Nodejs" /M
setx -m git "C:\Program Files (x86)\Git\bin"
SET "PATH=%PATH%;C:\Program Files (x86)\Git\bin;C:\Program Files (x86)\Git\cmd" /M

PAUSE

echo "Installing bower, brunch, nodemon and sendwithus..."
start cmd /k "npm install -g bower brunch nodemon sendwithus & exit"

PAUSE

echo "running npm install..."
start cmd /k "npm install & exit"

PAUSE

echo "Activating bower install..."
start cmd /k "bower install & PAUSE & exit"

PAUSE

echo "Installing sass via gem..."
start cmd /k "install sass & PAUSE & exit"

PAUSE

echo "comping repository via brunch..."
start cmd /k "brunch -w & exit"

PAUSE

endlocal