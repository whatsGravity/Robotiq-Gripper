classdef RobotiqGripper < matlab.mixin.SetGet
    % Matlab class to control the robotiq 2-finger gripper
    %   class sends arguments to a python script that controls the gripper
    %   over rs-485 serial. Done this way because matlab does not handle
    %   res-485 serial well.
    %   M. Rancic, 2016
    properties(SetAccess = 'public', GetAccess = 'public')
        Position
        Speed
        Force
        PyControl
        IsInit
    end
    
    methods(Access = 'public')
        %% Constructor, destructor, and init. 
        function obj = RobotiqGripper

        end
        
        function delete(obj)
            delete(obj);
        end
        
        function init(obj)
            if count(py.sys.path,'') == 0
                insert(py.sys.path,int32(0),'');
            end
            try
                obj.PyControl = py.importlib.import_module('robotiq');
            catch
                error('Cannot find the python class in your path. Are you sure you have it downloaded?');
            end
            py.reload(obj.PyControl);
            obj.PyControl.init();
            obj.IsInit = true;
            obj.Position = int16(0);
            obj.Speed = int16(255);
            obj.Force = int16(255);
        end
    end
    
    methods
        %% Get functions. Speed queries gripper, Force and Pos read propety
        function Position = get.Position(obj)
            if(obj.IsInit)
                response = obj.PyControl.checkStatus()
                Position = int16(hex2dec(char(response(15:16))));                 
                %Position = obj.Position;
            else
                error('Must run init() first.')
            end
        end
        
        function Speed = get.Speed(obj)
            if(obj.IsInit)
                Speed = obj.Speed;               
            else
                error('Must run init() first.')
            end
        end
        
        function Force = get.Force(obj)
            if(obj.IsInit)
                Force = obj.Force;               
            else
                error('Must run init() first.')
            end
        end

        %% Set Functions: All check for initilization before running
        function set.Position(obj, value)
            if(obj.IsInit)
                %obj.Position = int16(value);
                obj.PyControl.setPosition(int16(value));
            else
                error('Must run init() first.')
            end
        end
        
        function set.Speed(obj, value)
            if(obj.IsInit)
                obj.PyControl.setSpeed(int16(value));
                obj.Speed = int16(value);
            else
                error('Must run init() first.')
            end
        end
        
        function set.Force(obj, value)
            if(obj.IsInit)
                obj.PyControl.setForce(int16(value));
                obj.Force = int16(value);
            else
                error('Must run init() first.');
            end
        end
        
        %% Other Gripper functions.
        function fault = getFault(obj)
            response = obj.PyControl.checkStatus();
            tFault = char(response);
            tFault = tFault(11:12);
            switch(tFault)
                case '0'
                    fault = 'No fault';
                case '5'
                    fault = 'Action delayed, activation (reactivation) must be completed prior to renewed action.';
                case '7'
                    fault = 'The activation bit must be set prior to action';
                case '8'
                    fault = 'Maximum operating temperature exceeded, wait for cool-down.';
                case 'A'
                    fault = 'Under minimum operating voltage.';
                case 'B'
                    fault = 'Automatic release in progress.';
                case 'C'
                    fault = 'Internal processor fault';
                case 'D'
                    fault = 'Activation fault, verify that no interference or other error occurred.';
                case 'E'
                    fault = 'Overcurrent triggered.';
                case 'F'
                    fault = ' Automatic release completed.';
                otherwise
                    fault = 'this shouldn''t have happened but do''t worry about it';
            end
        end
        
        function current = getCurrent(obj)
            response = obj.PyControl.checkStatus();
            tCurrent = char(response);
            current = hex2dec(tCurrent(17:18));
        end
        
        function detect = objDetection(obj)
            response = obj.PyControl.checkStatus();
            tDetect = char(response);
            tDetect = dec2bin(hex2dec(tDetect(7)));
            tStatus = bin2dec(tStatus(3:4));
            switch tDetect
                case 0
                    detect = false;
                case 1
                    detect = true;
                case 2
                    detect = true;
                case 3
                    detect = false;
                otherwise
                    error('Something went wrong while object detecting.');
            end
        end
        
        function status = getStatus(obj)
            response = obj.PyControl.checkStatus();
            tStatus = char(response);
            tStatus = dec2bin(hex2dec(tStatus(7)));
            tStatus = bin2dec(tStatus(3:4));
            switch tStatus
                case 0
                    status = 'Gripper is in reset ( or automatic release ) state. See Fault Status if Gripper is activated.';
                case 1
                    status = 'Activation in progress.';
                case 2
                    status = 'Not used. Something went wrong';
                case 3
                    status = 'Activation has been completed';
                otherwise
                    error('Something went wrong while checking the status.');
            end
        end
        
        
    end
    
end