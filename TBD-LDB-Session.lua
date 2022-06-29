--[[

]]

local name, session = ...;

local ldb = LibStub("LibDataBroker-1.1");
local callbacks = LibStub("CallbackHandler-1.0");

local sessionDataObject = ldb:NewDataObject("TBD-LDB-Sessions", {
    type = "data source",
    tooltip = "TbdLdbSession",
});


function sessionDataObject:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOP", self, "BOTTOM")
	GameTooltip:ClearLines()
	--sessionDataObject.OnTooltipShow(GameTooltip)
	GameTooltip:Show()
end


session.sessionInfo = {
    --gold
    balance = 0,
    credits = 0,
    debits = 0,
    --quest data
    questsCompleted = {},
    --reps
    reputations = {},
    --xp
    mobsKilled = 0,
    mobXpReward = 0,
};


function session:CheckPlayerMoney()
    local newBalance = GetMoney();
    local transactionValue = newBalance - session.sessionInfo.balance;
    if transactionValue > 0 then
        session.sessionInfo.credits = session.sessionInfo.credits + transactionValue;
    elseif transactionValue < 0 then
        session.sessionInfo.debits = session.sessionInfo.debits - transactionValue;
    end
    session.sessionInfo.balance = newBalance;
end

function session:ADDON_LOADED(...)

end


function session:PLAYER_ENTERING_WORLD(...)

end


function session:PLAYER_MONEY(...)
    if not MerchantFrame:IsVisible() then
        self:CheckPlayerMoney();
    end
end


function session:MERCHANT_CLOSED(...)
    self:CheckPlayerMoney();
end


function session:CHAT_MSG_COMBAT_FACTION_CHANGE(...)

    local info = ...;
    local rep = FACTION_STANDING_INCREASED:gsub("%%s", "(.+)"):gsub("%%d", "(.+)");
    local faction, gain = string.match(info, rep);
    
    gain = tonumber(gain);

    if self.sessionInfo.reputations[faction] then
        self.sessionInfo.reputations[faction] = self.sessionInfo.reputations[faction] + gain;
    else
        self.sessionInfo.reputations[faction] = gain;
    end

end


function session:CHAT_MSG_COMBAT_XP_GAIN(...)
    local text = ...;

    if text:find("dies") then

        if not self.sessionInfo then
            self.sessionInfo = {
                mobsKilled = 0,
                mobXpReward = 0,
            };
        end

        --if a mob dies and gives xp then we must have tagged it so grab the xp value and update the session info
        self.sessionInfo.mobsKilled = self.sessionInfo.mobsKilled + 1;

        --nasty but there are a lot of global strings for the various messages so just attempt to strip the number characters out using a guess on fixed position
        local start = text:find("you gain ");
        local finish = text:find(" experience");
        local xp = text:sub(start+9, finish);
        if tonumber(xp) then
            self.sessionInfo.mobXpReward = self.sessionInfo.mobXpReward + xp;
        end
    end
end


function session:QUEST_TURNED_IN(...)
    local questID, xpReward = ...;

    if not self.sessionInfo then
        self.sessionInfo = {
            questsCompleted = {},
        };
    end

    table.insert(self.sessionInfo.questsCompleted, {
        questID = questID,
        xpReward = xpReward or 0,
    });
end



session.e = CreateFrame("FRAME");
session.e:RegisterEvent("ADDON_LOADED");
session.e:RegisterEvent("PLAYER_ENTERING_WORLD");
session.e:RegisterEvent("PLAYER_MONEY");
session.e:RegisterEvent("MERCHANT_CLOSED");
session.e:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE");
session.e:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN");
session.e:RegisterEvent("QUEST_TURNED_IN");
session.e:SetScript("OnEvent", function(self, event, ...)
    if session[event] then
        session[event](session, ...)
    end
end);