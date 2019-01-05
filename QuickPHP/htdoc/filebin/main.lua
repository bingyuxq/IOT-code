local reset = 7    --GPIO13，配置复位按钮，拉高进入配置模式
sda = 1	--sht20的配置
scl = 2	--sht20的配置
MQTTusername = "dev"
MQTTpassword = "dev"
clientID = node.chipid()..""
standbyTime = 60 --连续运行模式下的数据更新间隔，当启用休眠模式时为发出信息后的等待窗口时间
reportDelay = 240 --当启用休眠模式时的唤醒间隔间间隔，本延迟同时用于{mqtt发出lastwill}

dofile("telnet.lua")
if file.stat("EnableWebInterface")==nil then
	dofile("sht20.lua")
	dofile("mqtt.lua")
end

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
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function()
	print("STA_GOT_IP");
	if file.stat("EnableWebInterface")~=nil then
		dofile("web_init.lua")
	else
		initServer()
	end
end)
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
	
	--print("TRIGGER_TEMP_MEASURE_HOLD:" .. readValue(TRIGGER_TEMP_MEASURE_HOLD))
	--print("TRIGGER_HUMD_MEASURE_HOLD:" .. readValue(TRIGGER_HUMD_MEASURE_HOLD))
	
	
	onlineMsg=[[{"name":"sensor","msgType":"online","sensorTypeList":["temperature","humidity"],"clientID":"]]..clientID..[["}]]
	offlineMsg=[[{"name":"sensor","msgType":"offline","sensorTypeList":["temperature","humidity"],"clientID":"]]..clientID..[["}]]
	MQTTinit(clientID,MQTTusername,MQTTpassword,onlineMsg,offlineMsg)
	collectgarbage()
	
	tmr.alarm(0, standbyTime*1000, tmr.ALARM_AUTO,function()
		if file.stat("DeepsleepEnabled")~=nil then
			sleepDelay = tmr.create()
			sleepDelay:register(standbyTime*1000, tmr.ALARM_SINGLE,function()
				print("getting into deepsleep mode")
				node.dsleep(1000000*reportDelay)
			end)
			sleepDelay:start()
		end
		
		print("uploading data to server")
		msgID1=node.random(4294967295)
		payload=[[{"name":"sensor","msgType":"uploadData","sensorType":"temperature","clientID":"]]..clientID..[[","data":"]]..readValue(TRIGGER_TEMP_MEASURE_HOLD)..[[","msgID":"]]..msgID1..[["}]]
		MQTTpublic("MQTT_Client",payload)
		msgID2=node.random(4294967295)
		payload=[[{"name":"sensor","msgType":"uploadData","sensorType":"humidity","clientID":"]]..clientID..[[","data":"]]..readValue(TRIGGER_HUMD_MEASURE_HOLD)..[[","msgID":"]]..msgID2..[["}]]
		MQTTpublic("MQTT_Client",payload)
	end)
end