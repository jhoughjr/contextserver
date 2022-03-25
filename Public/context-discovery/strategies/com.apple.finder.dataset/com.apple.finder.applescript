tell application id "com.apple.finder"
set baz to (get selection as alias list)
if the (count of item in baz) is 0 then
    error "No selection"
    else
    set foo to (first item of baz as alias)
    return foo as string
end if
end tell
