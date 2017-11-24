#!/bin/bash
# Default script for opening electromechanical lock with
# https://www.modmypi.com/raspberry-pi/relays-and-home-automation-1032/relay-boards-1033/modmypi-piot-relay-board

PIN=$1

# sudo gpio export $PIN out
# sudo gpio -g write $PIN 1
# sleep 3
# sudo gpio -g write $PIN 0

echo "Door with gpio_pin=$PIN is opened!";
