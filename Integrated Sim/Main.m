run clc; clear; close all
addpath Common_Functions
addpath_recurse('Config_Files')
addpath Balloon_Shape
addpath Ascent
addpath Rockoon_Flight
addpath Descent

%% Inputs
input.m_payload = 0;                 %(kg)
input.m_balloon = 0;                 %(kg)
input.V_H2_surplus = 40 * 0.0283168; %(m^3) surplus volume of H2 added to balloon
input.lat0 =  40.416275;
input.long0 = -86.944016;
input.alt0 = 180;                    %(m)
input.Drocket = 54 * 0.001;          %(m) rocket body diameter
input.Afin = 0.0129032;              %(m^2) Aref for fin
input.alt_chute = 5000 * 0.3048;     %(m) parachute deployment altitude
input.Dparachute = 36 * 0.0254;      %(m) parachute diameter

%% Configs
config.wind = load_Wyoming_Sounding('12Z_05_May_2014.csv');
config.rasaero = load_RASAero_aeroplot1('RASAero_aeroplot1.csv');
config.rocksim = load_rocksim('rocksim.csv');

%Modify Config data
config.wind.SKNT = config.wind.SKNT*0.514444;       %convert windspeed to m/s
config.wind.DRCT = -config.wind.DRCT+270;           %convert to degrees where 0=east, 90=north

%% Balloon Shape
run create_balloon

%determine variables to keep
balloon.V = V;                        %(m^3) balloon volume when deployed
balloon.m_balloon = S*wd;             %(kg) predicted balloon mass
balloon.m_payload = Wpayload/g;       %(kg) payload mass
balloon.z = z;                        %(m) balloon height as a function of S

%clear all variables but balloon struct
clearvars -except input config balloon

%% Ascent Calculator
run Ascent

%determine variables to keep
ascent.sz = sz;
ascent.vz = vz;
ascent.t = t;
ascent.lat = lat;
ascent.long = long;

%clear all variables but balloon and ascent structs
clearvars -except input config balloon ascent

%% Rockoon Launch
run rockoon_launch

rockoon.sz = sz;
rockoon.long = long;
rockoon.lat = lat;
rockoon.vxx = vxx;
rockoon.vyy = vyy;

%clear all variables but balloon and ascent structs
clearvars -except input config balloon ascent rockoon

%% Descent
run Descent

descent.sz1 = sz1;
descent.long1 = long1;
descent.lat1 = lat1;
descent.sz2 = sz2;
descent.long2 = long2;
descent.lat2 = lat2;

%clear all variables but balloon and ascent structs
%clearvars -except input config balloon ascent rockoon descent

%% Formulate trajectory
trajectory = [[ascent.sz; rockoon.sz; descent.sz1; descent.sz2] ...
              [ascent.long'; rockoon.long'; descent.long1'; descent.long2'] ...
              [ascent.lat'; rockoon.lat'; descent.lat1'; descent.lat2']];













