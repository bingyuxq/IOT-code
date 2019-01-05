local m = mqtt.Client(clientID, reportDelay+10, MQTTusername, MQTTpassword)
--传感器模块相关，测温、测湿度

function MQTTinit(clientID, MQTTusername, MQTTpassword, onlineMsg, offlineMsg)
	--m:close()
	m:on("connect", function(client) print ("mqtt connection ON") end)
	m:on("offline", function(client)
		print ("offline")
		-- tmr.start(0)
	end)
	m:lwt("MQTT_Client", offlineMsg, 0, 0)
	
	m:connect("192.168.1.1", 1883, 0,
            function(client)
                print("mqtt connected")
                -- m:subscribe("homebridge/from/set",0, function(client) print("subscribe homebridge command success") end)    --订阅控制主题信息
                m:publish("MQTT_Client", onlineMsg, 0, 0)      --注册设备
				MQTTListener()	--启动对C&C服务器的指令监听
            end, 
            function(client, reason)
                print("failed reason: "..reason)
                --node.restart()
				m:close()
            end
        )
end

function MQTTpublic(topic, messsage)
	return(m:publish(topic, messsage, 0, 0))
end

function MQTTListener()
	m:on("message", function(client, topic, data) 
	--{"name":"master","msgType":"command","targetID":"chipid或all","targetItem":"设备类型或all","payload":"xxxxxxxxxxxxxxxxxxxxxx","msgID":"msgID"}
	  if data ~= nil then
		t = sjson.decode(data)
		if t["name"] == "master" and t["msgType"] == "command" and (t["targetID"] == clientID or t["targetID"] == "all") then
			print("command received!")
			commandHandle(t)
		end
	  end
	end)
	
	m:subscribe("MQTT_Master",0, function(client) print("subscribe C&C topic success") end)    --订阅控制主题信息
end

function commandHandle(payload)
	if payload["payload"] == "enable deepsleep" then
		if file.stat("DeepsleepEnabled")==nil then
			dest = file.open("DeepsleepEnabled", "w")
			dest:close(); dest = nil
		end
		if file.stat("DeepsleepEnabled")~=nil then
			msgID=node.random(4294967295)
			msgReturn = [[{"msgType":"msgReturn","clientID":"]]..clientID..[[","calllbackMsgID":"]]..payload["msgID"]..[[","msgID":"]]..msgID..[[","status":"success"}]]
			MQTTpublic("MQTT_Client", msgReturn)
		else
			msgID=node.random(4294967295)
			msgReturn = [[{"msgType":"msgReturn","clientID":"]]..clientID..[[","calllbackMsgID":"]]..payload["msgID"]..[[","msgID":"]]..msgID..[[","status":"fail"}]]
			MQTTpublic("MQTT_Client", msgReturn)
		end
	end
	if payload["payload"] == "disable deepsleep" then
		if file.stat("DeepsleepEnabled")~=nil then
			file.remove("DeepsleepEnabled")
		end
		if file.stat("DeepsleepEnabled")==nil then
			msgID=node.random(4294967295)
			msgReturn = [[{"msgType":"msgReturn","clientID":"]]..clientID..[[","calllbackMsgID":"]]..payload["msgID"]..[[","msgID":"]]..msgID..[[","status":"success"}]]
			MQTTpublic("MQTT_Client", msgReturn)
		else
			msgID=node.random(4294967295)
			msgReturn = [[{"msgType":"msgReturn","clientID":"]]..clientID..[[","calllbackMsgID":"]]..payload["msgID"]..[[","msgID":"]]..msgID..[[","status":"fail"}]]
			MQTTpublic("MQTT_Client", msgReturn)
		end
	end
	
end

collectgarbage()
--m:lwt("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-"..m_name.."\", \"reachable\": false}", 0, 0)
