function [bus, gen, branch] = pfsoln_benchmark(baseMVA, bus0, gen0, branch0, Ybus, Yf, Yt, V, ref, pv, pq,IExt)
%PFSOLN  Updates bus, gen, branch data structures to match power flow soln.
%   [BUS, GEN, BRANCH] = PFSOLN(BASEMVA, BUS0, GEN0, BRANCH0, ...
%                                   YBUS, YF, YT, V, REF, PV, PQ)

%   MATPOWER
%   Copyright (c) 1996-2015 by Power System Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%
%   $Id: pfsoln.m 2644 2015-03-11 19:34:22Z ray $
%
%   This file is part of MATPOWER.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See http://www.pserc.cornell.edu/matpower/ for more info.

%% define named indices into bus, gen, branch matrices
[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;

%% zero IExt
if nargin<12
   IExt=zeros(size(V,1),1); 
end

%% initialize return values
bus     = bus0;
gen     = gen0;
branch  = branch0;

%%----- update bus voltages -----
bus(:, VM) = abs(V);
bus(:, VA) = angle(V) * 180 / pi;

%%---- bus injections at PQ buses----
Sbus = V .* conj(Ybus * V+IExt);
bus(pq, PD) = -real(Sbus(pq)) * baseMVA;
bus(pq, QD) = -imag(Sbus(pq)) * baseMVA;

%%----- update Qg for gens at PV/slack buses and Pg for slack bus(es) -----
%% generator info
on = find(gen(:, GEN_STATUS) > 0 & ...  %% which generators are on?
        bus(gen(:, GEN_BUS), BUS_TYPE) ~= PQ);  %% ... and not at PQ buses
off = find(gen(:, GEN_STATUS) <= 0);    %% which generators are off?
gbus = gen(on, GEN_BUS);                %% what buses are they at?

%% compute total injected bus powers
Sbus = V(gbus) .* conj(Ybus(gbus, :) * V+IExt(gbus));

%% update Qg for generators at PV/slack buses
gen(off, QG) = zeros(length(off), 1);   %% zero out off-line Qg
%% don't touch the ones at PQ buses
gen(on, QG) = imag(Sbus) * baseMVA + bus(gbus, QD); %% inj Q + local Qd

%% total PG at each bus
gen(on, PG) = real(Sbus) * baseMVA + bus(gbus, PD); %% inj Q + local Qd

%% ... at this point any buses with more than one generator will have
%% the total P Q dispatch for the bus assigned to each generator. This
%% must be split between them. We do it first equally, then in proportion
%% to the reactive range of the generator.

%% currently we spile P just like Q, however in the original data, P 
%% is not split this way so here is just for test
if length(on) > 1
    %% build connection matrix, element i, j is 1 if gen on(i) at bus j is ON
    nb = size(bus, 1);
    ngon = size(on, 1);
    Cg = sparse((1:ngon)', gbus, ones(ngon, 1), ngon, nb);

    %% divide Pg by number of generators at the bus to distribute equally
    ngg = Cg * sum(Cg)';    %% ngon x 1, number of gens at this gen's bus
    gen(on, PG) = gen(on, PG) ./ ngg;

    %% divide proportionally
    Cmin = sparse((1:ngon)', gbus, gen(on, PMIN), ngon, nb);
    Cmax = sparse((1:ngon)', gbus, gen(on, PMAX), ngon, nb);
    Pg_tot = Cg' * gen(on, PG);     %% nb x 1 vector of total Pg at each bus
    Pg_min = sum(Cmin)';            %% nb x 1 vector of min total Pg at each bus
    Pg_max = sum(Cmax)';            %% nb x 1 vector of max total Pg at each bus
    ig = find(Cg * Pg_min == Cg * Pg_max);  %% gens at buses with Pg range = 0
    Pg_save = gen(on(ig), PG);
    gen(on, PG) = gen(on, PMIN) + ...
        (Cg * ((Pg_tot - Pg_min)./(Pg_max - Pg_min + eps))) .* ...
            (gen(on, PMAX) - gen(on, PMIN));    %%    ^ avoid div by 0
    gen(on(ig), PG) = Pg_save;
end    

%% split Q
if length(on) > 1
    %% build connection matrix, element i, j is 1 if gen on(i) at bus j is ON
    nb = size(bus, 1);
    ngon = size(on, 1);
    Cg = sparse((1:ngon)', gbus, ones(ngon, 1), ngon, nb);

    %% divide Qg by number of generators at the bus to distribute equally
    ngg = Cg * sum(Cg)';    %% ngon x 1, number of gens at this gen's bus
    gen(on, QG) = gen(on, QG) ./ ngg;

    %% divide proportionally
    Cmin = sparse((1:ngon)', gbus, gen(on, QMIN), ngon, nb);
    Cmax = sparse((1:ngon)', gbus, gen(on, QMAX), ngon, nb);
    Qg_tot = Cg' * gen(on, QG);     %% nb x 1 vector of total Qg at each bus
    Qg_min = sum(Cmin)';            %% nb x 1 vector of min total Qg at each bus
    Qg_max = sum(Cmax)';            %% nb x 1 vector of max total Qg at each bus
    ig = find(Cg * Qg_min == Cg * Qg_max);  %% gens at buses with Qg range = 0
    Qg_save = gen(on(ig), QG);
    gen(on, QG) = gen(on, QMIN) + ...
        (Cg * ((Qg_tot - Qg_min)./(Qg_max - Qg_min + eps))) .* ...
            (gen(on, QMAX) - gen(on, QMIN));    %%    ^ avoid div by 0
    gen(on(ig), QG) = Qg_save;
end                                             %% (terms are mult by 0 anyway)

%% update Pg for slack gen(s)
for k = 1:length(ref)
    refgen = find(gbus == ref(k));              %% which is(are) the reference gen(s)?
    gen(on(refgen(1)), PG) = real(Sbus(refgen(1))) * baseMVA ...
                            + bus(ref(k), PD);  %% inj P + local Pd
    if length(refgen) > 1       %% more than one generator at this ref bus
        %% subtract off what is generated by other gens at this bus
        gen(on(refgen(1)), PG) = gen(on(refgen(1)), PG) ...
                                - sum(gen(on(refgen(2:length(refgen))), PG));
    end
end

%%----- update/compute branch power flows -----
branch=updateBranchPf(baseMVA,branch,Yf,Yt,V);
% out = find(branch(:, BR_STATUS) == 0);      %% out-of-service branches
% br = find(branch(:, BR_STATUS));            %% in-service branches
% Sf = V(branch(br, F_BUS)) .* conj(Yf(br, :) * V) * baseMVA; %% complex power at "from" bus
% St = V(branch(br, T_BUS)) .* conj(Yt(br, :) * V) * baseMVA; %% complex power injected at "to" bus
% branch(br, [PF, QF, PT, QT]) = [real(Sf) imag(Sf) real(St) imag(St)];
% branch(out, [PF, QF, PT, QT]) = zeros(length(out), 4);
