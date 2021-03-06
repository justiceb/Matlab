clc; close all; clear;

%Parse RAVEN
raven = parse_raven2('raven_raw.txt');
multiplier1 = 0.4728/min(raven.hz20.P);
raven.hz20.P = raven.hz20.P * multiplier1 * 101325;  %Pa
multiplier2 = 0.01; %37.37/3646;
raven.hz400.X = raven.hz400.X * multiplier2 * 9.80665;  %m/s^2

%parse Ardupilot
data = load('LOG00076.TXT');
time = data(:,1);
time = (time - time(1))*0.001 - 19.25;
pressure = data(:,2);
gps_alt = data(:,6)/100; %m
lat = data(:,4);
lat = lat*1E-7;
long = data(:,5);
long = long*1E-7;
sats = data(:,9);

%pressure altitudes
Hchart = 0:0.01:10;                    %km
Pchart = atmo_p(Hchart);               %Pa
p_alt = interp1(Pchart,Hchart,pressure)*1000;  %m
raven.hz20.alt = interp1(Pchart,Hchart,raven.hz20.P)*1000;  %m

%integrate accelerometer
[~,Iapogee] = max(raven.hz20.alt);
tapogee = raven.hz20.t(Iapogee);
Iapogee = interp1(raven.hz400.t,1:length(raven.hz400.t),tapogee,'nearest');
raven.hz400.v(1) = 0;    %(m/s)
raven.hz400.alt(1) = gps_alt(1);    %(m)
for n = 2:1:Iapogee
    dt = raven.hz400.t(n) - raven.hz400.t(n-1); %s
    raven.hz400.v(n) = raven.hz400.X(n-1) * dt + raven.hz400.v(n-1); %m/s
    raven.hz400.alt(n) = raven.hz400.v(n-1) * dt + raven.hz400.alt(n-1); %m/s
end

%nsats
for n = 1:1:length(sats)
   if sats(n) == 0
       gps_lock(n) = 1;
   else
       gps_lock(n) = 0;
   end
end

%gps tracker
gps_alt2 = gps_alt;
long2 = long;
lat2 = lat;
ind = [];
for n = 1:1:length(gps_alt)
    if gps_lock(n) == 1;
        ind = [ind n];
    end
end
gps_alt2=gps_alt(setdiff(1:length(gps_alt),ind));
long2=long(setdiff(1:length(long),ind));
lat2=lat(setdiff(1:length(lat),ind));
trajectory = [gps_alt2,long2,lat2];
[~,I2] = max(gps_alt2);
trajectory2 = [gps_alt2(1:I2),long2(1:I2),lat2(1:I2)];

figure(1)
m = 3.28084; %meters to feet
h = area(time,gps_lock*20000);
set(h(1),'FaceColor','y');
hold all
plot(raven.hz400.t(1:Iapogee),raven.hz400.alt*m,raven.hz20.t,raven.hz20.alt*m,time,p_alt*m,time,gps_alt*m)
set(gca,'YTickLabel',num2str(get(gca,'YTick').'))
xlabel('time (s)')
ylabel('altitude ASL (feet)')
legend('No GPS lock','Raven accelerometer altitude','Raven presure altitude','APM pressure altitude','GPS altitude',0)
grid on

figure(2)
plot(raven.hz400.t(1:Iapogee),raven.hz400.v*3.28084)

figure(3)
plot(raven.hz400.t,raven.hz400.X/9.80665)

