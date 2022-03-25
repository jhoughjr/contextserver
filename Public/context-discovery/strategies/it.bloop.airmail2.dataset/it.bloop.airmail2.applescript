tell application "Airmail 3"
	set theSelection to the selected message
	set theSender to the sender of theSelection
	set theSubject to the subject of theSelection
	set theID to the id of theSelection
	return theID & ": " & theSender & " / " & theSubject
end tell
