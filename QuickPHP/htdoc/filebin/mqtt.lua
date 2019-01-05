local m = mqtt.Client(clientID, timeout, MQTTusername, MQTTpassword)

function MQTTinit(clientID, MQTTusername, MQTTpassword)
	m:close()
	m:on("connect", function(client) print ("mqtt connection ON") end)
	m:on("offline", function(client)
		print ("offline")
		-- tmr.start(0)
	end)
	m:connect("192.168.1.1", 1883, 0,
            function(client)
                print("mqtt connected")
                -- m:subscribe("homebridge/from/set",0, function(client) print("subscribe homebridge command success") end)    --订阅控制主题信息
                m:publish("homebridge/to/add", "{\"name\": \""..clientID.."\", \"service\": \"servername\"}", 0, 0)      --注册设备
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

collectgarbage()
--m:lwt("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-"..m_name.."\", \"reachable\": false}", 0, 0)
