#!/bin/bash

printf "\n☝️  Set up Touch ID\n"
if grep -q "pam_tid.so" "/etc/pam.d/sudo"; 
    then
        printf "\nTouch ID is set up for sudo!\n"
    else
        printf "\nTouch ID is not set up for sudo, setting it up now...\n"
        grep pam_tid /etc/pam.d/sudo >/dev/null || echo auth sufficient pam_tid.so | cat - /etc/pam.d/sudo | sudo tee /etc/pam.d/sudo > /dev/null
fi
if grep -q "pam_tid.so" "/etc/pam.d/sudo"; 
    then
        printf "\nTouch ID set up succeeded!\n"
    else
        printf "\nTouch ID set up failed!\n"
fi