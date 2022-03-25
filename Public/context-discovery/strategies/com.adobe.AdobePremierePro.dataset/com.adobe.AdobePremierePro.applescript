tell application "System Events"
	tell process "com.adobe.AdobePremierePro"
		return the title of (get front window)
	end tell
end tell