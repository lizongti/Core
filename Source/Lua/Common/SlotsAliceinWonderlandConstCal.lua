module("SlotsAliceinWonderlandConstCal", package.seeall)
require "Util/TableExt"


Calculate = {
    DealJackpot = function(response, winValue, selConf, selTotalValue, GlobalSession, NUM_FLAG)
        response.amount = selTotalValue
        local isWin = 0
        if (winValue and winValue == 1)
        then
            isWin = 1
        end
        if (isWin == 0)
        then
            selTotalValue = 0
        end
        if (not selTotalValue)
        then
            selTotalValue = 0
        end
        
        if (selTotalValue > 0)
        then
            --LOG(RUN, INFO).Format("[SlotsAliceinWonderlandConst][DealJackpot] selTotalValue is:%s", selTotalValue)
        end
        local totalJackpotAmount = 0
        local addAmount = 0
        --------------没中JACKPOT将注入奖池
        for k, v in pairs(AliceinWonderlandJackpotBetConfig)
        do
            local GJackpotK = "AliceWonderJackpot.Amount"..k

            local orginValue = GlobalState:GetLatest(GJackpotK)
            local curValue = orginValue / NUM_FLAG

            local gainAmount = selConf.amount[k]

            addAmount = addAmount + selConf.amount[k]

            local orgTotalValue = curValue + gainAmount

            totalJackpotAmount = totalJackpotAmount + orgTotalValue

            GlobalState:Append(GJackpotK, gainAmount)

            --LOG(RUN, INFO).Format("[SlotsAliceinWonderlandConst][DealJackpot] k is: %s, orgTotalValue is: %s, orginValue is:%s, gainAmount is:%s", k, orgTotalValue, orginValue, gainAmount)
        end
        --LOG(RUN, INFO).Format("[SlotsAliceinWonderlandConst][DealJackpot] addAmount is:%s", addAmount)
        --LOG(RUN, INFO).Format("[SlotsAliceinWonderlandConst][DealJackpot] totalJackpotAmount1 is:%s", totalJackpotAmount)
        totalJackpotAmount = totalJackpotAmount - selTotalValue
        if (totalJackpotAmount < 0)
        then
            totalJackpotAmount = 0
        end
        --LOG(RUN, INFO).Format("[SlotsAliceinWonderlandConst][DealJackpot] totalJackpotAmount2 is:%s", totalJackpotAmount)
        for k, v in pairs(AliceinWonderlandJackpotBetConfig)
        do
            local GJackpotK = "AliceWonderJackpot.Amount"..k
            local orginValue = GlobalState:GetLatest(GJackpotK)
            local newValue = 0
            --------------中奖将从每个奖池扣除
            if (isWin == 1)
            then
                newValue = totalJackpotAmount * v.distri_ratio

                local durValue = tonumber(newValue * NUM_FLAG) - orginValue
                LOG(RUN, INFO).Format("[SlotsAliceinWonderlandConst][DealJackpot] k is: %s, isWin is: %s,  totalJackpotAmount is: %s,  newValue is:%s, orginValue is:%s", k, isWin, totalJackpotAmount, newValue, orginValue)
                GlobalState:Append(GJackpotK, durValue)
            end

        end

        local totalAmountKey = "AliceWonderJackpot.TotalAmount"
        local orginTotalValue = GlobalState:GetLatest(totalAmountKey)

        local durTotalValue = tonumber(totalJackpotAmount * NUM_FLAG) - orginTotalValue
        GlobalState:Append(totalAmountKey, durTotalValue)
    
        response.ret = Return.OK()
        response.win_amount = selTotalValue
    
        return response
	end,


}
