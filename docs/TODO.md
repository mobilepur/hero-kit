# TODO

header.style.color should have a large header option.

For iOS 26 devices:
we realised iOS 26 does not play nicely with large titles when the navbar has a background color 
therefor we try to re-plicate the pre iOS 26 behaviour.
 Steps:
- we constrain a header view with a color like we do with style.headerView.
- we add a label to that header and constrain it to look like the old system

For pre-iOS devices:
we just add preferLargeHeaders with iOS API 
