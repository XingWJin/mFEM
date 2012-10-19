classdef Element < handle
    %Element Base class for defining elements
    % Inludes the general behavior of an element, including the node locations,
    % id, shape functions, etc...
    %
    % This is an abstract class, as such it must be inherited to function.
    % The abstract properties and methods must be redifined in the
    % subclass, see Quad4.m for an example.
    %
    % see Quad4
    
    % Abstract Properties (must be redefined in subclass)
    properties (Abstract = true, SetAccess = protected, GetAccess = public) 
      n_sides;      % no. of sides
      lims;         % limits of local coordinate; assumesall dim. vary the same
      side_dof;     % array of local node ids for each side
      side_type;    % defines the type of element that defines the sides.
    end
    
    % Abstract Methods (protected)
    % (the user must redfine these in subclasse, e.g. Quad4)
    methods (Abstract, Access = protected)
        N = basis(obj, varargin)            % basis functions
        B = grad_basis(obj, varargin)       % basis function derivatives (dN/dx, ...)
        G = local_grad_basis(obj, varargin) % basis function derivatives (dN/dxi, ...)
        J = jacobian(obj, varargin)         % the Jacobian matrix for the element
    end
    
    % Public properties (read only)
    properties (SetAccess = protected, GetAccess = public)
        id = [];          % element id [double]
        nodes = [];       % global coordinates (no. nodes, no. dim) [double]
        n_nodes = [];     % no. of nodes [double]
        n_dim = []        % no. of spatial dimensions [double]
        n_dof = [];       % no. of global degrees of freedom
        n_dof_node = 1;   % no. of dofs per node (scalar = 1)       
        is_side = false;  % id's the element as a side or not
        opt = ...         % struct of default user options
            struct('space', 'scalar');
    end
    
    % Public properties (read only; except FEmesh)
    properties (SetAccess = {?mFEM.FEmesh, ?mFEM.Element}, SetAccess = protected, GetAccess = public)
        on_boundary;                % flag if element is on a boundary
        boundary_id = uint32([]);   % list of all boundary ids for element
        side = ...                  % structure containing side info
            struct('on_boundary', [], 'boundary_id', uint32([]),...
                'dof', uint32([]), 'global_dof', uint32([]), ...
                'neighbor', [], 'neighbor_side', uint32([]));          
    end
    
    % Protected properties
    properties (Access = {?mFEM.FEmesh, ?mFEM.Element}, Access = protected)
       global_dof = []; % global dof for nodes of element    
       side_nodes = []; % nodal coord. for side elements, see get_normal
    end
    
    % Public Methods
    % These methods are accessible by the user to create the element and
    % access the shape functions and other necessary parameters
    methods (Access = public)
        function obj = Element(id, nodes, varargin)
            % Class constructor.
            %
            % This is an abstract class, it must be inherited by a subclass
            % to operate, see Quad4.m for example.
            %
            % Syntax:
            %   Element(id, nodes)
            %   Element(id, nodes, 'PropertyName', PropertyValue)
            %
            % Description:
            %   Element(id, nodes) creates an element given:
            %       id: unique identification number for this element
            %       nodes: matrix of node coordinates (global), should be 
            %              arranged as column matrix [no. nodes x no. dims]
            %
            %   Element(id, nodes, 'PropertyName', PropertyValue) allows
            %       customize the behavior of the element, the available
            %       properties are listed below.
            %
            % Properties:
            %   'Space' = 'scalar', 'vector', <number>
            %               allows the type of FEM space to be set: scalar
            %               sets the number of dofs per node to 1, vector
            %               sets it to the no. of space dimension, and
            %               specifing a number sets it to that value.
            
            % Add the bin directory
            addpath('./bin');
            
            % Insert required values into object properties
            obj.id = id;
            obj.nodes = nodes;
            [obj.n_nodes, obj.n_dim] = size(nodes);

            % Collect the options from the user
            obj.opt = gather_user_options(obj.opt, varargin{:});
            
            % Determine the no. of dofs per node
            if strcmpi(obj.opt.space, 'scalar');
                obj.n_dof_node = 1;
                
            elseif strcmpi(obj.opt.space, 'vector');
                obj.n_dof_node = obj.n_dim;
                
            elseif isnumeric(obj.opt.space);
                obj.n_dof_node = obj.opt.space;
                
            else
                error('FEmesh:FEmesh', 'The element space, %s, was not recongnized.',obj.opt.space);
            end         
            
            % Determine the total number of global dofs
            obj.n_dof = obj.n_nodes * obj.n_dof_node;
        end
        
        function N = shape(obj, varargin)
            % Returns the shape functions

            % Scalar field basis functions
            N = obj.basis(varargin{:});

            % Non-scalar fields
            if obj.n_dof_node > 1;
                n = N;                          % re-assign scalar basis
                r = obj.n_dof_node;             % no. of rows
                c = obj.n_dof_node*obj.n_nodes; % no. of cols
                N = zeros(r,c);                 % size the vector basis
    
                % Loop through the rows and assign scalar basis
                for i = 1:r;
                    N(i,i:r:c) = n;
                end
            end            
        end
        
        function B = shape_deriv(obj, varargin)
            % Returns the shape function derivatives in x,y system

            % Scalar field basis functin derivatives
            B = obj.grad_basis(varargin{:});
                        
            % Non-scalar fields
            if obj.n_dof_node > 1;
                b = B;                      % Re-assign scalar basis
                r = obj.n_dof_node;         % no. of rows
                c = r*size(b,2);            % no. of cols
                B = zeros(r+1,c);           % size the vector basis

                % Loop through the rows and assign scalar basis
                for i = 1:r;
                    B(i,i:r:c)  = b(i,:);
                    B(r+1, i:r:c) = b((r+1)-i,:);
                end
            end
        end
        
        function J = detJ(obj, varargin)
            % Returns the determinate of the jacobian matrix
            J = det(obj.jacobian(varargin{:}));
        end 
        
        function varargout = get_position(obj, varargin)
            % Returns the real coordinates given xi, eta, ...
            %
            % Syntax:
            %   x = get_position(xi)
            %   [x,y] = get_position(xi,eta)
            %   [x,y,z] = get_position(xi,eta,zeta)
            %
            % Note: This function accounts for being on a side, if the
            % element is a side element then it will use the side_nodes
            % variable to give you the position of the point in the real
            % x,y,z coordinate system.
           
            % Initialize the output
            varargout = cell(obj.n_dim);
            
            % Determine the nodes based on if the element is a side or not
            if obj.is_side;
                n = obj.n_dim + 1;
                node = obj.side_nodes;
            else
                n = obj.n_dim;
                node = obj.nodes;
            end

            % Loop through the dimensions and return the desired position
            for i = 1:n;
               varargout{i} = obj.shape(varargin{:})*node(:,i); 
            end

        end
        
        function n = get_normal(obj, varargin)
            % Returns the normal vector at a given xi, eta, ...
            %
            % The element must be a side element created with build_side
            % of a parent element for this function to be used.
           
            % Throw an error if the element is not a side
            if ~obj.is_side;
                error('Element:get_normal', 'Function only available for side elements');
            end
            
            % 1D: Side is defined by a line
            if obj.n_dim == 1;
                % Compute the tangent at the point
                n = obj.local_grad_basis(varargin{:}) * obj.side_nodes;
                
                % Re-arrange tangent to give the normal (outward from
                % element face is positive)
                n = [n(2), -n(1)]/norm(n);

            % 2D: Side is defined by a plane    
            elseif obj.n_dim == 2;
                error('Element:get_normal', 'Not yet supported');
                
            % Only defined for 1D and 2D sides
            else
                error('Element:get_normal', 'Not defined for %d-D side element', obj.n_dim);
            end 
        end
                
        function side = build_side(obj, id)
            % Build an element for the side
            
            if obj.n_dim == 3;
                error('Element:build_side','Feature not yet supported in 3D');
            end
            
            % Extract the nodes for the side
            dof = obj.side_dof(id,:);
            node = obj.nodes(dof,:);
            
            % Create a map to the line/plane
            mapped = zeros(size(node,2),1);
            for i = 2:size(node,1);
                mapped(i,:) = norm(node(i,:) - node(1,:));
            end
            
            % Create the side element, the FE space of side must be set
            % to be the same as the parent element
            side = feval(['mFEM.',obj.side_type], NaN, mapped,...
                'Space', obj.n_dof_node);
            
            % Indicate that the element created was a side
            side.is_side = true;
            
            % Store the actual coordinates in the side element
            side.side_nodes = node;
        end
               
        function dof = get_dof(obj)
            % The global degrees of freedom, account for type of space
            
            % Scalar FE space
            if obj.n_dof_node == 1;
                dof = obj.global_dof; 
            
            % Non-scalar fields
            else
                dof = obj.transform_dof(obj.global_dof);
            end
        end  
        
        function dof = get_side_dof(obj, s)
            % Extract the local dofs for the specified side
           
            % Scalar FE space
            if obj.n_dof_node == 1;
                dof = obj.side(s).dof;

            % Non-scalar FE space
            else 
                dof = obj.transform_dof(obj.side(s).dof);
            end
        end
                
        function D = transform_dof(obj, d)
            % Converts the dofs for vector element space
            
            n = obj.n_dim;              % no. of dimensions
            D = zeros(n*length(d),1);   % size of vector space dofs
            
            % Loop through dimensions and build vector
            for i = 1:n;
                D(i:n:end) = d*n - (n-i);
            end 
        end
    end
end
    