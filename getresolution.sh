#!/bin/bash

xrandr | awk '/\*/ { print $1; exit }'
