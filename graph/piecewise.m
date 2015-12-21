function [zone]=piecewise(baseMVA,bus,gen,branch)

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;

[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;

% add branch ids
brids=(1:size(branch,1))';
branch=[branch brids];
% add gen ids
genids=(1:size(gen,1))';
gen=[gen genids];

zones=sort(unique(bus(:,ZONE)));

zn=size(zones,1);
buses=cell(1,zn);
gens=cell(1,zn);
branches=cell(1,zn);
connbrf=cell(1,zn);
connbrt=cell(1,zn);
connbrf_bus_out=cell(1,zn);
connbrt_bus_out=cell(1,zn);

for k=1:zn
    zone(k).no=zones(k);
    %     piecewise buses
    zonebuses=bus(bus(:,ZONE)==zones(k),:);  
    buses(k)={zonebuses};
    zone(k).bus=zonebuses;
    
    %     piecewise gens
    [~,igen]=intersectRep(gen(:,GEN_BUS),zonebuses(:,BUS_I));    
    zonegens=gen(igen,:);    
    gens(k)={zonegens};
    zone(k).gen=zonegens;
    
    %     piecewise branches
    [~,ibrf]=intersectRep(branch(:,F_BUS),zonebuses(:,BUS_I));    
    [~,ibrt]=intersectRep(branch(:,T_BUS),zonebuses(:,BUS_I));    
    ibrzone=intersectRep(ibrf,ibrt);        
    branches(k)={branch(ibrzone,:)};
    zone(k).branch=branch(ibrzone,:);
    
    %   connection branches
    connbrf(k)={branch(diffRep(ibrf,ibrzone),:)};    
    connbrt(k)={branch(diffRep(ibrt,ibrzone),:)};
    zone(k).brconnf=branch(diffRep(ibrf,ibrzone),:);
    zone(k).brconnt=branch(diffRep(ibrt,ibrzone),:);

    %   buses of connection branches that are out of the zone
    %% ibus may have duplicated elements
    [~,ibus]=intersectRep(bus(:,BUS_I),branch(diffRep(ibrf,ibrzone),T_BUS));    
    connbrf_bus_out(k)={bus(ibus,:)};    
    zone(k).brconnf_out_bus=bus(ibus,:);
    [~,ibus]=intersectRep(bus(:,BUS_I),branch(diffRep(ibrt,ibrzone),F_BUS));    
    connbrt_bus_out(k)={bus(ibus,:)};    
    zone(k).brconnt_out_bus=bus(ibus,:);
    
    % assign S base
    zone(k).baseMVA=baseMVA;
end
