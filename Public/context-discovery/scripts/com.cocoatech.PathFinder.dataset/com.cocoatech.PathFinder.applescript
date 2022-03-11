tell application "Path Finder"
set theSelection to the selection
if theSelection is equal to missing value or the (count of items in theSelection) is 0 then
    set theSelection to the name of the front window
    return path of theSelection
    else
    return path of (item 1 of theSelection)
end if
end tell
