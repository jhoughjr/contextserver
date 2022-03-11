-- adapted from https://secure.macscripter.net/viewtopic.php?pid=187113#p187113 by Nigel Garvey
--
--
-- Store the current clipboard contents.

set theClipboard to (the clipboard as record)
-- Set the clipboard to a default blank value
set the clipboard to ""

-- Bring NewMoon to the front, highlight the URL in the URL field and copy it.
tell application "System Events"
	set frontmost of application process "NewMoon" to true
	keystroke "lc" using {command down}
end tell

-- Read the clipboard contents until either they change from "" or a second elapses.
repeat 5 times
	delay 0.2
	set theURL to (the clipboard)
	if (theURL ≠ "") then exit repeat
end repeat

-- Restore the old clipboard contents.
set the clipboard to theClipboard

theURL
