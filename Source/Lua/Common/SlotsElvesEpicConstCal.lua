module("SlotsElvesEpicConstCal", package.seeall)
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
        local totalJackpotAmount = 0

        if (selTotalValue > 0)
        then
            --LOG(RUN, INFO).Format("[SlotsElvesEpicConst][DealJackpot] selTotalValue is:%s", selTotalValue)
        end
        
        local addAmount = 0
        for k, v in ipairs(ElvesEpicJackpotBetConfig)
        do
            local GJackpotK = "Jackpot.Amount"..k

            local orginValue = GlobalState:GetLatest(GJackpotK)
            local curValue = orginValue / NUM_FLAG

            local gainAmount = selConf.amount[k]

            addAmount = addAmount + selConf.amount[k]
            local orgTotalValue = curValue + gainAmount

            totalJackpotAmount = totalJackpotAmount + orgTotalValue

            GlobalState:Append(GJackpotK, gainAmount)
            LOG(RUN, INFO).Format("[SlotsElvesEpicConst][DealJackpot] k is: %s, orgTotalValue is: %s, orginValue is:%s, gainAmount is:%s", k, orgTotalValue, orginValue, gainAmount)
        end

        --LOG(RUN, INFO).Format("[SlotsElvesEpicConst][DealJackpot] addAmount is:%s", addAmount)
        --LOG(RUN, INFO).Format("[SlotsElvesEpicConst][DealJackpot] totalJackpotAmount1 is:%s", totalJackpotAmount)
        totalJackpotAmount = totalJackpotAmount - selTotalValue
        if (totalJackpotAmount < 0)
        then
            totalJackpotAmount = 0
        end
        --LOG(RUN, INFO).Format("[SlotsElvesEpicConst][DealJackpot] totalJackpotAmount2 is:%s", totalJackpotAmount)
        for k, v in ipairs(ElvesEpicJackpotBetConfig)
        do
            local GJackpotK = "Jackpot.Amount"..k
            local orginValue = GlobalState:GetLatest(GJackpotK)
            local newValue = 0
            if (isWin == 1)
            then
                newValue = totalJackpotAmount * ElvesEpicJackpotBetConfig[k].distri_ratio

                local durValue = tonumber(newValue * NUM_FLAG) - orginValue
                LOG(RUN, INFO).Format("[SlotsElvesEpicConst][DealJackpot] totalJackpotAmount is: %s,  newValue is:%s", totalJackpotAmount, newValue)
                GlobalState:Append(GJackpotK, durValue)
            end

        end

        local totalAmountKey = "Jackpot.TotalAmount"
        local orginTotalValue = GlobalState:GetLatest(totalAmountKey)

        local durTotalValue = tonumber(totalJackpotAmount * NUM_FLAG) - orginTotalValue
        GlobalState:Append(totalAmountKey, durTotalValue)

        response.ret = Return.OK()
        response.win_amount = selTotalValue
    
        return response
	end,


}
