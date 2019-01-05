local reset = 7    --GPIO13，配置复位按钮，拉高进入配置模式
sda = 1	--sht20的配置
scl = 2	--sht20的配置
MQTTusername = "dev"
MQTTpassword = "dev"
clientID = node.chipid()..""
timeout = 300

dofile("telnet.lua")
dofile("sht20.lua")
dofile("mqtt.lua")

wifi.setmode(wifi.STATION)
wifi.sta.connect()

gpio.mode(reset, gpio.INT)    --初始化复位按钮为输入模式
if gpio.read(reset) == 1 then
    print("reset wifi config!")
    --node.restore()
    --node.restart()
end

print("eventMonReg initing")
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function() print("STA_CONNECTED") end)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function() print("STA_DISCONNECTED") end)
wifi.eventmon.register(wifi.eventmon.STA_AUTHMODE_CHANGE, function() print("STA_AUTHMODE_CHANGE") end)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function() print("STA_GOT_IP");initServer(); end)
wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, function() print("STA_DHCP_TIMEOUT") end)


if(wifi.sta.getconfig(true).pwd ==nil) then
	wifi.setmode(wifi.STATION)
	wifi.startsmart(0,
		function(ssid, password)
			 print(string.format("Success. SSID:%s ; PASSWORD:%s", ssid, password))
			 wifi.sta.config({ ssid = ssid,pwd = password})
			 node.restart()
		 end )
end

function initServer()
	print("init network Server!");
	
	print("TRIGGER_TEMP_MEASURE_HOLD:" .. readValue(TRIGGER_TEMP_MEASURE_HOLD))
	print("TRIGGER_HUMD_MEASURE_HOLD:" .. readValue(TRIGGER_HUMD_MEASURE_HOLD))
	
	MQTTinit(clientID,MQTTusername,MQTTpassword)
	collectgarbage()

	tmr.alarm(0, 10*1000, tmr.ALARM_AUTO,function()
		MQTTpublic("TEMP",readValue(TRIGGER_TEMP_MEASURE_HOLD))
		MQTTpublic("HUMD",readValue(TRIGGER_HUMD_MEASURE_HOLD))
	end)
end

initServer()
