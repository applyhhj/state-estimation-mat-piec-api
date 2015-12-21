clc;clear;close all;

casedata='case1354pegase';
% [F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
%     TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
%     ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;

N=300;

[baseMVA, bus, gen, branch] = loadcase(casedata);

bus = reassignZone( bus,gen,branch,N );

fprintf('Done!\n');