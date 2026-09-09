$p = "C:\Users\parke\source\commons-shorts-roku\components\MainScene.brs"
$lines = Get-Content $p
$lines[17] = '    return "https://raw.githubusercontent.com/parker-pdl/commons-shorts-roku/master/feed/feed.json"'
Set-Content $p $lines
Get-Content $p | Select-Object -Index 16,17,18
Set-Location C:\Users\parke\source\commons-shorts-roku
git add -A
git commit -q -m "Point FEED_URL at GitHub raw feed" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
git push 2>&1 | Select-Object -Last 5
git log --oneline -3
