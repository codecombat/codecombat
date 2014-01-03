#!/bin/bash

repositoryUrl=https://github.com/codecombat/codecombat.git
deps=( git python )
function checkDependencies { #usage: checkDependencies [name of dependency array] [name of error checking function]
    declare -a dependencyArray=("${!1}")
    for i in "${dependencyArray[@]}"
    do
        command -v $i >/dev/null 2>&1 || { $2 "$i" >&2; exit 1; }
    done
}

function basicDependenciesErrorHandling {
    case "$1" in
    "python")
        echo "Python isn't installed. Please install it to continue."
        read -p "Press enter to open download link..."
        open http://www.python.org/getit/
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
#checkIsRoot
checkDependencies deps[@] basicDependenciesErrorHandling
#install git repository
git clone https://github.com/codecombat/codecombat.git coco
#python ./coco/scripts/devSetup/setup.py
echo "Now copy and paste 'sudo python ./coco/scripts/devSetup/setup.py' into the terminal!"
