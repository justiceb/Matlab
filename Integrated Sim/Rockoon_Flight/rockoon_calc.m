function [outputs, data] = rockoon_calc(t, inputs, sz_0, rocksim, rasaero, wind, balloon_height, Drocket)

%define inputs and outputs
%inputs = [sx, vx, sz, vz, theta, theta_dot]
%outputs = [vx, ax, vz, az, theta_dot, theta_dot_dot]
sx = inputs(1);
vx = inputs(2);
sz = inputs(3);
vz = inputs(4);
theta = inputs(5);
theta_dot = inputs(6);

%constants
A = pi*(Drocket/2)^2;                %(m^2) reference area
gamma_air = 1.4;                     %specific heat of air
gamma_H2 = 1.41;                     %specific heat of H2
g = 9.81;                            %m/s/s
R_air = 287.058;                     %specific gas constant air (SI)
R_H2 = 4124;                         %specific gas constant hydrogen (SI)

% Get wind data
vx_wind = interp1( wind.HGHT, wind.SKNT, sz, 'linear', 'extrap' );    %interpolate for ground course
vz_wind = 0;

% get gaseous density and speed of sound
[rho_air,a_air,temp_air,press_air,kvisc,ZorH]=stdatmo(sz);   %SI units

if (sz-sz_0 <= balloon_height)              %if we are inside of the balloon
    rho = press_air/(R_H2 * temp_air);      %set gas density to hydrogen density
    a = sqrt(gamma_H2 * R_H2 * temp_air);   %set gas speed of sound to hydrogen speed of sound
    vx_wind = 0;                            %(m/s) wind x velocity at altitude
else                                        %if we are outside of the balloon
    rho = rho_air;                          %use air density
    a = a_air;                              %use air speed of sound
end

% calculate freestream velocity and angle of attack
vx_inf = vx_wind - vx;             %(m/s) get freestream velocity
vz_inf = vz_wind - vz;             %(m/s) get freestream velocity
v = norm([vx_inf vz_inf]);         %[m/s] velocity magnitude
M = v/a;                           %freestream Mach
v_theta = atan2d(-vz_inf,-vx_inf);   %[deg] polar angle 
alpha = v_theta - theta;           %[deg] angle of attack

%interpolate RASAero for aerodynamics data
CD = interp2(rasaero.Mach,rasaero.alpha_deg,rasaero.CD,M,abs(alpha),'spline');           %
CN = interp2(rasaero.Mach,rasaero.alpha_deg,rasaero.CN,M,abs(alpha),'spline');           %
CP = interp2(rasaero.Mach,rasaero.alpha_deg,rasaero.CP,M,abs(alpha),'spline') * 0.0254;  %(m) from nosecone tip

%Calculate forces
N = 1/2 * rho * v^2 * A * CN ;                              %(N) normal force
D = 1/2 * rho * v^2 * A * CD ;                              %(N) drag force
   m_total = interp1(rocksim.Time1, rocksim.MassOunces, t); %(ounces) total rocket mass
   m_total = m_total * 0.0283495;                           %(kg) total rocket mass
Fg = m_total * g;                                           %(N) gravity force
T = interp1(rocksim.Time1, rocksim.ThrustN, t);             %(N) engine thrust

%determine ax, ay
Tx = T*cosd(theta);
Tz = T*sind(theta);
Dx = -D*cosd(v_theta);
Dz = -D*sind(v_theta);
FGx = 0;
FGz = -Fg;
Nx = sign(alpha) * N*cosd(v_theta-90);
Nz = sign(alpha) * N*sind(v_theta-90);

ax = (Tx + Dx + FGx + Nx)/m_total;
az = (Tz + Dz + FGz + Nz)/m_total;

%determine static margin
CG = interp1(rocksim.Time1, rocksim.CGInches, t) * 0.0254;  %(m) to CG from nosecone
margin = CP - CG;                                           %(m) static margin

%determine theta_dot_dot
r = -[cosd(theta) , sind(theta) , 0];                                %points from CG to CP (useless magnitude)
r = margin * r./norm(r);                                             %(m) displacement vector from CG to CP
Torque = cross(r,[Dx Dz 0]) + cross(r,[Nx Nz 0]);                    %(N-m) torque caused by normal and drag forces
Torque = Torque(3);                                                  %(N-m) take torque scalar term
   I = interp1(rocksim.Time1, rocksim.Longitudinalmomentofinert, t); %
   I = I * 0.00001829;                                             %(kg-m^2) moment of inertia
theta_dot_dot = (Torque / I)  *57.2957795;                           %deg/s/s

%formulate function output
outputs = [vx, ax, vz, az, theta_dot, theta_dot_dot]';
data.alpha = alpha;
data.N = N;
data.D = D;
data.Fg = Fg;
data.T = T;
data.Torque = Torque;
data.M = M;
data.a = a;
data.vz_inf = vz_inf;
data.vx_inf = vx_inf;
data.az = az;
data.ax = ax;
data.Tx = Tx;
data.Tz = Tz;
data.Dx = Dx;
data.Dz = Dz;
data.Nx = Nx;
data.Nz = Nz;
end







