classdef Beam < mFEM.elements.base.Element
    % A 2-node Beam element, it may be located in 1D, 2D, or 3D space.
    %
    %      (-1)   (1)   (1)
    %         1---------2
    %
    % This is a special case...
    %
    %----------------------------------------------------------------------
    %  mFEM: An Object-Oriented MATLAB Finite Element Library
    %  Copyright (C) 2012 Andrew E Slaughter
    % 
    %  This program is free software: you can redistribute it and/or modify
    %  it under the terms of the GNU General Public License as published by
    %  the Free Software Foundation, either version 3 of the License, or
    %  (at your option) any later version.
    % 
    %  This program is distributed in the hope that it will be useful,
    %  but WITHOUT ANY WARRANTY; without even the implied warranty of
    %  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    %  GNU General Public License for more details.
    % 
    %  You should have received a copy of the GNU General Public License
    %  along with this program.  If not, see <http://www.gnu.org/licenses/>.
    %
    %  Contact: Andrew E Slaughter (andrew.e.slaughter@gmail.com)
    %----------------------------------------------------------------------
    
    % Define the inherited abstract properties
    properties (SetAccess = protected, GetAccess = public)
        n_sides = 2;                 % no. "sides" (nodes are sides in 1D)
        side_dof = [1; 2];           % local dofs of the "sides"
        side_type = 'Point';         % 1D elements have points on sides
        quad = ...                   % quadrature 
            mFEM.Gauss('Order',2,'Type','Line'); 
    end
    
    methods  
        % Define the Truss constructor
        function obj = Beam(id, nodes, varargin)
           % Class constructor; calls base class constructor
           
           % Test that nodes is sized correctly
           if ~all(size(nodes) == [2,1]);
               error('Beam:Beam','Nodes not specified correctly; expected a [2x1] array, but recieved a [%dx%d] array.', size(nodes,1), size(nodes,2));
           end
           
           % Call the base class constructor
           obj = obj@mFEM.elements.base.Element(id, nodes, 'Space', 2); 
        end
        
        % Define the size function
        function L = size(obj)
        	L = norm(diff(obj.nodes,1));
        end
        
        function D = dNdx3(obj)
           % Third derivative of shape functoins 
           L = obj.size();
           D(1) = 12/L^3;
           D(2) = 6/L^2;
           D(3) = -12/L^3;
           D(4) = 6/L^2;
        end
        
        function Ke = stiffness(obj)
            L = obj.size();
            
            Ke = [12/L^3, 6/L^2, -12/L^3, 6/L^2;
                  6/L^2, 4/L, -6/L^2, 2/L;
                    -12/L^3, -6/L^2, 12/L^3, -6/L^2;
                    6/L^2, 2/L, -6/L^2, 4/L];
            
        end
        

    end
    
    methods (Access = protected)  
        function N = basis(obj, xi)
            % Returns a row vector of local shape functions
            L = obj.size();
            N(1) = 1/4*(1-xi)^2*(2+xi);
            N(2) = L/8*(1-xi)^2*(1+xi);
            N(3) = 1/4*(1+xi)^2*(2-xi);
            N(4) = L/8*(1+xi)^2*(xi-1);            
        end

        function B = gradBasis(obj, xi) 
            % Second derivative of shape functions
            L = obj.size();
            B(1) = 1/L^2*6*xi;
            B(2) = 1/L*(3*xi-1);
            B(3) = -1/L^2*6*xi;
            B(4) = 1/L*(3*xi+1);
        end
             
        function J = jacobian(obj, varargin)
            % Returns the jacobian matrix (1/2 the length)
            J = 1/2 * obj.size();            
        end
        
        function localGradBasis(~, varargin)
            % Does nothing for the Truss dlement
            error('Truss:local_grad_basis','The gradient in local coordinte system is not defined for the Truss element.');   
        end
    end
end