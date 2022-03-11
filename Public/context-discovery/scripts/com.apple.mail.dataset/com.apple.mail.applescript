tell application id "com.apple.mail"
	set theSelection to the selection
	set theMessage to the last item of theSelection
	set theSender to the sender of theMessage
	set theDate to the date received of theMessage
	set theSubject to the subject of theMessage
	return theSender & " " & theDate & " " & theSubject
end tell