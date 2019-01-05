dofile("ZZMathBit.lua")


-- #define ERROR_I2C_TIMEOUT                     998
-- #define ERROR_BAD_CRC                         999
-- #define SLAVE_ADDRESS                         0x40 
-- #define TRIGGER_TEMP_MEASURE_HOLD             0xE3
-- #define TRIGGER_HUMD_MEASURE_HOLD             0xE5
-- #define TRIGGER_TEMP_MEASURE_NOHOLD           0xF3
-- #define TRIGGER_HUMD_MEASURE_NOHOLD           0xF5
-- #define WRITE_USER_REG                        0xE6
-- #define READ_USER_REG                         0xE7
-- #define SOFT_RESET                            0xFE
-- #define USER_REGISTER_RESOLUTION_MASK         0x81
-- #define USER_REGISTER_RESOLUTION_RH12_TEMP14  0x00
-- #define USER_REGISTER_RESOLUTION_RH8_TEMP12   0x01
-- #define USER_REGISTER_RESOLUTION_RH10_TEMP13  0x80
-- #define USER_REGISTER_RESOLUTION_RH11_TEMP11  0x81
-- #define USER_REGISTER_END_OF_BATTERY          0x40
-- #define USER_REGISTER_HEATER_ENABLED          0x04
-- #define USER_REGISTER_DISABLE_OTP_RELOAD      0x02
-- #define MAX_WAIT                              100
-- #define DELAY_INTERVAL                        10
-- #define SHIFTED_DIVISOR                       0x988000

ERROR_BAD_CRC = 999
SLAVE_ADDRESS = 0x40	--x1000000,前面7位是地址
TRIGGER_TEMP_MEASURE_HOLD = 0xE3
TRIGGER_HUMD_MEASURE_HOLD = 0xE5
TRIGGER_TEMP_MEASURE_NOHOLD = 0xF3
TRIGGER_HUMD_MEASURE_NOHOLD = 0xF5
WRITE_USER_REG = 0xE6	--配置寄存器写地址
READ_USER_REG = 0xE7	--配置寄存器读地址
SOFT_RESET = 0xFE
USER_REGISTER_RESOLUTION_MASK = 0x81
USER_REGISTER_RESOLUTION_RH12_TEMP14 = 0x00
USER_REGISTER_RESOLUTION_RH8_TEMP12 = 0x01
USER_REGISTER_RESOLUTION_RH10_TEMP13 = 0x80
USER_REGISTER_RESOLUTION_RH11_TEMP11 = 0x81
USER_REGISTER_END_OF_BATTERY = 0x40
USER_REGISTER_HEATER_ENABLED = 0x04
USER_REGISTER_DISABLE_OTP_RELOAD = 0x02
SHIFTED_DIVISOR = 0x988000

i2c.setup(0, sda, scl, i2c.SLOW)

local function num_to_str(val, mult)
	local sign = ""
	if val < 0 then
		val = -val
		sign = "-"
	end
	local v1 = val/mult
	local v2 = (val/(mult/1000))%1000
	local res = string.format("%d.%03d", v1, v2)
	return sign..res
end

local function checkCRC(message_from_sensor, check_value_from_sensor)
	remainder = ZZMathBit.lShiftOp(message_from_sensor, 8)
	remainder = ZZMathBit.orOp(remainder, check_value_from_sensor)
	divsor = SHIFTED_DIVISOR
	for i =1,15 do
		if(ZZMathBit.andOp(remainder, ZZMathBit.lShiftOp(1,23-i))>0) then
			remainder = ZZMathBit.xorOp(remainder, divsor)
		end
		divsor = ZZMathBit.rShiftOp(divsor, 1)
	end
	return(remainder)
end

function readValue(cmd)
    i2c.start(0)
    i2c.address(0, SLAVE_ADDRESS, i2c.TRANSMITTER)
    i2c.write(0, cmd)
    i2c.stop(0)
    i2c.start(0)
    i2c.address(0, SLAVE_ADDRESS, i2c.RECEIVER)
	c = i2c.read(0, 2)
	--print(checkCRC(string.byte(c,1)*0xff +string.byte(c,2), string.byte(c,3)))
    i2c.stop(0)
	if(cmd == TRIGGER_TEMP_MEASURE_HOLD) then
		return(bit.band(0xfff0,(string.byte(c,1)*255+string.byte(c,2))) * (175.72 / 65536.0)-46.85)
	elseif(cmd == TRIGGER_HUMD_MEASURE_HOLD) then
		return(bit.band(0xfff0,(string.byte(c,1)*255+string.byte(c,2))) * (125.0 / 65536.0)-6)
	else
		return(0)
	end
end
local function readUserRegister()
    i2c.start(0)
    i2c.address(0, SLAVE_ADDRESS, i2c.TRANSMITTER)
    i2c.write(0, READ_USER_REG)
    i2c.stop(0)
    i2c.start(0)
    i2c.address(0, SLAVE_ADDRESS, i2c.RECEIVER)
    c = i2c.read(0, 1)
    i2c.stop(0)
    return c
end

local function writeUserRegister(val)
    i2c.start(0)
    i2c.address(0, SLAVE_ADDRESS, i2c.TRANSMITTER)
    i2c.write(0, WRITE_USER_REG)
    i2c.write(0, val)
    i2c.stop(0)
	
	
end

local function setResolution(resolution)
	userRegister = readUserRegister()
	userRegister = bit.band(string.byte(userRegister), 0x7e)
	userRegister = bit.bor(userRegister,resolution)
	writeUserRegister(userRegister);
end

local function checkSHT20()
	local reg = string.byte(readUserRegister())
	print(reg)
	print("End of battery: " .. bit.band(reg,USER_REGISTER_END_OF_BATTERY))
	print("Heater enabled: " .. bit.band(reg,USER_REGISTER_HEATER_ENABLED))
	print("Disable OTP reload: " .. bit.band(reg,USER_REGISTER_DISABLE_OTP_RELOAD))
	print("TRIGGER_TEMP_MEASURE_HOLD:" .. readValue(TRIGGER_TEMP_MEASURE_HOLD))
	print("TRIGGER_HUMD_MEASURE_HOLD:" .. readValue(TRIGGER_HUMD_MEASURE_HOLD))
end

--checkSHT20()
setResolution(USER_REGISTER_RESOLUTION_RH12_TEMP14)

collectgarbage()
