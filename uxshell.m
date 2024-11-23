% --- Geometry parameters ---
n = 8; % polynomial order + 1
nv = 8; % number of patches in poloidal direction
nu = nv*3; % number of patches in toroidal direction
r = 2.0; % major radius
ao = 1.0; % outer minor radius
ai = 0.6; % inner minor radius
domo = circulartorus(n,nu,nv,ao,r);
domi = circulartorus(n,nu,nv,ai,r);
dom = {domo,domi};
domparams = [n, nu, nv];

% --- Specify flux ---
flux = [1.0,0.7];

% --- Beltrami parameter ---
zk = 0;

% --- Tolerances ---
tol = 1e-6;

ts = TaylorState(dom,domparams,zk,flux,tol);
ts = ts.solve(true);
B = ts.surface_B();

phi = 4*pi/7;
h = 1e-3;
center = [(r+ai+.1)*cos(phi) (r+ai+.1)*sin(phi) 0];

[errB, curlB, kB] = ts.fd_test(center,h);
fprintf('at interior pt norm(curl B - k B) = %f\n',norm(errB));