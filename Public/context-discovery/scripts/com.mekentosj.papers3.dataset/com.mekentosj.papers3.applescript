tell application "Papers"
	set p to selected publications of front library window
	set u to item url of item 1 of p
	## set pdfPath to full path of primary file item of item 1 of p
	## return pdfPath
	return u
end tell
