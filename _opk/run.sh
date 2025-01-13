#!/bin/sh

./PocketSNES "$1"&
pid record $!
wait $!
pid erase
