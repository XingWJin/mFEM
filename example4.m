% Example 9.2 of Fish & Belytschko (2007)
function example2

% Clear all variables, including classes
clear;

% Import the mFEM library
import mFEM.*;
  
% Create a FEmesh object, add the single element, and initialize it
mesh = FEmesh('Quad4','vector');
mesh.add_element([0,1; 0,0; 2,0.5; 2,1]);
mesh.initialize();

% Label the boundaries
mesh.add_boundary_id('left', 1);    % essential boundaries
mesh.add_boundary_id('top', 2);     % distributed load (t = -20)

% Create Gauss objects for performing integration on the element and
% elements sides.
q_elem = Gauss(2);
[qp, W] = q_elem.rules();
q_face = Gauss(1);
[qp_side, W_side] = q_face.rules();

% Definethe constants for the problem
E = 3e7;            % modolus of elasticity
v = 0.3;            % posion's ratio
t_top = [0; -20];   % distributed load
D = E / (1-v^2) * [1, v, 0; v, 1, 0; 0, 0, (1-v)/2]; % constitutive matrix

% Create the stiffness matrix and force vector by looping over the
% elements, which in this case is a single element.
for e = 1:mesh.n_elements;
    
    % Extract the current element from the mesh object
    elem = mesh.element(e);
    
    % Define short-hand function handles for the element shape functions
    % and determinate of the Jacobian
    B = @(xi,eta) elem.shape_deriv(xi,eta);
    J = @(xi,eta) elem.detJ(xi,eta);

    % Initialize the stiffness matrix (K) and the force vector (f), for
    % larger systems K should be sparse.
    K = zeros(elem.n_dof);
    f = zeros(elem.n_dof,1);
    
    % Loop over the quadrature points in the two dimensions to perform the
    % numeric integration
    for i = 1:length(qp);
        for j = 1:length(qp);
            K = K + W(j)*W(i)*B(qp(i),qp(j))'*D*B(qp(i),qp(j))*J(qp(i),qp(j));
        end
    end
    
    % Define the N short-hand function handle for use on sides and
    % re-define J for the jacobian of the side
    N = @(id, beta) elem.side_shape(id, beta);
    J = @(id, beta) elem.side_detJ(id, beta);

    % Loop throught the sides of the element, if the side has the boundary
    % id of 1 (top), then add the distributed load to the force vector
    % using numeric integration via the quadrature points for the element
    % side.
    for s = 1:elem.n_sides;
        if elem.side(s).boundary_id == 2;
            for i = 1:length(qp_side);
                f = f + W_side(i)*N(s, qp_side(i))'*J(s, qp_side(i))*t_top;
            end
        end
    end          
end

% Define dof indices for the essential dofs and non-essential dofs
non = mesh.get_dof(1,'ne'); % 1-4
ess = mesh.get_dof(1);      % 5-8

% Solve for the temperatures
u = zeros(size(f));         % initialize the displacement vector
u(ess) = 0;                 % apply essential boundary condtions
u(non) = K(non,non)\f(non); % solve for T on the non-essential boundaries

% Solve for the reaction fluxes
r = K*u - f;

% Display the results
u, r

% Compute the stress and strain at the Gauss points
% Loop through the elements
for e = 1:mesh.n_elements; % (include for illustration, but not needed)
    
    % Extract the current element from the mesh object
    elem = mesh.element(e);
    
    % Collect the local values of T
    d(:,1) = u(elem.get_dof())
    
    % Compute the stress and strain at the Gauss points
    k = 1;
    for i = 1:length(qp);
        for j = 1:length(qp);
            strain(:,k) = B(qp(i),qp(j))*d;
            stress(:,k) = D*strain(:,k);
            k = k + 1;
        end
    end
end    

% Display the stress and strain vectors
strain, stress

