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

#define CREATE_SERVO_DRIVER         0x00
#define DELETE_SERVO_DRIVER         0x01
#define BEGIN                       0x02
#define RESET                       0x03
#define SLEEP                       0x04
#define WAKEUP                      0x05
#define SET_EXT_CLK               0x06
#define SET_PWM_FREQ                0x07
#define SET_OUTPUT_MODE             0x08
#define GET_PWM                     0x09
#define SET_PWM                     0x0A
#define SET_PIN                     0x0B
#define READ_PRESCALE               0x0C
#define WRITE_MICROSECONDS          0x0D
#define SET_OSCILLATOR_FREQUENCY    0x0E
#define GET_OSCILLATOR_FREQUENCY    0x0F

// Arduino trace commands
const char MSG_PSD_CREATE_SERVO_DRIVER[]                PROGMEM = "Adafruit::ASD[%d] = new Adafruit_PWMServoDriver(%d);\n";
const char MSG_PSD_DELETE_SERVO_DRIVER[]                PROGMEM = "Adafruit::delete ASD[%d];\n";
const char MSG_PSD_BEGIN_VOID[]                         PROGMEM = "Adafruit::ASD[%d]->begin();\n";
const char MSG_PSD_BEGIN_VALUE[]                        PROGMEM = "Adafruit::ASD[%d]->begin(%d);\n";
const char MSG_PSD_RESET[]                              PROGMEM = "Adafruit::ASD[%d]->reset();\n";
const char MSG_PSD_SLEEP[]                              PROGMEM = "Adafruit::ASD[%d]->sleep();\n";
const char MSG_PSD_WAKEUP[]                             PROGMEM = "Adafruit::ASD[%d]->wakeup();\n";
const char MSG_PSD_SET_EXT_CLK[]                        PROGMEM = "Adafruit::ASD[%d]->setExtClk(%d);\n";
const char MSG_PSD_SET_PWM_FREQ[]                       PROGMEM = "Adafruit::ASD[%d]->setPWMFreq(%d);\n";
const char MSG_PSD_SET_OUTPUT_MODE[]                    PROGMEM = "Adafruit::ASD[%d]->setOutputMode(%d);\n";
const char MSG_PSD_GET_PWM[]                            PROGMEM = "Adafruit::ASD[%d]->getPWM(%d);\n";
const char MSG_PSD_SET_PWM[]                            PROGMEM = "Adafruit::ASD[%d]->setPWM(%d,%d,%d);\n";
const char MSG_PSD_SET_PIN[]                            PROGMEM = "Adafruit::ASD[%d]->setPin(%d, %d, %d);\n";
const char MSG_PSD_READ_PRESCALE[]                      PROGMEM = "Adafruit::ASD[%d]->readPrescale();\n";
const char MSG_PSD_WRITE_MICROSECONDS[]                 PROGMEM = "Adafruit::ASD[%d]->writeMicroseconds(%d, %d);\n";
const char MSG_PSD_SET_OSCILLATOR_FREQUENCY[]           PROGMEM = "Adafruit::ASD[%d]->setOscillatorFrequency(%d);\n";
const char MSG_PSD_GET_OSCILLATOR_FREQUENCY[]           PROGMEM = "Adafruit::ASD[%d]->getOscillatorFrequency();\n";


Adafruit_PWMServoDriver *ASD[MAX_DRIVERS];

class AdafruitServoDriverTrace {
public:
    static void createServoDriver(byte driverNum, byte i2caddress) {
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Delete shield if it already exists
            if (NULL != ASD[driverNum]) {
                delete(ASD[driverNum]);
                ASD[driverNum] = NULL;
            }
            // Execute commands
            ASD[driverNum] = new Adafruit_PWMServoDriver(i2caddress);
            // Print trace
            debugPrint(MSG_PSD_CREATE_SERVO_DRIVER, driverNum, i2caddress);
        }
    }

    static void deleteServoDriver(byte driverNum) {
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Delete pointer
            delete ASD[driverNum];
            ASD[driverNum] = NULL;
            // Print trace
            debugPrint(MSG_PSD_DELETE_SERVO_DRIVER, driverNum);
        }
    }
    
    static void begin(byte driverNum, unsigned int prescale) {
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Delete pointer
            ASD[driverNum]->begin(prescale);
            // Print trace
            if(0 == prescale){
                debugPrint(MSG_PSD_BEGIN_VOID, driverNum);
            } else {
                debugPrint(MSG_PSD_BEGIN_VALUE, driverNum, prescale);
            }
        }
    }

    static void reset(byte driverNum){
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            ASD[driverNum]->reset();
            // Print trace
            debugPrint(MSG_PSD_RESET, driverNum);
        }
    }

    static void sleep(byte driverNum){
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            ASD[driverNum]->sleep();
            // Print trace
            debugPrint(MSG_PSD_SLEEP, driverNum);
        }
    }

    static void wakeup(byte driverNum){
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            ASD[driverNum]->wakeup();
            // Print trace
            debugPrint(MSG_PSD_WAKEUP, driverNum);
        }
    }

    static void setExtClk(byte driverNum, unsigned int prescale){
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            ASD[driverNum]->setExtClk(prescale);
            // Print trace
            debugPrint(MSG_PSD_SET_EXT_CLK, driverNum, prescale);
        }
    }

    static void setPWMFreq(byte driverNum, unsigned int pwmfreq) {
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            ASD[driverNum]->setPWMFreq(pwmfreq);
            // Print trace
            debugPrint(MSG_PSD_SET_PWM_FREQ, driverNum, pwmfreq);
        }
    }

    static void setOutputMode(byte driverNum, bool totempole){
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            ASD[driverNum]->setOutputMode(totempole);
            // Print trace
            debugPrint(MSG_PSD_SET_OUTPUT_MODE, driverNum, totempole);
        }
    }

    static unsigned int getPWM(byte driverNum, unsigned int num){
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            unsigned int pwmFreq = ASD[driverNum]->getPWM(num);
            // Print trace
            debugPrint(MSG_PSD_GET_PWM, driverNum, num);

            return pwmFreq;
        }
    }

    static unsigned int setPWM(byte driverNum, unsigned int num, unsigned int on, unsigned int off) {
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            unsigned int pwm = ASD[driverNum]->setPWM(num,on,off);
            // Print trace
            debugPrint(MSG_PSD_SET_PWM, driverNum, num, on, off);

            return pwm;
        }
    }

    static void setPin(byte driverNum, unsigned int num, unsigned int val, bool invert = false){
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            ASD[driverNum]->setPin(num, val, invert);
            // Print trace
            debugPrint(MSG_PSD_SET_PIN, driverNum, num, val, invert);
        }
    }

    static unsigned int readPrescale(byte driverNum){
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            unsigned int prescale = ASD[driverNum]->readPrescale();
            // Print trace
            debugPrint(MSG_PSD_READ_PRESCALE, driverNum);

            return prescale;
        }
    }

    static void writeMicroseconds(byte driverNum, unsigned int num, unsigned int microseconds){
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            ASD[driverNum]->writeMicroseconds(num, microseconds);
            // Print trace
            debugPrint(MSG_PSD_WRITE_MICROSECONDS, driverNum, num, microseconds);
        }
    }

    static void setOscillatorFrequency(byte driverNum, unsigned int oscFreq){
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            ASD[driverNum]->setOscillatorFrequency(oscFreq);
            // Print trace
            debugPrint(MSG_PSD_SET_OSCILLATOR_FREQUENCY, driverNum, oscFreq);
        }
    }

    static unsigned int getOscillatorFrequency(byte driverNum){
        if(driverNum < MAX_DRIVERS){    //Check if driver numeration is whitin range
            // Execute command
            unsigned int oscFreq = ASD[driverNum]->getOscillatorFrequency();
            // Print trace
            debugPrint(MSG_PSD_GET_OSCILLATOR_FREQUENCY, driverNum);

            return oscFreq;
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
                    AdafruitServoDriverTrace::createServoDriver(driverNum, i2caddress);

                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case DELETE_SERVO_DRIVER:{ 
                    byte driverNum = dataIn[0];
                    AdafruitServoDriverTrace::deleteServoDriver(driverNum);

                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }
                
                case BEGIN:{
                    byte driverNum = dataIn[0];
                    unsigned int prescale = dataIn[1];
                    AdafruitServoDriverTrace::begin(driverNum, prescale);

                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case RESET:{
                    byte driverNum = dataIn[0];
                    AdafruitServoDriverTrace::reset(driverNum);

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

                case SET_EXT_CLK:{
                    byte driverNum = dataIn[0];
                    unsigned int prescale = dataIn[1];
                    AdafruitServoDriverTrace::setExtClk(driverNum, prescale);

                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case SET_PWM_FREQ:{
                    byte driverNum = dataIn[0];
                    unsigned int pwmFreq = dataIn[1]+(dataIn[2]<<8);
                    AdafruitServoDriverTrace::setPWMFreq(driverNum, pwmFreq);

                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case SET_OUTPUT_MODE:{
                    byte driverNum = dataIn[0];
                    bool totempole = dataIn[1];
                    AdafruitServoDriverTrace::setOutputMode(driverNum, totempole);

                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case GET_PWM:{
                    byte driverNum = dataIn[0];
                    unsigned int num = dataIn[1];
                    unsigned int* pwm = new unsigned int(AdafruitServoDriverTrace::getPWM(driverNum, num));
                    unsigned char* dataOut = reinterpret_cast<unsigned char*>(&pwm);

                    sendResponseMsg(cmdID, dataOut, 1);
                    break;
                }

                case SET_PWM:{
                    byte driverNum = dataIn[0];
                    unsigned int num = dataIn[1];
                    unsigned int on = dataIn[2]+(dataIn[3]<<8);
                    unsigned int off = dataIn[4]+(dataIn[5]<<8);
                    unsigned int* pwm = new unsigned int(AdafruitServoDriverTrace::setPWM(driverNum, num, on, off));
                    unsigned char* dataOut = reinterpret_cast<unsigned char*>(&pwm);

                    sendResponseMsg(cmdID, dataOut, 1);
                    break;
                }

                case SET_PIN:{
                    byte driverNum = dataIn[0];
                    unsigned int num = dataIn[1];
                    unsigned int val = dataIn[2]+(dataIn[3]<<8);
                    bool invert = dataIn[4];
                    AdafruitServoDriverTrace::setPin(driverNum, num, val, invert);

                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case READ_PRESCALE:{
                    byte driverNum = dataIn[0];
                    unsigned int* prescale = new unsigned int(AdafruitServoDriverTrace::readPrescale(driverNum));
                    unsigned char* dataOut = reinterpret_cast<unsigned char*>(&prescale);

                    sendResponseMsg(cmdID, dataOut, 1);
                    break;
                }

                case WRITE_MICROSECONDS:{
                    byte driverNum = dataIn[0];
                    unsigned int num = dataIn[1];
                    unsigned int microseconds = dataIn[2]+(dataIn[3]<<8);
                    AdafruitServoDriverTrace::writeMicroseconds(driverNum, num, microseconds);

                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case SET_OSCILLATOR_FREQUENCY:{
                    byte driverNum = dataIn[0];
                    uint32_t oscFreq = 0;
                    oscFreq |= (uint32_t) dataIn[4] << 24;
                    oscFreq |= (uint32_t) dataIn[3] << 16;
                    oscFreq |= (uint32_t) dataIn[2] <<  8;
                    oscFreq |= (uint32_t) dataIn[1];
                    AdafruitServoDriverTrace::setOscillatorFrequency(driverNum, oscFreq);

                    sendResponseMsg(cmdID, 0, 0);
                    break;
                }

                case GET_OSCILLATOR_FREQUENCY:{
                    byte driverNum = dataIn[0];
                    unsigned int oscFreq = AdafruitServoDriverTrace::getOscillatorFrequency(driverNum);
                    unsigned char dataOut[4];
                    for (int i = 0; i < 4; i++) {
                        dataOut[3 - i] = (oscFreq >> (i * 8));
                    }
                    
                    sendResponseMsg(cmdID, dataOut, 4);
                    break;
                }

                default:
					break;
            }
		}
};