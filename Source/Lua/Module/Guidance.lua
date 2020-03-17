module("Guidance", package.seeall)
require "Common/SlotsOpenSesameCal"

--这套导表要导出层次深一点的表实在是难难难...
--这里手写出来算了, dogs fucked
local guidance_wilds = {
    [1] = {
        [3] = {4, 9, 14}
    },
    [2] = {
        [1] = {4, 9, 14},
        [3] = {5, 10, 14},
    },
    [3] = {
        [1] = {4, 9, 15},
        [3] = {2, 7, 9},
        [4] = {4, 5, 6},
    },
    [5] = {
        [1] = {5, 10, 15},
        [3] = {5, 9, 14},
    },
    [7] = {
        [2] = {4, 9, 15},
    },
    [12] = {
        [1] = {4, 9, 14},
        [4] = {4, 9, 14},
    },
    [14] = {
        [1] = {5, 10, 15},
        [3] = {5, 11, 15},
    }
}
--这个的存在也是因为难支持深层次的table,心塞...
local num_2_str = {[1] = "one", [2] = "two", [3] = "three", [4] = "four"}

FetchData = function ( _M, session, request )
	local response = {header = {router = "Response"}}
    response.ret = Return.OK()


    --LOG(RUN, INFO).Format("[Guidance][FetchData] player %s , response is: %s", player.id, Table2Str(response))
    return response
end