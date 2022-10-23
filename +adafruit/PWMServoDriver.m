classdef PWMServoDriver < matlabshared.addon.LibraryBase & matlab.mixin.CustomDisplay 
% PWMServoDriver Create an Adafruit PWM Servo Driver device object.

    properties(Access = private, Constant = true)
        CREATE_SERVO_DRIVER         = hex2dec('00')
        DELETE_SERVO_DRIVER         = hex2dec('01')
        BEGIN                       = hex2dec('02')
        RESET                       = hex2dec('03')
        SLEEP                       = hex2dec('04')
        WAKEUP                      = hex2dec('05')
        SET_EXT_CLOCK               = hex2dec('06')
        SET_PWM_FREQ                = hex2dec('07')
        SET_OUTPUT_MODE             = hex2dec('08')
        GET_PWM                     = hex2dec('09')
        SET_PWM                     = hex2dec('0A')
        SET_PIN                     = hex2dec('0B')
        READ_PRESCALE               = hex2dec('0C')
        WRITE_MICROSECONDS          = hex2dec('0D')
        SET_OSCILLATOR_FREQUENCY    = hex2dec('0E')
        GET_OSCILLATOR_FREQUENCY    = hex2dec('0F')
    end
    properties(GetAccess = public, SetAccess = protected)
        SCLPin
        SDAPin
    end
    properties(SetAccess = immutable)
        I2CAddress
    end
    properties(Access = private)
        Bus
        CountCutOff
        DriverSlotNum
    end
    
    properties(Access = private)
        ResourceOwner = 'AdafruitPWMServoDriver';
        MinI2CAddress = hex2dec('40');  
        MaxI2CAddress = hex2dec('7F');   
    end
    
    properties(Access = protected, Constant = true)
        LibraryName = 'Adafruit/PWMservoDriver'
        DependentLibraries = {'I2C'}
        LibraryHeaderFiles = {'Adafruit_PWM_Servo_Driver_Library/Adafruit_PWMServoDriver.h'}
        CppHeaderFile = fullfile(arduinoio.FilePath(mfilename('fullpath')), 'src', 'PWMServoDriverBase.h')
        CppClassName = 'PWMServoDriverBase'
    end
    
    %% Constructor
    methods(Hidden, Access = public)
        function obj = PWMServoDriver(parentObj, varargin)
            narginchk(1,3);
            obj.Parent = parentObj;
            
            if ismember(obj.Parent.Board, {'Uno', 'Leonardo'})
                obj.CountCutOff = 4;
            else
                obj.CountCutOff = 32;
            end
            count = incrementResourceCount(obj.Parent, obj.ResourceOwner);
            incrementResourceCount(obj.Parent,'I2C');
            if count > obj.CountCutOff
                obj.localizedError('MATLAB:arduinoio:general:maxAddonLimit',...
                    num2str(obj.CountCutOff),...
                    obj.ResourceOwner,...
                    obj.Parent.Board);
            end  
            try
                p = inputParser;
                addParameter(p, 'I2CAddress', hex2dec('40'));
                parse(p, varargin{:});
            catch e
                message = e.message;
                index = strfind(message, '''');
                str = message(index(1)+1:index(2)-1);
                switch e.identifier
                     case 'MATLAB:InputParser:ParamMissingValue'
                         % throw error if user doesn't provide a value for parameter
                        try
                           validatestring(str,p.Parameters);
                        catch
                            obj.localizedError('MATLAB:arduinoio:general:invalidNVPropertyName',...
                            obj.ResourceOwner, ...
                            matlabshared.hwsdk.internal.renderCellArrayOfCharVectorsToCharVector(p.Parameters, ', '));
                        end
                        obj.localizedError('MATLAB:InputParser:ParamMissingValue', str);
                    case 'MATLAB:InputParser:UnmatchedParameter'
                        % throw error if user tries to use invalid NV pair
                        obj.localizedError('MATLAB:arduinoio:general:invalidNVPropertyName',...
                        obj.ResourceOwner, ...
                        matlabshared.hwsdk.internal.renderCellArrayOfCharVectorsToCharVector(p.Parameters, ', '));
                    otherwise
                end
            end
            
            address = validateAddress(obj, p.Results.I2CAddress);
            try
                i2cAddresses = getSharedResourceProperty(parentObj, obj.ResourceOwner, 'i2cAddresses');
            catch
                i2cAddresses = [];
            end
            if ismember(address, i2cAddresses)
                obj.localizedError('MATLAB:arduinoio:general:conflictI2CAddress', ...
                    num2str(address),...
                    dec2hex(address));
            end
            i2cAddresses = [i2cAddresses address];
            setSharedResourceProperty(parentObj, obj.ResourceOwner, 'i2cAddresses', i2cAddresses);
            obj.I2CAddress = address;
                      
            configureI2C(obj);
            
            obj.DriverSlotNum = getFreeResourceSlot(obj.Parent, obj.ResourceOwner);
            createServoDriver(obj);
            
            setSharedResourceProperty(parentObj, 'I2C', 'I2CIsUsed', true);
        end
    end
    
    %% Destructor
    methods (Access=protected)
        function delete(obj)
            originalState = warning('off','MATLAB:class:DestructorError');
            try
                parentObj = obj.Parent;
                decrementResourceCount(obj.Parent, obj.ResourceOwner);
                countI2C = decrementResourceCount(obj.Parent, 'I2C');
                i2cAddresses = getSharedResourceProperty(parentObj, obj.ResourceOwner, 'i2cAddresses');
                if ~isempty(i2cAddresses)
                    if ~isempty(obj.I2CAddress) 
                        i2cAddresses(i2cAddresses==obj.I2CAddress) = [];
                    end
                end
                setSharedResourceProperty(parentObj, obj.ResourceOwner, 'i2cAddresses', i2cAddresses);
                if ~isempty(obj.DriverSlotNum) 
                    clearResourceSlot(parentObj, obj.ResourceOwner, obj.DriverSlotNum);
                    deleteServoDriver(obj);
                    if(countI2C == 0)
                        I2CTerminals = parentObj.getI2CTerminals();
                        sda = parentObj.getPinsFromTerminals(I2CTerminals(obj.Bus*2+1));
                        sda = sda{1};
                        scl = parentObj.getPinsFromTerminals(I2CTerminals(obj.Bus*2+2));
                        scl = scl{1};
                        configurePinResource(parentObj, sda, 'I2C', 'Unset', false);
                        configurePinResource(parentObj, scl, 'I2C', 'Unset', false);
                    end
                end
            catch
            end
            warning(originalState.state, 'MATLAB:class:DestructorError');
        end
    end
    
    %% Public methods
    methods (Access = public)

        function begin(obj, prescale)
            % Argument validation
            arguments
                obj
                prescale (1,1) uint8 = 0
            end

            commandID = obj.BEGIN;
            data = prescale;
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end

        function reset(obj)
            commandID = obj.RESET;
            data = [];
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end

        function sleep(obj)
            commandID = obj.SLEEP;
            data = [];
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end

        function wakeup(obj)
            commandID = obj.WAKEUP;
            data = [];
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end
        
        function setExtClk(obj, prescale)
            % Argument validation
            arguments 
                obj
                prescale (1,1)   uint8
            end

            commandID = obj.SET_EXT_CLOCK;
            data = prescale;
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end

        function setPWMFreq(obj, freq)
            % Argument validation
            arguments 
                obj
                freq (1,1) uint16
            end

            commandID = obj.SET_PWM_FREQ;
            dataFreq = typecast(freq, 'uint8');
            data = dataFreq;
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end

        function setOutputMode(obj, totempole)
            % Argument validation
            arguments 
                obj
                totempole (1,1)  uint8
            end

            commandID = obj.SET_OUTPUT_MODE;
            data = totempole;
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end

        function pwm = getPWM(obj, num)
            % Argument validation
            arguments 
                obj
                num (1,1)   uint8
            end

            commandID = obj.GET_PWM;
            data = num;
            pwm = sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end

        function pwm = setPWM(obj, num, on, off)
            % Argument validation
            arguments 
                obj
                num (1,1)   uint8
                on  (1,1)   uint16
                off (1,1)   uint16
            end

            commandID = obj.SET_PWM;
            data_on = typecast(uint16(on), 'uint8');
            data_off = typecast(uint16(off), 'uint8');
            data = [num, data_on, data_off];
            pwm = sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end

        function setPin(obj, num, val, invert)
            % Argument validation
            arguments
                obj
                num (1,1) uint8
                val (1,1) uint16
                invert (1,1) uint8 = false
            end

            commandID = obj.SET_PIN;
            dataVal = typecast(uint16(val), 'uint8');
            data = [num dataVal invert];
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end
        
        function prescale = readPrescale(obj)
            commandID = obj.READ_PRESCALE;
            data = [];
            prescale = sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end
        
        function writeMicroseconds(obj, num, microseconds)
            % Argument validation
            arguments 
                obj
                num (1,1)   uint8
                microseconds (1,1) uint16
            end

            commandID = obj.WRITE_MICROSECONDS;
            dataMicroseconds = typecast(uint16(microseconds), 'uint8');
            data = [num dataMicroseconds];
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end
        
        function setOscillatorFrequency(obj, freq)
            % Argument validation
            arguments 
                obj
                freq (1,1)   uint32
            end

            commandID = obj.SET_OSCILLATOR_FREQUENCY;
            dataFreq = typecast(uint32(freq), 'uint8');
            data = dataFreq;
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end
        
        function freq = getOscillatorFrequency(obj)
            commandID = obj.GET_OSCILLATOR_FREQUENCY;
            data = [];
            freq = swapbytes(typecast(uint8(sendCommandCustom(obj, obj.LibraryName, commandID, data')), 'uint32'));
        end

    end

    %% Private methods
    methods (Access = private)
        function createServoDriver(obj)        
            commandID = obj.CREATE_SERVO_DRIVER;
            data = uint8(obj.I2CAddress);
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end
        
        function deleteServoDriver(obj)
            commandID = obj.DELETE_SERVO_DRIVER;
            data = [];
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end

    end
    
    methods(Access = private)
        function addr = validateAddress(obj, address)
            if ~isempty(address)
                
                if isstring(address)
                    address = char(address);
                end
                if isempty(address)
                        obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress', '', ...
                            strcat('0x', dec2hex(obj.MinI2CAddress), '(',num2str(obj.MinI2CAddress), ')'), ...
                            strcat('0x', dec2hex(obj.MaxI2CAddress), '(',num2str(obj.MaxI2CAddress), ')'));
                end
                
                if ~ischar(address)
                    try
                        validateattributes(address, {'uint8', 'double'}, {'scalar'});
                    catch
                        obj.localizedError('MATLAB:hwsdk:general:invalidAddressType');
                    end
                    if ~(address >= 0 && ~isinf(address))
                        obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress', num2str(address), ...
                            strcat('0x', dec2hex(obj.MinI2CAddress), '(',num2str(obj.MinI2CAddress), ')'), ...
                            strcat('0x', dec2hex(obj.MaxI2CAddress), '(',num2str(obj.MaxI2CAddress), ')'));
                    end
                    try
                        addr = matlabshared.hwsdk.internal.validateIntParameterRanged('address', address, obj.MinI2CAddress, obj.MaxI2CAddress);
                    catch
                        obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress', strcat('0x', dec2hex(address), '(',num2str(address),')'), ...
                            strcat('0x', dec2hex(obj.MinI2CAddress), '(',num2str(obj.MinI2CAddress), ')'), ...
                            strcat('0x', dec2hex(obj.MaxI2CAddress), '(',num2str(obj.MaxI2CAddress), ')'));
                    end
                else
                    
                    if strcmpi(address(1:2),'0x')
                        address = address(3:end);
                    elseif strcmpi(address(end), 'h')
                        address(end) = [];
                    end
                    try
                        addr = hex2dec(address);
                    catch
                        obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress', address, ...
                            strcat('0x', dec2hex(obj.MinI2CAddress), '(',num2str(obj.MinI2CAddress), ')'), ...
                            strcat('0x', dec2hex(obj.MaxI2CAddress), '(',num2str(obj.MaxI2CAddress), ')'));
                    end
                    
                    if addr < obj.MinI2CAddress || addr > obj.MaxI2CAddress
                        obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress', ...
                            strcat('0x', dec2hex(addr),'(',num2str(addr),')'), ...
                            strcat('0x', dec2hex(obj.MinI2CAddress),'(',num2str(obj.MinI2CAddress), ')'), ...
                            strcat('0x', dec2hex(obj.MaxI2CAddress),'(',num2str(obj.MaxI2CAddress), ')'));
                    end
                end
            else
                obj.localizedError('MATLAB:arduinoio:general:invalidI2CAddress','', ...
                    strcat('0x', dec2hex(obj.MinI2CAddress),'(',num2str(obj.MinI2CAddress), ')'), ...
                    strcat('0x', dec2hex(obj.MaxI2CAddress),'(',num2str(obj.MaxI2CAddress), ')'));
            end
            
        end
    
        function configureI2C(obj)
            parentObj = obj.Parent;
            I2CTerminals = parentObj.getI2CTerminals();
            
            if ~strcmp(parentObj.Board, 'Due')
                obj.Bus =0 ;
                resourceOwner = 'I2C'; 
                sda = parentObj.getPinsFromTerminals(I2CTerminals(obj.Bus*2+1)); 
                sda = sda{1};
                [~, ~, pinMode, pinResourceOwner] = getPinInfo(obj.Parent, sda);
                if (strcmp(pinMode, 'I2C') || strcmp(pinMode, 'Unset')) && strcmp(pinResourceOwner, '') 
                    configurePinResource(obj.Parent, sda, '', 'Unset');        
                end
                configurePinResource(parentObj, sda, resourceOwner, 'I2C', false);
                scl = parentObj.getPinsFromTerminals(I2CTerminals(obj.Bus*2+2)); 
                scl = scl{1};
                [~, ~, pinMode, pinResourceOwner] = getPinInfo(obj.Parent, scl);
                if (strcmp(pinMode, 'I2C') || strcmp(pinMode, 'Unset')) && strcmp(pinResourceOwner, '')
                    configurePinResource(obj.Parent, scl, '', 'Unset');            
                end
                configurePinResource(parentObj, scl, resourceOwner, 'I2C', false);
                obj.SCLPin = char(scl);
                obj.SDAPin = char(sda);
            else
                obj.Bus = 1;
                obj.SCLPin = 'SCL1';
                obj.SDAPin = 'SDA1';
            end
        end
    end
    
    %% Protected methods
    methods(Access = protected)
        function output = sendCommandCustom(obj, libName, commandID, inputs, timeout)
            inputs = [obj.DriverSlotNum-1; inputs];
            if nargin > 4
                [output, ~] = sendCommand(obj, libName, commandID, inputs, timeout);
            else
                [output, ~] = sendCommand(obj, libName, commandID, inputs);
            end
        end
        
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            
            fprintf('          SCLPin: ''%s''\n', obj.SCLPin);
            fprintf('          SDAPin: ''%s''\n', obj.SDAPin);
            fprintf('      I2CAddress: %-1d (''0x%02s'')\n', obj.I2CAddress, dec2hex(obj.I2CAddress));
            fprintf('\n');
                  
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end
