#!/bin/bash

git add -A
git commit -m "Web page published from linux-home box"
git push
echo "Copying to OneDrive from Linux mint"
cp -f index.html "smb://win10-hd-home/users/jsmith/OneDrive/Documents/ftp sync/"
