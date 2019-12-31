-- local function html_safe(str)
-- 	local output, t = str:gsub("[^%w]", function(chr)
-- 		return string.format("%%%X", string.byte(chr))
-- 	end)
-- 	return output
-- end

-- local function build_param(url, tbl)
-- 	local param = "?"
-- 	for k, v in pairs(tbl) do
-- 		param = param .. k .. "=" .. html_safe(v) .. "&"
-- 	end
-- 	param = string.sub(param, 0, #param - 1)
-- 	return (url .. param)
-- end

local script_name = "scotty-casino-pokdeng"
-- local script_active = false

-- Citizen.CreateThread(function()
-- 	Citizen.Wait(4000)
-- 	-- local hostname = GetConvar("sv_hostname", "Unknown")
-- 	-- local url = build_param("http://api.scotty1944.net/client_five", {
-- 	-- 	request = Config["license_key"],
-- 	-- 	script_name = script_name,
-- 	-- 	client_name = hostname
-- 	-- })
-- 	LoadScript()
-- 	-- PerformHttpRequest(url, function(err, text, headers)
-- 	-- 	local st = json.decode(text or "")
-- 	-- 	if st then
			
-- 	-- 		local col = "\x1b[32m"
-- 	-- 		if st.status ~= 200 then
-- 	-- 			col = "\x1b[31m"
-- 	-- 		end
-- 	-- 		print(col.."[SLP]\x1b[0m " .. (st.desc or "Unknown State"))
-- 	-- 		if st.status == 200 then
-- 	-- 			LoadScript()
-- 	-- 		end
-- 	-- 	else
-- 	-- 		print("\x1b[32m[SLP]\x1b[0m " .. "couldn't connect to license server.")
-- 	-- 	end
-- 	-- end, 'GET', '', {["Content-Type"] = 'application/json'})
-- end)

-- RegisterServerEvent("scotty:license_"..script_name)
-- AddEventHandler("scotty:license_"..script_name, function()
-- 	TriggerClientEvent("scotty:license_"..script_name, source, script_active)
-- end)

-- function LoadScript()
	-- script_active = true
	-- print("\x1b[33m[" .. script_name .. "]\x1b[0m " .. "initiating splinter sequence.")

	if Config == nil then
		print("Failed to load " .. script_name .. " because of config is nil")
		return
	end

	ESX = nil
	TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

	local total_player = 5
	STATE_WAITING = 0
	STATE_START = 1
	STATE_DRAW = 2
	STATE_DRAW2 = 3
	STATE_REVEAL = 4
	DESK_TABLE = {}

	AddEventHandler("playerDropped", function()
		local src = source
		for k, v in pairs(DESK_TABLE) do
			v:OnPlayerLeave(src)
		end
	end)

	AddEventHandler("scotty:leaveDesk", function()
		local src = source
		local desk = PlayerGetTable(src)
		if desk then
			desk:OnPlayerLeave(src)
		end
	end)

	RegisterServerEvent("scotty-cpk:gameReceive")
	AddEventHandler("scotty-cpk:gameReceive", function(desk, action, data)
		local src = source
		
		Citizen.CreateThread(function()
			if DESK_TABLE[desk] == nil then
				return
			end

			local desk = DESK_TABLE[desk]
			
			if action == "join" then
				desk:PlayerJoin(src)
			elseif action == "leave" then
				desk:OnPlayerLeave(src)
			elseif action == "bet" then
				desk:PlayerBet(src, data)
			elseif action == "morecard" then
				desk:RequestMoreCard(src)
			elseif action == "pass" then
				desk:PassMoreCard(src)
			end
		end)
	end)

	function PlayerGetTable(src)
		for k, v in pairs(DESK_TABLE) do
			if v:IsPlayerInside(src) then
				return v
			end
		end
	end

	Citizen.CreateThread(function()
		while true do
			for k, v in ipairs(DESK_TABLE) do
				if v.Think then
					v:Think()
				end
			end
			Citizen.Wait(50)
		end
	end)
		
	AddEventHandler('es:playerLoaded', function(source)
		for k, v in ipairs(DESK_TABLE) do
			TriggerClientEvent("scotty-cpk:fetchGame", -1, v.id, "playerCount", #v.player)
		end
	end)
		
	function CreateTable(name, min, max, destiny_draw)
		local tbl = {}
		tbl.name = name
		tbl.minimum = min
		tbl.maximum = max
		tbl.state = 0
		tbl.player = {}
		tbl.dealer_card = {}
		tbl.id = (#DESK_TABLE + 1)

		if tbl.maximum < tbl.minimum then
			tbl.maximum = tbl.minimum
		end

		tbl.destiny_draw = destiny_draw
		tbl.state = STATE_WAITING
	   
		tbl.Start = function(self)

			if tbl.state ~= STATE_WAITING then
				return
			end

			self.state = STATE_START
			self:ResetCard()
			self:ResetPlayer()
			self:Timer(0.2, function()
				self:Broadcast("state", self.state)
				self:Timer(Config["game_time"]["wait_time"], function()
					
					local count = 0
					
					for k, v in pairs(self.player) do
						if v:GetBet() then
							count = count + 1
						end
					end
					
					if count <= 0 then
						self:Broadcast("dealer_text", "ผู้เล่นไม่เพียงพอ")
						self:Timer(5, function()
							self.state = STATE_WAITING
							self:Broadcast("state", self.state)
							self:ResetCard()
							self:ResetPlayer()
						end)
						
						return
					end
					
					self.state = STATE_DRAW
					self:Broadcast("state", self.state)
					self:SplitCard()
					self:Broadcast("dealcard", {
						dealer = self:GetDealerCard(),
						player = self:GetPlayerCard()
					})
					
					local sec = (((7 / 6) * #self.player) + 2)
					self:Timer(((7 / 6) * #self.player) + 2, function()
						local deal = {GetScore(self.dealer_card)}
						if (deal[4] == 8 or deal[4] == 9) and Config["dealer_pok_allow_more_card"] or (deal[4] ~= 8 and deal[4] ~= 9) then
							self.state = STATE_DRAW2
							self:Broadcast("state", self.state)
							for k, v in pairs(self.player) do
								if v:GetBet() then
									v.requestCard = true
									local time = (GetGameTimer() + Config["game_time"]["more_card_time"] * 1000)
									self:Broadcast("morecard_turn", {
										seat = k,
										state = true,
										dura = Config["game_time"]["more_card_time"]
									})
									while (v.requestCard and time > GetGameTimer()) do
										Citizen.Wait(10)
									end
								end
							end
							
							Citizen.Wait(500)
							
							local max_score = self:GetMaximumScoreFromPlayer()
							if deal[4] <= 5 then
								if deal[1] <= max_score then
									self:GiveDealerMoreCard()
								end
							elseif deal[4] > 5 then
								if deal[1] < max_score and math.random(1, 4) == 1 then
									self:GiveDealerMoreCard()
								end
							end
						end
							
						self:Broadcast("dealer_text", "กำลังนับคะแนน")
						self:Broadcast("dealer_closed")
						self:Timer(Config["game_time"]["calculate_time"], function()
							self.state = STATE_REVEAL
							self:Broadcast("state", self.state) self:
							endGameCalculate()
							self:Timer(Config["game_time"]["restart_time"], function()
								self.state = STATE_WAITING
								self:Broadcast("state", self.state)
								self:ResetCard()
								self:ResetPlayer()
							end)
						end)
					end)
				end)
			end)
		end

		tbl.GetMaximumScoreFromPlayer = function(self)
			local max = 0
			for k, v in pairs(self.player) do
				local bet = v:GetBet()
				if bet then
					
					local score, call, multiply = GetScore(v:GetCard())
					if max < score then
						max = score
					end
				end
			end
			return max
		end
		
		tbl.ban_list = {}
		tbl.KickPlayer = function(self, src)
			local ply, seat = self:GetPlayer(src)
			if ply == nil then
				return
			end
			
			if Config["kick_ban_time"] ~= nil and Config["kick_ban_time"] > 0 then
				self.ban_list[src] = GetGameTimer() + (Config["kick_ban_time"] * 1000)
			end
			
			self:OnPlayerLeave(src)
			TriggerClientEvent("scotty-cpk:fetchGame", src, self.id, "kickPlayer")
		end
		
		tbl.time_log = {}
		tbl.Timer = function(self, sec, cb)
			local exec_time = GetGameTimer() + (sec * 1000)
			table.insert(tbl.time_log, {exec_time = exec_time, cb = cb})
		end
		
		tbl.Think = function(self)
			if #self.time_log > 0 then
				
				for k, v in pairs(tbl.time_log) do
					if v.exec_time < GetGameTimer() then
						v.cb()
						table.remove(self.time_log, k)
					end
				end
			end
		end

		tbl.PassMoreCard = function(self, src)
			local ply, seat = self:GetPlayer(src)
			if ply == nil then
				return
			end
			ply.requestCard = false
		end

		tbl.RequestMoreCard = function(self, src)
			local ply, seat = self:GetPlayer(src)
			if ply == nil then
				return
			end
			ply.requestCard = false
			if ply:GetCard()[3] == nil then
				
				local card = self:RemoveRandomCard()
				ply:GiveCard(card)
				local cards = ply:GetCard()
				cards[3] = card
				local score, call, multiply = GetScore(cards)
				local data = {
					card3 = card,
					score = call
				}
				self:Broadcast("morecard_deal", {
					seat = seat,
					data = data,
					isply = true
				})
			end
		end
		
		tbl.GiveDealerMoreCard = function(self)
			local dealer_card = self.dealer_card
			if dealer_card[3] == nil then
				
				local card = self:RemoveRandomCard()
				table.insert(self.dealer_card, card)
				local cards = self.dealer_card
				cards[3] = card
				local score, call, multiply = GetScore(cards)
				local data = {
					card3 = card,
					score = call
				}
				self:Broadcast("morecard_deal", {
					seat = seat,
					data = data,
				})
			end
		end
		
		tbl.endGameCalculate = function(self)
			local dealer_score, dealer_call, dealer_multiply, dealer_total = GetScore(self.dealer_card)
			local result = {}
			for k, v in pairs(self.player) do
				local xPlayer = ESX.GetPlayerFromId(v.src)
				local bet = v:GetBet()
				if bet then
					
					local score, call, multiply, total_score = GetScore(v:GetCard())
					local r = 0

					if (dealer_score == 88 and total_score == 8 or dealer_score == 99 and total_score == 8) then
						r = 1 xPlayer.addMoney(bet)
					elseif score > dealer_score or (dealer_score >= 88 and score < 10 and dealer_total < total_score or score > 10) then
						r = 2
						local am = (bet * multiply)
						xPlayer.addMoney(bet + am)
						v.profit = v.profit + am
					elseif score == dealer_score then
						r = 1 xPlayer.addMoney(bet)
					else
						local am = (bet * (dealer_multiply - 1))
						if am > 0 then
							xPlayer.removeMoney(am)
							v.profit = v.profit - am - bet
						else
							v.profit = v.profit - bet
						end
					end
					
					result[k] = {
						seat = v.seat,
						score = score,
						multiply = multiply,
						call = call,
						result = r
					}
					v.kick_count = 0
				else
					v.kick_count = v.kick_count or 0
					v.kick_count = v.kick_count + 1
					if v.kick_count >= Config["kick_after_game"] then
						self:KickPlayer(v.src)
						TriggerClientEvent("pNotify:SendNotification", v.src, {
							text = string.format(Config["translate"]["kick_game"], Config["kick_after_game"]),
							type = "error",
							queue = "right",
							timeout = 5000,
							layout = "centerRight"
						})
					end
				end
						
				local money = xPlayer.getMoney()
				
				if money < self.minimum then
					self:KickPlayer(v.src)
					TriggerClientEvent("pNotify:SendNotification", v.src, {
						text = Config["translate"]["kick_minimum"],
						type = "error",
						queue = "right",
						timeout = 5000,
						layout = "centerRight"
					})
				end
			end
					
			self:Broadcast("result", {
				dealer = {
					score = dealer_score,
					call = dealer_call,
					multiply = dealer_multiply
				},
				player = result
			})
		end

		tbl.Broadcast = function(self, action, data)
			for k, v in pairs(self.player) do
				TriggerClientEvent("scotty-cpk:fetchGame", v.src, self.id, action, data)
			end
		end

		tbl.PlayerFetch = function(self, src)
			local data = {
				dealer = self:GetDealerCard(),
				player = self:GetPlayersData(),
				state = self.state,
			}
			TriggerClientEvent("scotty-cpk:fetchGame", src, self.id, "fetchGame", data)
		end

		tbl.GetPlayersData = function(self)
			local data = {}
			for k, v in pairs(self.player) do
				local card = v:GetCard()
				local score, call, multiply = GetScore(card)
				card[4] = call
				card[5] = multiply
				data[k] = {
					name = v:GetName(),
					bet = v:GetBet(),
					seat = v.seat,
					card = card
				}
			end
			return data
		end

		tbl.PlayerJoin = function(self, src)
			if #self.player >= total_player or self:IsPlayerAlreadyIn(src) then
				return
			end
			
			if self.ban_list and self.ban_list[src] and self.ban_list[src] > GetGameTimer() then
				
				local left = math.floor((self.ban_list[src] - GetGameTimer()) / 1000)
				TriggerClientEvent("pNotify:SendNotification", src, {
					text = string.format(Config["translate"]["ban_text"], left),
					type = "error",
					queue = "right",
					timeout = 5000,
					layout = "centerRight"
				})
				return
			end
			
			local xPlayer = ESX.GetPlayerFromId(src)
			local money = xPlayer.getMoney()
			if money < self.minimum then
				TriggerClientEvent("pNotify:SendNotification", src, {
					text = string.format(Config["translate"]["join_minimum"], self.minimum),
					type = "error",
					queue = "right",
					timeout = 5000,
					layout = "centerRight"
				})
				return
			end
			
			local ply = CreatePlayer(src)
			
			if ply == nil then
				return
			end
			self:PlayerFetch(src)
			local found
			for i = 1, 5 do
				if found == nil and self.player[i] == nil then
					found = i
					self.player[found] = ply
					self.player[found].seat = found
				end
			end
			self:Broadcast("player_join", {
				seat = found,
				src = src,
				name = ply:GetName()
			})
			TriggerClientEvent("scotty-cpk:fetchGame", -1, self.id, "playerCount", #self.player)
		end
		
		tbl.IsPlayerAlreadyIn = function(self, src)
			for k, v in pairs(self.player) do
				if v and v.src == src then
					return true
				end
			end
			return false
		end
		
		tbl.OnPlayerLeave = function(self, src)
			local found
			for i = 1, 5 do
				if self.player[i] and self.player[i].src == src then
					found = i
				end
			end
			if found then
				local ply = self.player[found]
				self:Broadcast("player_leave", {
					seat = found,
					src = src,
				})
				if ply.profit and ply.profit ~= 0 then
					if ply.profit < 0 then
						TriggerClientEvent("pNotify:SendNotification", src, {
							text = string.format(Config["translate"]["profit_report1"], string.Comma(ply.profit)),
							type = "error",
							queue = "right",
							timeout = 5000,
							layout = "centerRight"
						})
					else
						TriggerClientEvent("pNotify:SendNotification", src, {
							text = string.format(Config["translate"]["profit_report2"], string.Comma(ply.profit)),
							type = "success",
							queue = "right",
							timeout = 5000,
							layout = "centerRight"
						})
					end
				end
				self.player[found] = nil
			end
			
			TriggerClientEvent("scotty-cpk:fetchGame", -1, self.id, "playerCount", #self.player)
		end
		
		tbl.IsPlayerInside = function(self, src)
			for k, v in pairs(self.player) do
				if v.src == src then
					return true
				end
			end
			return false
		end
		
		tbl.GetPlayer = function(self, src)
			for k, v in pairs(self.player) do
				if v.src == src then
					return v, k
				end
			end
		end
		
		tbl.PlayerBet = function(self, src, amount)
			local ply, seat = self:GetPlayer(src)
			
			if ply == nil then
				return
			end
			
			if self.state ~= STATE_WAITING and self.state ~= STATE_START then
				return
			end
			
			local xPlayer = ESX.GetPlayerFromId(src)
			local money = xPlayer.getMoney()
			if money < amount then
				self:KickPlayer(src)
				TriggerClientEvent("pNotify:SendNotification", src, {
					text = Config["translate"]["kick_exploit"],
					type = "error",
					queue = "right",
					timeout = 5000,
					layout = "centerRight"
				})
				return
			else
				xPlayer.removeMoney(amount)
			end
			ply.requestCard = false 
			self:Start()
			ply:SetBet(amount)
			self:Broadcast("player_bet", {seat = seat, chip = amount})
		end
		
		tbl.GetDealerCard = function(self)
			local card = {}
			card[1] = self.dealer_card[1]
			card[2] = self.dealer_card[2]
			card[3] = self.dealer_card[3]
			local score, call, multiply = GetScore(self.dealer_card)
			card[4] = call
			card[5] = multiply
			card[6] = score
			return card
		end
		
		tbl.GetPlayerCard = function(self)
			local card = {}
			for k, v in pairs(self.player) do
				card[k] = v:GetCard()
				local score, call, multiply = GetScore(card[k])
				card[k][4] = call
				card[k][5] = multiply
			end
			return card
		end
		
		tbl.SplitCard = function(self)
			if self.destiny_draw and math.random(0, 100) <= self.destiny_draw then
				
				local rand = math.random(1, 2)
				if rand == 1 then
					local sym = math.random(0, 2)
					local num = math.random(8, 9)
					local king = math.random(10, 13)
					table.insert(self.dealer_card, {sym, king})
					table.insert(self.dealer_card, {sym, num})
					self:RemoveCard(sym, 10)
					self:RemoveCard(sym, num)
				elseif rand == 2 then
					local sym = math.random(0, 2)
					local sym2 = math.random(0, 2)
					local num = math.random(8, 9)
					local king = math.random(10, 13)
					table.insert(self.dealer_card, {sym, king})
					table.insert(self.dealer_card, {sym2, num})
					self:RemoveCard(sym, king)
					self:RemoveCard(sym2, num)
				end
			else
				table.insert(self.dealer_card, self:RemoveRandomCard())
				table.insert(self.dealer_card, self:RemoveRandomCard())
			end
			
			for k, v in pairs(self.player) do
				if v:GetBet() then
					v:GiveCard(self:RemoveRandomCard())
					v:GiveCard(self:RemoveRandomCard())
				end
			end
		end
			
		tbl.RemoveCard = function(self, sym, num)
			local card = self.card[sym]
			for k, v in pairs(card) do
				if v == num then
					table.remove(card, k)
					return
				end
			end
		end
			
		tbl.RemoveRandomCard = function(self)
			while true do Wait(0)
				local sym = math.random(0, 3)
				local card = self.card[sym]
				if #card > 0 then
					
					local key = math.random(1, #card)
					local card_to_remove = card[key]
					if card_to_remove ~= nil then
						table.remove(card, key)
						return {sym, card_to_remove}
					end
				end
			end
		end
		
		tbl.ResetCard = function(self)
			self.card = {
				[0] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13},
				[1] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13},
				[2] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13},
				[3] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13},
			}
		end
			
		tbl.ResetPlayer = function(self)
			self.dealer_card = {}
			for k, v in pairs(self.player) do
				v:Reset()
			end
		end

		return tbl
	end
	
	function CreatePlayer(src)
		local pl = {}
		pl.name = GetPlayerName(src)
		pl.src = src
		pl.card = {}
		pl.score = 0
		pl.bet = nil
		pl.profit = 0

		pl.GetName = function(self)
			return self.name
		end

		pl.GetCard = function(self)
			return self.card
		end
		
		pl.GiveCard = function(self, card)
			table.insert(self.card, card)
		end
		
		pl.Reset = function(self)
			self.card = {}
			self.score = 0
			self.bet = nil
		end
		
		pl.SetBet = function(self, amount)
			self.bet = amount
		end
		
		pl.GetBet = function(self, amount)
			return self.bet
		end
		
		return pl
	end
		
	for k,v in pairs(Config["desk"]) do
		table.insert(DESK_TABLE, CreateTable(v.name or "UNKNOWN", v.minimum or 1000, v.maximum or 10000, v.destiny_draw))
	end
	
	local scores = {[1] = 1, [2] = 2, [3] = 3, [4] = 4, [5] = 5, [6] = 6, [7] = 7, [8] = 8, [9] = 9, [10] = 10, [11] = 10, [12] = 10, [13] = 10, }
	local symbol = {[1] = "A", [2] = "2", [3] = "3", [4] = "4", [5] = "5", [6] = "6", [7] = "7", [8] = "8", [9] = "9", [10] = "10", [11] = "J", [12] = "Q", [13] = "K", }
		
	function GetScore(card)
		local c1 = card[1]
		local c2 = card[2]
		local c3 = card[3]
		if c1 == nil then
			return
		end
		local s1 = (c1[2] < 10 and c1[2] or 10)
		local s2 = (c2[2] < 10 and c2[2] or 10)
		local s3 = (c3 ~= nil and (c3[2] < 10 and c3[2] or 10) or 0)
		local deng = (c3 == nil and c1[1] == c2[1] or c3 ~= nil and c1[1] == c2[1] and c1[1] == c3[1] or false)
		local total_score = (s1 + s2 + s3) % 10
		local straight, straight_score = false, 0
		
		if c3 ~= nil then
			local hand = {c1[2], c2[2], c3[2]}

			table.sort(hand, function(a, b)
				return a < b
			end)

			local count, last = 1, -1

			for k, v in pairs(hand) do
				if v == 1 and hand[2] == 12 and hand[3] == 13 then
					straight = true
					straight_score = 50
					break
				elseif v == 1 and hand[2] == 2 and hand[3] == 3 then
					straight = false
					straight_score = 0
					break
				elseif last == (v - 1) then
					count = count + 1
				else
					count = 1
				end
				last = v
				straight_score = straight_score + v
			end

			if count >= 3 then
				straight = true
			end
		end
				
		local multi = Config["win_multiply"]
		local multiply = multi["default"]
		local score = 0
		local call = "UNKNOWN"
		
		if deng and total_score == 9 then
			score = 99
			multiply = multi["deng"] or multi["default"] or 2
			call = string.format(Config.translate["pok_deng_num"], 9)
		elseif deng and total_score == 8 then
			score = 88
			multiply = multi["deng"] or multi["default"] or 2
			call = string.format(Config.translate["pok_deng_num"], 8)
		elseif c3 ~= nil and (c1[2] == c2[2] and c1[2] == c3[2]) then
			score = 80
			multiply = multi["tong"] or multi["default"] or 5
			call = string.format(Config.translate["tong"], symbol[c1[2]])
			if c1[2] == 13 then
				score = score - 1
			elseif c1[2] == 12 then
				score = score - 2
			elseif c1[2] == 11 then
				score = score - 3
			elseif c1[2] == 10 then
				score = score - 4
			elseif c1[2] == 9 then
				score = score - 5
			elseif c1[2] == 8 then
				score = score - 6
			elseif c1[2] == 7 then
				score = score - 7
			elseif c1[2] == 6 then
				score = score - 8
			elseif c1[2] == 5 then
				score = score - 9
			elseif c1[2] == 4 then
				score = score - 10
			elseif c1[2] == 2 then
				score = score - 11
			elseif c1[2] == 1 then
				score = score - 12
			end
		elseif straight and deng then
			score = 50
			multiply = multi["royal_straight"] or multi["default"] or 5
			call = Config.translate["royal_straight"]
			score = score + ((straight_score / 100) * 10)
		elseif straight then
			score = 30
			multiply = multi["straight"] or multi["default"] or 3
			call = Config.translate["straight"]
			score = score + ((straight_score / 100) * 10)
		elseif c3 ~= nil and (c1[2] > 10 and c2[2] > 10 and c3[2] > 10) then
			score = 20
			multiply = multi["sean"] or multi["default"] or 3
			call = Config.translate["sean"]
		else
			score = total_score
			if deng then
				call = (total_score < 10 and total_score > 0 and string.format(total_score >= 8 and total_score < 10 and Config.translate["pok_deng_num"] or Config.translate["taem_deng_num"], total_score) or Config.translate["blind"]) multiply = multi["deng"] or multi["default"] or 2
			else
				call = (total_score < 10 and total_score > 0 and string.format(total_score >= 8 and total_score < 10 and Config.translate["pok_num"] or Config.translate["taem_num"], total_score) or Config.translate["blind"])
			end

			if total_score >= 10 and total_score <= 0 then
				score = 0
			end
		end

		return score, call, multiply, total_score
	end
					
	function pdebug(txt)
		print("[Pokdeng]", txt)
	end
					
	function string.Comma(number)
		if tonumber(number) then
			number = string.format("%f", number) number = string.match(number, "^(.-)%.?0*$")
		end

		local k

		while true do number, k = string.gsub(number, "^(-?%d+)(%d%d%d)", "%1,%2")
			if (k == 0) then
				break
			end
		end

		return number
	end
-- end
