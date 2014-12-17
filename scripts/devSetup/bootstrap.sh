#!/bin/bash

repositoryUrl=${1:-https://github.com/codecombat/codecombat.git}
deps=( git python )
NODE_VERSION=v0.10
function checkDependencies { #usage: checkDependencies [name of dependency array] [name of error checking function]
    declare -a dependencyArray=("${!1}")
    for i in "${dependencyArray[@]}"
    do
        command -v $i >/dev/null 2>&1 || { $2 "$i" >&2; exit 1; }
    done
}

function openUrl {
    case "$OSTYPE" in
        darwin*)
            open $@;;
        linux*)
            xdg-open $@;;
        *)
            echo "$@";;
    esac
}

function basicDependenciesErrorHandling {
    case "$1" in
    "python")
        echo "Python isn't installed. Please install it to continue."
        read -p "Press enter to open download link..."
        openUrl http://www.python.org/download/
        exit 1
        ;;
    "git")
        echo "Please install Git.(If you're running mac, this is included in the XCode command line tools."
    esac
 }


function checkIsRoot {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root (run 'sudo ./$me $installDirectory')" 1>&2
        exit 1
    fi
}

function checkNodeVersion {
    #thanks https://gist.github.com/phatblat/1713458
    node --version | grep ${NODE_VERSION}
    if [[ $? != 0 ]] ; then
        echo "Node was found, but not version 0.10. Make sure 0.10 is installed before running the install script."
        echo "Also, make sure `sudo node -v` also returns v0.10.x."
        exit 1
    fi
}

checkDependencies deps[@] basicDependenciesErrorHandling
#check for node
if command -v node >/dev/null 2>&1; then
    checkNodeVersion
fi

#check if a git repository already exists here
if [ -d .git ]; then
  echo "A git repository already exists here!"
else
  #install git repository
  git clone $repositoryUrl coco
  #python ./coco/scripts/devSetup/setup.py
  echo "Now copy and paste 'sudo python ./coco/scripts/devSetup/setup.py' into the terminal!"
fi
