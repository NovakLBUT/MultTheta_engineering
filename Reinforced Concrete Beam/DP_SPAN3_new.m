function [TP]=DP_SPAN3_new(X)
% Design Parameters of CBP with three span

% Penalty Coefficient
TP.PEN=10^8;
% Uniformly Distributed Dead Load on Beam (kN/m)
TP.YAYILI_G=[X(1) X(2) X(3)];
% Uniformly Distributed Live Load on Beam (kN/m)
TP.YAYILI_Q=[X(4) X(5) X(6)];
% Concrete unit volume weight (kN/m3)
TP.BA_beton=25;
% Upper column dimensions (mm)
TP.ustkolon_HK=[500 500 500 500];
TP.ustkolon_BW=[300 400 400 400];
% Lower column dimensions (mm)
TP.altkolon_HK=[500 500 500 500];
TP.altkolon_BW=[300 400 400 400];
% Beam width (mm)
TP.kiris_BW=[250 250 250];
% Beam span (mm)
TP.L_kiris=[8000 4000 9000];
% Upper story height (mm)
TP.L_kolonust=3000;
% Lower story height (mm)
TP.L_kolonalt=3000;
% Max. aggregate diameter (mm)
TP.Dmax=16;
% Stirrup diameter (mm)
TP.etrcap=8; 
% Earthquake Design Class
TP.DTS='1a';
% Clear concrete cover (mm)
TP.Cnet=25;

% Column Bearing Capacity
TP.Mr_col_a=[252.12	318.47	321.35	312.70];
TP.Mr_col_u=[256.11	326.84	329.38	321.35];
% Reinforcement Template Data Pool
[TP.N1,TP.FI1,TP.N2,TP.FI2,TP.N3,TP.FI3,TP.N4,TP.FI4,TP.ALAN,TP.KOD]=textread('donatiindeks_250_fi24_etr8.txt','%f %f %f %f %f %f %f %f %f %f');
fcd_base =X(7);
Ec_correlated = 4700 * sqrt(fcd_base * 1.5) * (1 + 0.1*randn());
fctd_correlated = 0.3 * (fcd_base * 1.5)^(2/3) * (1 + 0.15*randn());
k1_correlated = max(0.65, 0.85 - 0.002*max(0, fcd_base*1.5 - 50));


% Concrete Properties Data Repository 
TP.Ec_data=[30000	32000	33000	Ec_correlated	36000	37000]; % MPa
TP.fcd_data=[16.7	20.0	23.3	fctd_correlated	30.0	33.3];  % MPa
TP.fctd_data=[1.20	1.26	1.31	fcd_base	1.53	1.66];  % MPa
TP.k1_data=[0.85	0.82	0.79	k1_correlated	0.73	0.70];
TP.Csinif=["C25" "C30" "C35" "C40" "C45" "C50"]; 

% Reinforcement Properties Data Pool
TP.fyd_data=[365 X(8)];          % MPa
TP.Fsinif=["B420C" "B500C"];


% Beam Height Data Pool (mm)
TP.DDHK=300:50:1050;                   

% Stirrup Spacing Data Pool (mm)
TP.etr_ara=50:10:350;

% Unit Cost Data Pool
TP.Cc_data=[47.26	49.06	52.35	55.34	56.24	58.03]; % $/ m3
TP.Cs_data=[0.78 0.78]; % $/kg










