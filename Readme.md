# Adafruit PWM Servo Driver for MATLAB

Custom MATLAB Add-on for AdafruitPWMServoDriver for Arduino

To use, install Adafruit_PWM_Servo_Driver_Library in your Arduino path and run the following:

```MATLAB
addpath('XXXX')
a = arduino('COM5','Uno','Libraries','Adafruit/PWMservoDriver')
shield = addon(a,'Adafruit/PWMservoDriver','I2CAddress','0x40')

```

To find the I2CAddess of your board:
```MATLAB
i2cAddress = scanI2CBus(controller)
```
<sub>
&nbsp;&nbsp;&nbsp;&nbsp;i2cAddresses = <br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1×2 string array<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'0x40'    '0x53'
</sub>

<br><br>
To find the port number of your board:<br>
https://www.mathworks.com/help/supportpkg/arduinoio/ug/find-arduino-port-on-windows-mac-and-linux.html
    

## List of the available functions

All the functions of the Adafruit library are available in the addon with the same sintax as the original library. <br>For more detailed information, please visit the official library page:
https://github.com/adafruit/Adafruit-PWM-Servo-Driver-Library

| Function                                                                          | Description                                                   | Return value        |    
| :---                                                                              |    :-----                                                     |              :---   |
| ```createServoDriver(byte driverNum, byte i2caddress)```                               | Creates the Servo Driver class. <br>driverNum used to reference the specific driver (for series<br> I2C connection. Maximum 4 in Arduino Uno and 32 else). <br>i2caddress used to reference the I2CAddress of the device ('0x40' - '0x80').                                | void                |
| ```deleteServoDriver(byte driverNum)```                                                 | Setups the I2C interface and hardware                         | void                |
| ```begin(byte driverNum, unsigned int prescale)```                                      | Setups the I2C interface and hardware                         | void                |
| ```reset(byte driverNum)```                                                             | Sends a reset command to the PCA9685 chip over I2C            | void                |
| ```sleep(byte driverNum)```                                                             | Puts board into sleep mode                                    | void                |
| ```wakeup(byte driverNum)```                                                            | Wakes board from sleep                                        | void                |
| ```setExtClk(byte driverNum, unsigned int prescale)```                                  | Sets EXTCLK pin to use the external clock                     | void                |
| ```setPWMFreq(byte driverNum, unsigned int pwmfreq)```                                  | Sets the PWM frequency for the entire chip, up to ~1.6 KHz    | void                |
| ```setOutputMode(byte driverNum, bool totempole)```                                     | Sets the output mode of the PCA9685 to either open drain or<br>push pull / totempole.<br> **Warning:** LEDs with integrated zener diodes should only<br>be driven in open drain mode    | void                |   
| ```getPWM(byte driverNum, unsigned int num)```                                          | Gets the PWM output of one of the PCA9685 pins num(0-15)      | unsigned int        |
| ```setPWM(byte driverNum, unsigned int num, unsigned int on, unsigned int off)```      | Sets the PWM output of one of the PCA9685 pins num(0-15)<br>with on/off tick placement and properly handles a zero value<br>as completely off and 4095 as completely on.       | void                | 
| ```readPrescale(byte driverNum)```       | Reads set Prescale from PCA9685                               | unsigned int        |
| ```writeMicroseconds(byte driverNum, unsigned int num, unsigned int microseconds)```  | Sets the PWM output of one of the PCA9685 pins based on the<br>input microseconds, output is not precise num(0-15)   | void                |
| ```setOscillatorFrequency(byte driverNum, unsigned int oscFreq)```                   | Setter for the internally tracked oscillator used for freq<br>calculations    | void                |
| ```getOscillatorFrequency(byte driverNum)```                              | Getter for the internally tracked oscillator used for freq<br>calculations    | unsigned int        |

Adafruit PWM Servo Driver: https://www.adafruit.com/product/815
<br>The addon and the library have been tried both with the official Adafruit 12-Channel 16-bit PWM LED Driver - SPI Interface - TLC59711 and with generic PCA9685 PWM LED and Servo drivers as well.
