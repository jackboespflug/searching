#!/usr/bin/env bash

set -e

# Determine if need to install and compile dependencies
install=false
for i in "$@"; do
  if [[ "$i" = "install" ]]; then
    install=true
  fi
done


#-------------------------------------------------
# Phoenix
#-------------------------------------------------
pushd backend

# if installing and compiling dependencies
if [[ $install = "true" ]]; then
  mix deps.get
  mix deps.compile
fi

# start the Phoenix server
mix phx.server &
popd


#-------------------------------------------------
# React
#-------------------------------------------------
pushd frontend
# if installing dependencies
if [[ $install = "true" ]]; then
    npm install
fi
# start the ReactJS application
npm start &
popd
