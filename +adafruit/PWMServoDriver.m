classdef PWMServoDriver < matlabshared.addon.LibraryBase & matlab.mixin.CustomDisplay 
% PWMServoDriver Create an Adafruit PWM Servo Driver device object.

    properties(Access = private, Constant = true)
        CREATE_SERVO_DRIVER = hex2dec('00')
        DELETE_SERVO_DRIVER = hex2dec('01')
        SET_PWM             = hex2dec('02')
        SET_PWM_FREQ        = hex2dec('03')
        SLEEP               = hex2dec('04')
        WAKEUP              = hex2dec('05')
        RESET               = hex2dec('06')
    end
    properties(GetAccess = public, SetAccess = protected)
        SCLPin
        SDAPin
    end
    properties(SetAccess = immutable)
        I2CAddress
        PWMFrequency
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
            narginchk(1,5);
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
                addParameter(p, 'PWMFrequency', 60);
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
            
            frequency = matlabshared.hwsdk.internal.validateDoubleParameterRanged('PWM frequency', p.Results.PWMFrequency, 0, 2^15-1, 'Hz');
            obj.PWMFrequency = frequency;
            
                      
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
        function setPWM(obj, num, on, off)
            commandID = obj.SET_PWM;
            data_on = typecast(uint16(on), 'uint8');
            data_off = typecast(uint16(off), 'uint8');
            data = [num, data_on, data_off];
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end

        function setPWMFreq(obj, freq)
            commandID = obj.SET_PWM_FREQ;
            data_freq = typecast(uint16(freq), 'uint8');
            data = data_freq;
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

        function reset(obj)
            commandID = obj.RESET;
            data = [];
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end
    end

    %% Private methods
    methods (Access = private)
        function createServoDriver(obj)        
            commandID = obj.CREATE_SERVO_DRIVER;
            frequency = typecast(uint16(obj.PWMFrequency), 'uint8');
            data = [uint8(obj.I2CAddress), frequency];
            sendCommandCustom(obj, obj.LibraryName, commandID, data');
        end
        
        function deleteServoDriver(obj)
            commandID = obj.DELETE_SERVO_DRIVER;
            params = [];
            sendCommandCustom(obj, obj.LibraryName, commandID, params);
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
            fprintf('    PWMFrequency: %.2d (Hz)\n', obj.PWMFrequency);
            fprintf('\n');
                  
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end
