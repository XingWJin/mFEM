classdef Vector < mFEM.base.handle_hide
    %VECTOR A wrapper class for creating a column vector, this is simple 
    % wrapper that provides the same features as the Matrix class so that 
    % syntax may remain consistent. This creates a column vector. And will
    % serve as the basis of creating parallel vectors in the future.  
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

    properties (SetAccess = private, GetAccess = public)
      m     % no. of rows
    end
    
    properties (Access = private)
        f     % the vector
    end
   
    methods
       function obj = Vector(m)
           %Vector Class constructor
           %
           % Syntax
           %    Vector(mesh)
           %    Vector(m)
           %
           % Description
           %    Vector(mesh) create a global vector based on the mesh
           %    contained in the FEMESH object.
           %
           %    Vector(m) create an m x 1 matrix.

           % Case when creating from an FEmesh object
           if nargin == 1 && isa(m,'mFEM.FEmesh');
               mesh = m;
               obj.m = mesh.n_dof;

           % Case when only m is specfied     
           elseif nargin == 1;
               obj.m = m;

           % Too many inputs
           else
               error('Matrix:Matrix', 'Input Error');
           end
           
           % Create a zero vector
           obj.zero();
       end
       
       function varargout = size(obj, varargin)
           %SIZE Returns the size of the the matrix
           %
           % Syntax
           %    m = size()
           %
           % Description
           %    m = size() returns the length of the vector

           % The size of the matrix
           varargout{1} = obj.m;
       end
       
       function add_vector(obj, fe, dof)
            %ADD_VECTOR Adds a sub-vector to the global vector
            %
            % Syntax
            %    add_matrix(fe, dof)
            %
            % Description
            %    add_matrix(fe, dof) adds the local vector fe to the 
            %    locations specified in dof, this is equivelent to the 
            %    following:
            %        f(dof) = f(dof) + fe,
            %    where f is the global vector.

            obj.f(dof) = obj.f(dof) + fe;
       end
       
       function f = init(obj)
           %INIT Return the vector
           %
           % Syntax
           %    f = init()
           %
           % Description
           %    f = init() creturns the vector
           f = obj.f;
       end
       
       function zero(obj)
           %ZERO Clears the matrix
           %
           % Syntax
           %    zero()
           %
           % Description 
           %    zero() removes all existing values, it does not resize the
           %    matrix.

           obj.f = zeros(obj.m,1);
       end
   end
end