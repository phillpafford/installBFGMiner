#!/bin/bash
#
# The MIT License (MIT)
#
# Copyright (c) 2014 Phill Pafford
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# inspired credit: https://github.com/joeswhite/makebfgminer
#
# Authors: Phill Pafford https://twitter.com/phillpafford
# Bitcoin: 18SDXNbLhUmcwZsC3RYu4qbA8ykvCxic6v
# Peercoin: PLGaQHRUukQC8RtwsfgzvYj3uiV6BGr9yZ
# Dogecoin: DK4riuULisMmuTzk7ky7fN7bALbEQrcypX
#
# Want to tip another coin just let me know
#
# Version: 1.0


export CLONE_HIDAPI_DECISION=0
export CLONE_BFGMINER_DECISION=0

INSTALL_PATH="/usr/local"

BFGMINER_INSTALL_PATH="${INSTALL_PATH}/bfgminer"
BFGMINER_REPO="https://github.com/luke-jr/bfgminer.git"

HIDAPI_INSTALL_PATH="${INSTALL_PATH}/hidapi"
HIDAPI_REPO="https://github.com/signal11/hidapi.git"

list_debian_packages_to_be_installed () {
    echo git
    echo build-essential
    echo autoconf
    echo automake
    echo libtool
    echo pkg-config
    echo libcurl4-gnutls-dev
    echo libjansson-dev
    echo uthash-dev
    echo libncursesw5-dev
    echo libudev-dev
    echo libusb-1.0-0-dev
    echo libevent-dev
    echo libmicrohttpd-dev
    echo uthash-dev

    # additional ???
    echo libfox-1.6-dev
    echo autotools-dev
    echo libncurses-dev
    echo yasm
    echo curl
    echo libcurl4-openssl-dev
    echo make
    echo libhid-dev
    echo libusb-dev

    # do these exists ???
    echo libusbx
}

install_required_debian_packages () {
    sudo apt-get install list_debian_packages_to_be_installed | tr "\\n" " "
}

list_bfgminer_tags () {
    cd ${BFGMINER_INSTALL_PATH}

    # if you want to see more/less results, change the count option
    git for-each-ref --format="%(refname)" --sort=-taggerdate --count=8 refs/tags | cut -c 6-
}

clone_bfgminer () {
    cd ${INSTALL_PATH}
    git clone ${BFGMINER_REPO} ${BFGMINER_INSTALL_PATH}
}

clone_hidapi () {
    cd ${INSTALL_PATH}
    git clone ${HIDAPI_REPO} ${HIDAPI_INSTALL_PATH}
}

decided_to_clone_hidapi () {
    export CLONE_HIDAPI_DECISION=$((CLONE_HIDAPI_DECISION+1))
}

decided_to_clone_bfgminer () {
    export CLONE_BFGMINER_DECISION=$((CLONE_BFGMINER_DECISION+1))
}

# parameters: install_path
clone_decision () {
    if [ -z "$1" ]
        then
            echo "missing install_path parameter"
    else
        search="bfgminer"
        case "$1" in
           *"$search"* ) decided_to_clone_bfgminer ${CLONE_BFGMINER_DECISION};;
        esac

        search="hidapi"
        case "$1" in
           *"$search"* ) decided_to_clone_hidapi ${CLONE_HIDAPI_DECISION};;
        esac
    fi
}

remove_directory () {
    if [ -z "$1" ]
        then
            echo "missing install_path parameter"
    else
        select yn in "Yes" "No"; do
            case $yn in
                Yes ) clone_decision $1; if [ ${CLONE_HIDAPI_DECISION} == 1 ] || [ ${CLONE_BFGMINER_DECISION} == 1 ]; then rm -rfv $1; fi; break;;
                No ) break;;
            esac
        done
    fi
}

check_install_path () {
    if [ -z "$1" ]
        then
            echo "missing install_path parameter"
    else
        if [ -d "$1" ]; then
            echo "$1 looks to be checked out, remove it?"
            remove_directory $1
        else
            clone_decision $1;
        fi
    fi
}

make_install_hidapi () {
    cd ${HIDAPI_INSTALL_PATH}
    echo "make install hidapi"
    sudo ./bootstrap
    sudo ./configure  --prefix=/usr
    sudo make
    sudo make install
}

make_install_bfgminer () {
    cd ${BFGMINER_INSTALL_PATH}
    echo "make install bfgminer"
    ./autogen.sh
    ./configure
    make
}

install_required_debian_packages

echo "clone hidapi"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) check_install_path ${HIDAPI_INSTALL_PATH}; if [ ${CLONE_HIDAPI_DECISION} == 1 ]; then clone_hidapi; make_install_hidapi; fi; break;;
        No ) break;;
    esac
done

echo "clone bfgminer"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) check_install_path ${BFGMINER_INSTALL_PATH}; if [ ${CLONE_BFGMINER_DECISION} == 1 ]; then clone_bfgminer; fi; break;;
        No ) break;;
    esac
done

echo "select number to switch tag or master (will update to latest)"
echo ""

select result in master $(list_bfgminer_tags)
do
    cd ${BFGMINER_INSTALL_PATH}

    if [[ ${result} = master ]]; then
        echo "switch to bfgminer"
        git checkout bfgminer
        git pull
        break
    elif [[ -z "${result}" ]]; then
        echo "select an option"
        echo ""
    else
        echo "switching to tag ${result}"
        git checkout ${result}
        break
    fi
done

make_install_bfgminer
