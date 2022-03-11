tell application "Google Chrome"
set t to the active tab of the front window
return {the URL of t, the title of t}
end tell
