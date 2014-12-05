questList = {}

questList[1] = {
name = "Quest Test",
enemyAmnt = {1,1},
enemyLv = {1,2},
enemyType = {1,1,1,2,2,3},
typeBonus = {1,2,3}
}

-- This kind of shows the idea behind the weighted random enemy selection

-- 1 = Spider
-- 2 = Snake
-- 3 = Boar

-- Easy = {1,1,1,2,2,3} - length 6
-- 1(3) = 50%
-- 2(2) = 33%
-- 3(1) = 16%

-- Medium = {1,1,1,1,2,2,2,3,3} - length 9
-- 1(4) = 44%
-- 2(3) = 33%
-- 3(2) = 22%

-- Hard = {1,1,1,1,1,2,2,2,2,3,3,3} - Length 12
-- 1(5) = 41%
-- 2(4) = 33%
-- 3(3) = 25%

-- Very Hard = {1,1,1,1,1,1,2,2,2,2,2,3,3,3,3} - Length 15
-- 1(6) = 40%
-- 2(5) = 33%
-- 3(4) = 26%

-- Very Hard = {1,1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3} - Length 18
-- 1(7) = 39%
-- 2(6) = 33%
-- 3(5) = 27%


