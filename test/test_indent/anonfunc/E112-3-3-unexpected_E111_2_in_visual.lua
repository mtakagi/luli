-- 継続行のインデントの深さによって E111 と E112 が交互に出現してしまうバグ
abcde('abc', function()
  print()
             end)
