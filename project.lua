require("credentials")
require("mqtconfig")
wifi.setmode(wifi.STATION)
wifi.sta.config(SSID,PASSWORD)

print("Fetching IP Address...")
tmr.alarm(1,10000, tmr.ALARM_SINGLE, function()
    myip = wifi.sta.getip()
    if myip~=nil then
        print(myip)
        mqttStart()    
    else
        print("Error in connecting to wifi")
    end
end) 

function publish_motionDetected()
    m:publish(ENDPOINT_MOTION,"1",0,0,function(client)
        print("TEMP and HUMI rec Detected. Sent 1 to MQTT")
    end
    )
end

function publish_keepalive()
    tmr.alarm(1,1000,tmr.ALARM_AUTO,function()
           m:publish("aliveMotion","alive",0,0,function(client)
                print("Keep alive message")
            end
            )
    end
    )
end

pin = 2

function motionDetection()
    print("1")
    tmr.alarm(0,5000,tmr.ALARM_AUTO,function()
    print("1")
    local status, temp, humi, temp_dec, humi_dec = dht.read(pin)
    print("1")
    if status == dht.OK then
        print("DHT temperature is: "..temp.."Humidity is: "..humi)
        publish_motionDetected()
        sendDataToThingSpeak(temp,humi)
        publish_motionDetected()
    elseif status == dht.ERROR_CHECKSUM then
        print("Checksum error")
    elseif status == dht.ERROR_TIMEOUT then
        print("Timeout error")    
    end   
end)    


function sendDataToThingSpeak(temp,humi)
    myip = wifi.sta.getip()
    print(myip)
    if myip~=nil then
        print("Sending data to thingspeak....")
        http.post('http://api.thingspeak.com/update',
        'Content-Type: application/json\r\n',
        '{"api_key":"8D7L8FLXSDX83U82","field1":'..temp..',"field2":'..humi..'}',
        function(code, data)
            if (code < 0) then
            print("HTTP request failed")
        else
            print(code, data)
        end
    end)
  
        else
          print("Not connected to wifi yet...")
        end    
  end

end


function mqttStart()
    m = mqtt.Client(CLIENTID1,120,"user3","password")
    m:connect(HOST,PORT,0,0,function(client)
        print("Connected...")
    end,
    function(client,reason)
        print("Reason..."..reason)
    end
    )
    m:on("message",function(client,topic,message)
        if message ~= nil then
            print(topic .. "  " .. message)
        end    
    end
    )

    m:on("offline", function(client)
        print("In offline mode")
       end 
       )
    m:on("connect", function(client)
        print("Connected")
        motionDetection()
        publish_keepalive()
    end 
    )

    m:lwt("/lwt","offline",0,0)
   
    
end