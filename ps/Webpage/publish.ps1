
git add -A
git commit -m "Web page published from Windows box"
git push
echo "Copying webpage to One Drive"
copy "$env:USERPROFILE\Documents\github\webpage\index.html" "C:\Users\jsmith.al-jsmith-sp3\OneDrive\Documents\ftp sync\index.html"

