module("GameStatusDefine", package.seeall)

-----状态标识------
AllTypes = {
    BaseSpinGame = 1,
    FreeSpinGame = 2,
    ReSpinGame = 3,
     --继续Spin
    HoldSpinGame = 4,
    SuperFreeSpinGame = 5,
    BonusSpinGame = 100,
    ClassicSpinGame = 10
}

AllFuncs = {}
PriorityLevel = {}
SortedPriorityLevel = {}
GtSortedPriorityLevel = {}
