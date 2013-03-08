classdef Mesh < handle
    %MESH Summary of this class goes here
    %   Detailed explanation goes here
    %
    % mention dimension independance, is possible to mix elements of
    % different dimensions (not tested)
    
    properties %(Access = protected)
        elements = Composite();
        nodes = Composite(); 
        n_nodes = uint32([]);                
        n_elements = uint32([]);            
        n_dof = uint32([]);            
        options = struct('time', false, 'space', 'scalar');
    end
    
    properties (Access = protected)
        node_map = Composite();
        elem_map = Composite();
        initialized = false;
        node_map_codist;
        elem_map_codist;
        node_tag_map = Composite();
        elem_tag_map = Composite();
        tag = {};
    end
    
    methods
        grid(obj,varargin);
        addBoundary(obj,id,varargin);
        addSubdomain(obj,id,varargin);
        el = getElements(obj,varargin);
        no = getNodes(obj,varargin);
        dof = getDof(obj,varargin);
        plot(obj,varargin);

        function obj = Mesh(varargin)
            obj.options = gatherUserOptions(obj.options, varargin{:});  
        end
        
        function delete(obj)
            nodes = obj.nodes;
            elements = obj.elements;
            spmd
                nodes.delete();
                elements.delete();
            end
        end
        
        function node = createNode(obj, x)
            id = length(obj.nodes) + 1;
            node = mFEM.elements.base.Node(id,x);     
            obj.nodes{id} = node; 
        end
        
        function elem = createElement(obj, type, nodes)
            
            if isnumeric(nodes);
                nodes = obj.nodes(nodes);
            end
            
            id = length(obj.elements) + 1;
            elem = feval(['mFEM.elements.',type],id,nodes);
            obj.elements{id} = elem;
        end
    end
    
    methods (Access = protected)
        init(obj)   
        addTag(obj, id, type, varargin)
        idEmptyBoundary(obj,id);
        out = gatherComposite(obj,name,id,tag,lab);
    end
    
    methods (Static)
        nodes = buildNodes(node_map,space);
        elements = buildElements(type,elem_map,node_map,nodes);
%         D = transformDof(d,n);
    end
end

