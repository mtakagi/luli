-- 継続行のインデントの深さによって E111 と E112 が交互に出現してしまうバグ
abcd('abc', function()
  print()
            end)
