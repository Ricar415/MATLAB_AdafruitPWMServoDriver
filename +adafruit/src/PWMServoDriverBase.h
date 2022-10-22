/**
 * @file PWMServoDriver.h
 *
 * Class definition for PWMServoDriver class that wraps APIs of Adafruit PWM Servo Driver library
 *
 */

#include "LibraryBase.h"
#include "Adafruit_PWMServoDriver.h"

#define MIN_I2C 0x40
#define MAX_I2C 0x80

#ifdef MW_UNO_SHIELDS
#define MAX_DRIVERS 4
#else
#define MAX_DRIVERS 32
#endif

#define CREATE_SERVO_DRIVER     0x00
#define DELETE_SERVO_DRIVER     0x01
#define SET_PWM                 0x02
#define SET_PWM_FREQ            0x03
#define SLEEP                   0x04
#define WAKEUP                  0x05
#define RESET                   0x06

// Arduino trace commands
const char MSG_MSV2_CREATE_SERVO_DRIVER[]        PROGMEM = "Adafruit::ASD[%d] = new Adafruit_PWMServoDriver(%d)->begin();\n";
const char MSG_MSV2_DELETE_SERVO_DRIVER[]        PROGMEM = "Adafruit::delete ASD[%d];\n";
const char MSG_MSV2_SET_PWM[]                    PROGMEM = "Adafruit::ASD[%d]->setPWM(%d,%d,%d);\n";
const char MSG_MSV2_SET_PWM_FREQ[]               PROGMEM = "Adafruit::ASD[%d]->setPWMFreq(%d);\n";
const char MSG_SLEEP[]                           PROGMEM = "Adafruit::ASD[%d]->sleep();\n";
const char MSG_WAKEUP[]                          PROGMEM = "Adafruit::ASD[%d]->wakeup();\n";
const char MSG_RESET[]                           PROGMEM = "Adafruit::ASD[%d]->reset();\n";

Adafruit_PWMServoDriver *ASD[MAX_DRIVERS];

class AdafruitServoDriverTrace {
public:
    static void createServoDriver(byte driverNum, byte i2caddress, unsigned int pwmfreq) {
        if(driverNum < MAX_DRIVERS){
            if (NULL != ASD[driverNum]) {
                delete(ASD[driverNum]);
                ASD[driverNum] = NULL;
            }
            ASD[driverNum] = new Adafruit_PWMServoDriver(i2caddress);
            ASD[driverNum]->begin();
            ASD[driverNum]->setPWMFreq(pwmfreq);
            debugPrint(MSG_MSV2_CREATE_SERVO_DRIVER, driverNum, i2caddress);
            debugPrint(MSG_MSV2_SET_PWM_FREQ, driverNum, pwmfreq);
        }
    }
    
    static void deleteServoDriver(byte driverNum) {
        if(driverNum < MAX_DRIVERS){
            delete ASD[driverNum];
            ASD[driverNum] = NULL;
            debugPrint(MSG_MSV2_DELETE_SERVO_DRIVER, driverNum);
        }
    }

    static void set_pwm(byte driverNum, unsigned int num, unsigned int on, unsigned int off) {
        if(driverNum < MAX_DRIVERS){
            ASD[driverNum]->setPWM(num,on,off);
            debugPrint(MSG_MSV2_SET_PWM, driverNum, num, on, off);
        }
    }

    static void set_pwm_freq(byte driverNum, unsigned int pwmfreq) {
        if(driverNum < MAX_DRIVERS){
            ASD[driverNum]->setPWMFreq(pwmfreq);
            debugPrint(MSG_MSV2_SET_PWM_FREQ, driverNum, pwmfreq);
        }
    }

    static void sleep(byte driverNum){
        if(driverNum < MAX_DRIVERS){
            ASD[driverNum]->sleep();
            debugPrint(MSG_SLEEP, driverNum);
        }
    }

    static void wakeup(byte driverNum){
        if(driverNum < MAX_DRIVERS){
            ASD[driverNum]->wakeup();
            debugPrint(MSG_WAKEUP, driverNum);
        }
    }

    static void reset(byte driverNum){
        if(driverNum < MAX_DRIVERS){
            ASD[driverNum]->reset();
            debugPrint(MSG_RESET, driverNum);
        }
    }
};

class PWMServoDriverBase : public LibraryBase
{
	public:
		PWMServoDriverBase(MWArduinoClass& a)
		{
            libName = "Adafruit/PWMServoDriver";
			a.registerLibrary(this);
		}
        
        void setup(){
            for (int i = 0; i < MAX_DRIVERS; ++i) {
                ASD[i] = NULL;
            }
        }
		
	public:
		void commandHandler(byte cmdID, byte* dataIn, unsigned int payloadSize)
		{
            switch (cmdID){
                case CREATE_SERVO_DRIVER:{
                    byte driverNum = dataIn[0];
                    byte i2caddress = dataIn[1];
                    unsigned int pwmfreq = dataIn[2]+(dataIn[3]<<8);
                    AdafruitServoDriverTrace::createServoDriver(driverNum, i2caddress, pwmfreq) ;
                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case DELETE_SERVO_DRIVER:{ 
                    byte driverNum = dataIn[0];
                    AdafruitServoDriverTrace::deleteServoDriver(driverNum);
                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case SET_PWM:{
                    byte driverNum = dataIn[0];
                    unsigned int num = dataIn[1];
                    unsigned int on = dataIn[2]+(dataIn[3]<<8);
                    unsigned int off = dataIn[4]+(dataIn[5]<<8);
                    AdafruitServoDriverTrace::set_pwm(driverNum, num, on, off);
                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case SET_PWM_FREQ:{
                    byte driverNum = dataIn[0];
                    unsigned int pwmFreq = dataIn[1]+(dataIn[2]<<8);
                    AdafruitServoDriverTrace::set_pwm_freq(driverNum, pwmFreq);
                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case SLEEP:{
                    byte driverNum = dataIn[0];
                    AdafruitServoDriverTrace::sleep(driverNum);
                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case WAKEUP:{
                    byte driverNum = dataIn[0];
                    AdafruitServoDriverTrace::wakeup(driverNum);
                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case RESET:{
                    byte driverNum = dataIn[0];
                    AdafruitServoDriverTrace::reset(driverNum);
                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                default:
					break;
            }
		}
};