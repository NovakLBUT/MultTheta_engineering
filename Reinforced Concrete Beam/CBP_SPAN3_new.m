function Y=CBP_SPAN3_new(X)
% CBP with two span
Foodsi=[2842	3456	11	3	12	2	1	5	30	2	5	4	31];
% Reading Design Parameters and Data Pool
[TP]=DP_SPAN3_new(X);

% Assignment of Design Variables
PRM.ASALUST_DONATI_food=Foodsi(1);  % Top Reýnforcement Template No.
PRM.ASALALT_DONATI_food=Foodsi(2);  % Bottom Reýnforcement Template No.
HK1=TP.DDHK(Foodsi(3));             % Height of Beam 1
HK2=TP.DDHK(Foodsi(4));             % Height of Beam 2 
HK3=TP.DDHK(Foodsi(5));             % Height of Beam 3 
PRM.fcd=TP.fcd_data(Foodsi(6));         % Design compressive strength of concrete
PRM.fctd=TP.fctd_data(Foodsi(6));       % Design tensile strength of concrete
PRM.k1=TP.k1_data(Foodsi(6));           % Equivalent compression block depth coefficient
PRM.Ec=TP.Ec_data(Foodsi(6));           % Modulus of elasticity of concrete
PRM.fyd=TP.fyd_data(Foodsi(7));         % Yield strength of reinforcement
PRM.CC=TP.Cc_data(Foodsi(6));           % Unit cost of concrete
PRM.CST=TP.Cs_data(Foodsi(7));          % Unit cost of steel
% Stirrup spacing in the confinement zone
PRM.s_sar=[TP.etr_ara(Foodsi(8)) TP.etr_ara(Foodsi(10)) TP.etr_ara(Foodsi(12))];
% Stirrup spacing in the mid zone
PRM.s_orta=[TP.etr_ara(Foodsi(9)) TP.etr_ara(Foodsi(11)) TP.etr_ara(Foodsi(13))];

PRM.kiris_HK=[HK1 HK2 HK3];
%% STRUCTURAL ANALYSIS MODULE
[PRM.MOM,PRM.KESME]=CONTBEAM_2D_SPAN3(TP,PRM);
FIRS=[PRM.MOM(1,1) PRM.MOM(1,2) PRM.MOM(1,3) PRM.MOM(2,1) PRM.MOM(2,2) PRM.MOM(2,3)...
    PRM.MOM(3,1) PRM.MOM(3,2) PRM.MOM(3,3) PRM.KESME(1,1) PRM.KESME(1,2) PRM.KESME(2,1) PRM.KESME(2,2)...
    PRM.KESME(3,1) PRM.KESME(3,2)];
%% TOP AND BOTTOM REINFORCEMENT MODULES 
[PRM.UST_IND,PRM.UST_AS,PRM.UST_d,PRM.UST_MR,PRM.UST_RHO]=SELECT_TOP_TEMPLATE(TP,PRM);
[PRM.ALT_IND,PRM.ALT_AS,PRM.ALT_MR,PRM.ALT_RHO]=SELECT_BOT_TEMPLATE(TP,PRM);
sec=[PRM.UST_MR(1,1) PRM.UST_MR(1,2) PRM.UST_MR(1,3) PRM.UST_MR(2,1) PRM.UST_MR(2,2) PRM.UST_MR(2,3)...
    PRM.UST_MR(3,1) PRM.UST_MR(3,2) PRM.UST_MR(3,3)...
    PRM.UST_RHO(1,1) PRM.UST_RHO(1,2) PRM.UST_RHO(1,3) PRM.UST_RHO(2,1) PRM.UST_RHO(2,2) PRM.UST_RHO(2,3)...
    PRM.UST_RHO(3,1) PRM.UST_RHO(3,2) PRM.UST_RHO(3,3)...
    PRM.ALT_MR(1,1) PRM.ALT_MR(1,2) PRM.ALT_MR(1,3)];
%% SHEAR REINFORCEMENT MODULE
[PRM.VD,PRM.VR,PRM.Vcr,PRM.ASW,PRM.ETR_SAY,PRM.ETR_AGIRLIK]=SHEAR(TP,PRM);

%% TOP AND BOTTOM REINFORCEMENT LAYOUTS MODULES
[PRM.W_DON_UST,PRM.DON_UST,PRM.FI_UST,PRM.DONATI_BOY_UST]=TOP_REBAR_SPAN3(TP,PRM);  
[PRM.W_DON_ALT,PRM.DON_ALT,PRM.FI_ALT,PRM.DONATI_BOY_ALT]=BOT_REBAR_SPAN3(TP,PRM);

%% WEB REINFORCEMENT MODULE
[PRM.W_DON_GOVDE,PRM.govde_fi]=WEB_REBAR(TP,PRM);

%% CONSTRAINT CALCULATION MODULE
% g = CONSTRAINT_MODULE_SPAN3(TP,PRM);
% اینها را با ML جایگزین کنید:
PRM.MOM, PRM.KESME                   
PRM.UST_MR, PRM.ALT_MR, PRM.UST_RHO 
Y=[FIRS sec];
end