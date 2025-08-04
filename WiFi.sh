#!/bin/bash
#This script helps when you are trying to open a public WiFi portal to gain access to the internet
firefox "http://neverssl.com" &
echo "To get to any portal, try accessing a non-HTTPS website as many captive portals intercept HTTP traffic like http://neverssl.com"
