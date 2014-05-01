function test
%BALLODE  Run a demo of a bouncing ball.  
%   This is an example of repeated event location, where the initial
%   conditions are changed after each terminal event.  This demo computes ten
%   bounces with calls to ODE23.  The speed of the ball is attenuated by 0.9
%   after each bounce. The trajectory is plotted using the output function
%   ODEPLOT. 
%
%   See also ODE23, ODE45, ODESET, ODEPLOT, FUNCTION_HANDLE.

%   Mark W. Reichelt and Lawrence F. Shampine, 1/3/95
%   Copyright 1984-2004 The MathWorks, Inc.
%   $Revision: 1.17.4.2 $  $Date: 2005/06/21 19:24:10 $
abe = 1;
tstart = 0;
tfinal = 30;
y0 = [0; 20];
refine = 4;
options = odeset('Events',@events,'OutputFcn',@odeplot,'OutputSel',1,...
                 'Refine',refine);

figure;
set(gca,'xlim',[0 30],'ylim',[0 25]);
box on
hold on;

tout = tstart;
yout = y0.';
teout = [];
yeout = [];
ieout = [];
for i = 1:10
  % Solve until the first terminal event.
  [t,y,te,ye,ie] = ode23(@f,[tstart tfinal],y0,options,abe);
  if ~ishold
    hold on
  end
  % Accumulate output.  This could be passed out as output arguments.
  nt = length(t);
  tout = [tout; t(2:nt)];
  yout = [yout; y(2:nt,:)];
  teout = [teout; te];          % Events at tstart are never reported. 
  yeout = [yeout; ye];
  ieout = [ieout; ie];

  ud = get(gcf,'UserData');
  if ud.stop
    break;
  end
  
  % Set the new initial conditions, with .9 attenuation.
  y0(1) = 0;
  y0(2) = -.9*y(nt,2);

  % A good guess of a valid first timestep is the length of the last valid
  % timestep, so use it for faster computation.  'refine' is 4 by default.
  options = odeset(options,'InitialStep',t(nt)-t(nt-refine),...
                           'MaxStep',t(nt)-t(1));

  tstart = t(nt);
end

plot(teout,yeout(:,1),'ro')
xlabel('time');
ylabel('height');
title('Ball trajectory and the events');
hold off
odeplot([],[],'done');

% --------------------------------------------------------------------------

function dydt = f(t,y,abe)
dydt = [y(2); -9.8];

% --------------------------------------------------------------------------

function [value,isterminal,direction] = events(t,y,abe)
% Locate the time when height passes through zero in a decreasing direction
% and stop integration.  
value = y(1)     % detect height = 0
isterminal = 1   % stop the integration
direction = -1   % negative direction
