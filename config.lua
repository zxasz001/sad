--[[
file: config.lua
resource: scotty-casino-pokdeng
author: Scotty1944
contact: https://steamcommunity.com/id/scotty1944/
warning: หากนำไปขายต่อหรือแจกจ่าย หรือใช้ร่วมกันเกิน 1 server จะถูกยกเลิก license ทันที
]]

Config = Config or {}

Config["developer"] = true -- ตั้งไว้ true เพื่อทำให้ใช้คำสั่ง sc_pokdeng บน console ได้
Config["dealer_pok_allow_more_card"] = false -- ถ้าเจ้ามือได้ป๊อกเด้งจะเปิดให้แจกไพ่เพิ่มไหม ?

Config["kick_after_game"] = 3 -- หากไม่ลงเดิมพันใน X เกมส์จะถูกเตะออกจากโต๊ะ
Config["kick_no_chip"] = true -- หากชิปไม่พอที่จะลงเดิมพันจะเตะออกจากโต๊ะ
Config["kick_ban_time"] = 30 -- หากโดนเตะออกจากโต๊ะจะโดนแบนไม่ให้ใช้งานกี่วินาที

Config["desk"] = {
    {
        name = "~y~โต๊ะป๊อกเด้ง 1", -- ชื่อโต๊ะป๊อกเด้ง
        position = {x = -1461.83, y = 165.95, z = 54.89, h = 298.62}, -- ที่ตั้งของโต๊ะสามารถใช้ sc_pokdeng จะเสกโต๊ะขึ้นมา 5 วิแล้วก๊อปที่อยู่ลง Clipboard ให้ (ใช้ Ctrl + V วางได้เลย)
        minimum = 100, -- เดิมพันขั้นต่ำ (ต้องใส่)
        maximum = 500, -- เดิมพันสูงสุด (ต้องใส่)
        destiny_draw = 20, -- กี่เปอร์เซ็นที่ เจ้ามือ (บอท) จะทำการจั่วการ์ดแห่งโชคชะตา (จะทำให้จั่วได้ไพ่ดีจากบนกองเช่นเจ้ามือจั่วได้ป๊อก 9 ทันที)
        map_blip = true, -- โชว์ blip บนแมพหรือไม่
        blip_id = 431, -- blip id สำหรับเปลี่ยน icon
        blip_scale = 0.5, -- ขนาดของ blip,
        blip_name = "Pok Deng Table", -- คำอธิบาย Blip ในแมพ ควรเป็นภาษาอังกฤษ
    },
    {
        name = "~y~โต๊ะป๊อกเด้ง 2",
        position = {x = -1472.06, y = 164.68, z = 54.85, h = 339.85},
        minimum = 1000,
        maximum = 30000,
        map_blip = true
    },
    {
        name = "~y~โต๊ะป๊อกเด้ง 3",
        position = {x = -1475.64, y = 174.25, z = 54.92, h = 293.21},
        minimum = 10000,
        maximum = 100000,
        map_blip = true
    }}
    Config["win_multiply"] = {-- ปรับอัตราคูณชิปเดิมพัน
        default = 1, -- ค่าเริ่มต้น
        deng = 2, -- สองเด้ง
        tong = 5, -- ตอง
        royal_straight = 5, -- โรยัล สเตท
        straight = 3, -- สเตท
        sean = 3 -- เซียน
    }
    Config["game_time"] = {-- ปรับเวลาการเดินเกมส์
        wait_time = 10, -- เวลารอก่อนที่จะเริ่มแจกไพ่
        deal_time = 15, -- deal time in js is 7 sec
        more_card_time = 5, -- เวลารอในแต่ละรอบที่แจกไพ่เพิ่มเติมของแต่ละคน
        calculate_time = 3, -- เวลานับแต้มห้ามลบออก
        restart_time = 10, -- เวลาก่อนที่โต๊ะจะ reset ใหม่
    }
    Config["translate"] = {
        taem_num = "แต้ม %s",
        taem_deng_num = "แต้ม %s สองเด้ง",
        pok_num = "ป๊อก %s",
        pok_deng_num = "ป๊อก %s สองเด้ง",
        sean = "เซียน",
        straight = "สเตรท",
        royal_straight = "สเตรทฟลัช",
        tong = "ตอง %s",
        blind = "บอด",
        ban_text = "คุณพึ่งถูกเตะออกจากโต๊ะกรุณารออีก %d วินาที",
        kick_game = "คุณถูกเตะออกจากโต๊ะเนื่องจากไม่ลงเดิมพันภายใน %d เกม",
        kick_minimum = "คุณถูกเตะออกจากโต๊ะเนื่องจากชิปเดิมพันไม่พอกับขั้นต่ำ",
        kick_exploit = "คุณทำอะไรน่ะ !?",
        player_count = "จำนวนผู้เล่น %d/%d",
        join_minimum = "ต้องมีชิปขั้นต่ำ $%d ในการเล่นโต๊ะนี้",
        profit_report1 = "คุณเสียเงินไป $%s กับโต๊ะตัวนี้",
        profit_report2 = "คุณได้รับกำไรมา $%s กับโต๊ะตัวนี้",
    }

   