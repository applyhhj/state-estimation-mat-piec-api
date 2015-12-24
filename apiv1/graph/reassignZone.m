function [ bus0 ] = reassignZone( bus,gen,branch,N )
%% define named indices into bus, branch matrices
[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;

%% bus numbers should be converted to internal consecutive numbers
bn=size(bus,1);
bus0=bus;
if any(bus(:, BUS_I) ~= (1:bn)')
    [~, bus, gen, branch] = ext2int(bus, gen, branch);
end

%% split system
% normally we should not split the system when the number of buses is not
% large, however due to the bug of the original estimator we have to split
% the reference bus so that the estimator can get more accurate result.
[ref, ~, ~] = getBusType(bus, gen);
if bn<N
    zone=ones(bn,1);
    zone(ref)=0;
    bus0(:,ZONE)=zone;
    return;
end

%% compute connection matrix
% convert to symmetric matrix
C=sparse(branch(:,F_BUS),branch(:,T_BUS),1,bn,bn);
C=C+C';

%% get buses of each zone
% use 0 for reference bus
zoneNums=bus(:,ZONE);
maxZoneIdx=max(bus(:,ZONE));
zoneRef.num=zoneNums(ref);
zoneRef.buses=bus(bus(:,ZONE)==zoneRef.num,BUS_I);

% check the rest of the zone that contains ref bus is connected, if not
% reassign the zone number
if size(zoneRef.buses,1)>1
    i2e=setdiff(zoneRef.buses,ref);
    Ctmp=C(i2e,i2e);
    subZones=BFSDivideGraph(Ctmp,i2e);
    if size(subZones,2)>1
        for k=2:size(subZones,2)
            zoneNums(subZones(k).graph)=maxZoneIdx+k-1;
        end
    end
end

zoneNums(ref)=-1;
bus(ref,ZONE)=-1;
zoneIds=sort(unique(zoneNums));
for k=1:size(zoneIds,1)
    zones(k).num=zoneIds(k);
    zones(k).buses=bus(bus(:,ZONE)==zones(k).num,BUS_I);
end

%% split rest systems after splitting the reference bus
zones=splitLargeZone(zones,C,N,maxZoneIdx);
zoneRef=zones(1);
% do not merge reference zone
[zones]=mergeZones(zones(2:end),branch,N);
zones=[zoneRef;zones];

%% reassign zone number
for k=1:size(zones,1)
    zoneNums(zones(k).buses)=k-1;
end
bus0(:,ZONE)=zoneNums;

end

