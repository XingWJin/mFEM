% A transient heat transfer example
%
% Syntax:
%   example6a
%   example6a('PropertyName', PropertyValue)
%
% Description:
%   example6a solves a simple transient heat conduction problem, with the
%   default settings.
%
%   example9a('PropertyName', PropertyValue) allows the user to customize
%   the behavior of this example using the property pairs listed below.
%
% Example6a Property Descriptions
%
% N
%   scalar
% 
%    The number of elements in the x and y directions, the default is 32.
%
% Element
%   {'Quad4'} | 'Tri3' | 'Tri6'
%
%   Specifies the type of element for the mesh
%
% Method
%   {'normal'} | 'alt'
%
%   Inidicates the type of sparse matrix assembly to utilize, the 'alt'
%   method is the index method that is faster for large matrices. For
%   example, for a 100 x 100 grid the normal assembly took 25.6 sec. and the
%   alternative method 23.8 sec.

function varargout = example6a(varargin)

% Import the mFEM library
import mFEM.*;

% Set the default options and apply the user defined options
opt.debug = false;
opt.n = 32;
opt.element = 'Quad4';
opt.method = 'normal';
opt = gatherUserOptions(opt,varargin{:});

% Create a FEmesh object, add the single element, and initialize it
mesh = FEmesh('Element',opt.element);
mesh.grid(0,1,0,1,opt.n,opt.n);
mesh.init();

% Label the boundaries
mesh.addBoundary(1); % essential boundaries (all)

% Problem specifics
D = 1 / (2*pi^2);           % thermal conductivity
theta = 0.5;                % numerical intergration parameter
dt = 0.1;                   % time-step

% Initialize storage
if strcmpi(opt.method,'alt');
    I = NaN(mesh.n_elements * mesh.n_dim^2,1); % (guess)
    J = I;
    Mij = I;
    Kij = I;
else
    M = sparse(mesh.n_dof(), mesh.n_dof());
    K = sparse(mesh.n_dof(), mesh.n_dof());
end

% Create mass and stiffness matrices by looping over elements
for e = 1:mesh.n_elements;

    % Extract the current element from the mesh object
    elem = mesh.element(e);
    
    % Define short-hand function handles for the element shape functions
    % and shape function derivatives
    B = @(i) elem.shapeDeriv(elem.qp{i});
    N = @(i) elem.shape(elem.qp{i});

    % Initialize the local matrices and vector
    Me = zeros(elem.n_dof);     % mass matrix
    Ke = zeros(elem.n_dof);     % stiffness matrix
    
    % Loop over the quadrature points in the two dimensions to perform the
    % numeric integration
    for i = 1:length(elem.qp);
        Me = Me + elem.W(i)*N(i)'*N(i)*elem.detJ(elem.qp{i});
        Ke = Ke + elem.W(i)*B(i)'*D*B(i)*elem.detJ(elem.qp{i});
    end

    % Insert current values into global matrix using one of two methods
    if strcmpi(opt.method,'alt');
        % Get the local degrees of freedom for this element
        dof = (1:elem.n_dof)';

        % Compute indices for inserting into sparse matrix i,j,s vectors
        m = numel(Me);
        idx = m*(e-1)+1 : m*(e);

        % Build the i,j components for the sparse matrix creation
        i = repmat(dof, length(dof),1);
        j = sort(i);
        
        % Get the global degrees of freedom for this element
        dof = elem.getDof();
        I(idx) = dof(i);
        J(idx) = dof(j);

        % Add the local mass and stiffness matrix to the sparse matrix values
         Mij(idx) = reshape(Me, numel(Me), 1);
         Kij(idx) = reshape(Ke, numel(Ke), 1);
    else
        % Add local mass, stiffness, and force to global (this method is slow)
        dof = elem.getDof();
        M(dof,dof) = M(dof,dof) + Me;
        K(dof,dof) = K(dof,dof) + Ke;
    end
end

% If the alternative method of assembly is used, the sparse matrices must
% be created using the I,J,Mij,Kij vectors
if strcmpi(opt.method,'alt');
    % Assemble sparse matrices
    M = sparse(I,J,Mij);
    K = sparse(I,J,Kij);
end

% Define dof indices for the essential dofs and non-essential dofs
ess = mesh.getDof('Boundary',1);   
non = ~ess;

% Initialize the temperatures
T_exact = @(x,y,t) exp(-t)*sin(pi*x).*sin(pi*y);
nodes = mesh.getNodes();
T = T_exact(nodes(:,1),nodes(:,2),0);

% Collect the node positions for applying the essential boundary conditions
x = nodes(:,1);
y = nodes(:,2);

% Plot the initial condition
if ~opt.debug;
    figure; hold on;
    mesh.plot(T);
    title('t = 0');
    xlabel('x');
    ylabel('y');
    cbar = colorbar;
    set(get(cbar,'YLabel'),'String','Temperature');
end

% Compute residual for non-essential boundaries, the mass matrix does not
% contribute because the dT/dt = 0 on the essential boundaries. This
% problem also does not have a force term.
R(:,1) = - K(non,ess)*T(ess);

% Use a general time integration scheme
K_hat = M(non,non) + theta*dt*K(non,non);
f_K   = M(non,non) - (1-theta)*dt*K(non,non);

% Perform 10 time-steps
for t = dt:dt:1;

    % Compute the force componenet using previous time step T
    f_hat = dt*R + f_K*T(non);

    % Solve for non-essential boundaries
    T(non) = K_hat\f_hat;
    
    % Set values for the essential boundary conditions the next time step 
    T(ess) = T_exact(x(ess), y(ess), t);

    % Plot the results
    pause(0.25);
    if ~opt.debug;
        mesh.plot(T);
        title(['t = ', num2str(t)]);
    end
end

if opt.debug;
    varargout = {x,y,t,T};
end

