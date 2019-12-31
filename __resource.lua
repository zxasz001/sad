--[[
	resource: scotty-casino-pokdeng
	desc: ชุดคาสิโน God of Gambler ของ Scotty ในชุด ป๊อกเด้ง
	author: Scotty1944
	contact: https://www.facebook.com/Scotty1944/
	warning: หากนำไปขายต่อหรือแจกจ่าย หรือใช้ร่วมกันเกิน 1 server จะถูกยกเลิก license ทันที
]]

resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'Scotty Casino: Pokdeng'

files {
	'stream/sarabun.gfx',
	'stream/vw_prop_casino_blckjack_01.ydr',
	'stream/vw_prop_casino_tables.ytd',
	'stream/vw_prop_casino_tables+hi.ytd',
	'stream/casino.ytyp',
	
	'html/menu.html',
	'html/css/style.css',
	'html/css/scotty.css',
	'html/js/script.js',
	'html/js/scotty.js',
	'html/js/jquery-3.1.0.min.js',
	'html/js/howler.core.js',
	'html/fonts/OpenSans-Light.ttf',
	'html/fonts/SFProText-Regular.ttf',
	'html/fonts/THSarabunNew.ttf',
	'html/images/person.png',
	
	-- SOUND
	'html/sound/cardFan1.wav',
	'html/sound/cardSlide1.wav',
	'html/sound/cardSlide2.wav',
	'html/sound/cardSlide3.wav',
	'html/sound/cardSlide4.wav',
	'html/sound/cardSlide5.wav',
	'html/sound/cardSlide6.wav',
	'html/sound/cardSlide7.wav',
	'html/sound/cardSlide8.wav',
	'html/sound/chipsHandle.wav',
	'html/sound/chipsHandle1.wav',
	'html/sound/chipsHandle2.wav',
	'html/sound/chipsHandle3.wav',
	'html/sound/chipsHandle4.wav',
	-- CARD
	'html/images/card/0_1.png',
	'html/images/card/0_10.png',
	'html/images/card/0_11.png',
	'html/images/card/0_12.png',
	'html/images/card/0_13.png',
	'html/images/card/0_2.png',
	'html/images/card/0_3.png',
	'html/images/card/0_4.png',
	'html/images/card/0_5.png',
	'html/images/card/0_6.png',
	'html/images/card/0_7.png',
	'html/images/card/0_8.png',
	'html/images/card/0_9.png',
	'html/images/card/1_1.png',
	'html/images/card/1_10.png',
	'html/images/card/1_11.png',
	'html/images/card/1_12.png',
	'html/images/card/1_13.png',
	'html/images/card/1_2.png',
	'html/images/card/1_3.png',
	'html/images/card/1_4.png',
	'html/images/card/1_5.png',
	'html/images/card/1_6.png',
	'html/images/card/1_7.png',
	'html/images/card/1_8.png',
	'html/images/card/1_9.png',
	'html/images/card/2_1.png',
	'html/images/card/2_10.png',
	'html/images/card/2_11.png',
	'html/images/card/2_12.png',
	'html/images/card/2_13.png',
	'html/images/card/2_2.png',
	'html/images/card/2_3.png',
	'html/images/card/2_4.png',
	'html/images/card/2_5.png',
	'html/images/card/2_6.png',
	'html/images/card/2_7.png',
	'html/images/card/2_8.png',
	'html/images/card/2_9.png',
	'html/images/card/3_1.png',
	'html/images/card/3_10.png',
	'html/images/card/3_11.png',
	'html/images/card/3_12.png',
	'html/images/card/3_13.png',
	'html/images/card/3_2.png',
	'html/images/card/3_3.png',
	'html/images/card/3_4.png',
	'html/images/card/3_5.png',
	'html/images/card/3_6.png',
	'html/images/card/3_7.png',
	'html/images/card/3_8.png',
	'html/images/card/3_9.png',
	'html/images/card/back.png',
}

data_file 'DLC_ITYP_REQUEST' 'stream/casino.ytyp'

ui_page {
	'html/menu.html'
}

client_scripts {
	'config.lua',
	'client.lua',
}

server_scripts {
	'config.lua',
	'config_sv.lua',
	'server.lua'
}