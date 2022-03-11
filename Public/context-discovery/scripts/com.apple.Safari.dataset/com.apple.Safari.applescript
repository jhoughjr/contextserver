tell application id "com.apple.Safari"
    set t to the current tab of the front window
    return {the URL of t}
end tell
