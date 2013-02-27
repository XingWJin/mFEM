classdef Node < handle
    %Node Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        coord = [0,0,0];
        id = [];
    end
    
    properties (Access = {?mFEM.cells.base.Cell, ?mFEM.Mesh})
        parents = mFEM.elements.Line2.empty(); % 
    end
    
    methods
        function obj = Node(id,x)
            obj.id = id;
            obj.coord(1:length(x)) = x;    
        end
        
        function varargout = get(obj, varargin)
           
            if nargin == 1
                if nargout == 1
                    varargout{1} = obj.coord;
                else
                    varargout = num2cell(obj.coord);
                end
            
            elseif isnumeric(varargin{1});
                varargout{1} = obj.coord(varargin{1});
                
            elseif ischar(varargin{1});
                switch lower(varargin{1});
                    case 'x'; varargout{1} = obj.coord(1);
                    case 'y'; varargout{1} = obj.coord(2);
                    case 'z'; varargout{1} = obj.coord(3);
                end
            end  
        end
    end
    
    methods (Access = ?mFEM.cells.base.Cell)
        function addParent(obj, c)
            obj.parents(end+1) = c;    
        end 
    end
    
end
