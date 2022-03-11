tell application "System Events"
    tell process "com.sublimetext.3"
        set foo to window 1
        set bar to the name of foo
        return bar
    end tell
end tell
