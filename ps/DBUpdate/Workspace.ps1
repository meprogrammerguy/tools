$tfFile = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\tf.exe"
$tf = & $tfFile workspaces /collection:http://al-tfs2012-vm1:8080/tfs/defaultcollection
$tf | Out-null