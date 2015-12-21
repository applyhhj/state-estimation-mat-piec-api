function [outdiff,zoneBuses]=compareEst(casedata,N,mpopt)
global debug reassign
% [busBench, genBench, branchBench, success]=runBench(casedata,mpopt);
% clearvars -except mpopt casedata busBench genBench branchBench

[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;

outdiff=[{0},{0},{0},{0}];
zoneBuses=[];

if debug==1
    [~, bus, ~, ~] = loadcase(casedata);
    if size(bus,1)>300
        return;
    end
end

[baseMVA, bus, gen, branch, success,i2e,Sbuslf] = solvePowerFlow(casedata,mpopt);

if ~success
    return;
end

if reassign
    bus=reassignZone(bus,gen,branch,N);
else
    [ref, ~, ~] = getBusType(bus, gen);
    bus(ref,ZONE)=-1;
    bus(ref,BUS_AREA)=-1;
    zones=sort(unique(bus(:,ZONE)));
    areas=sort(unique(bus(:,BUS_AREA)));
    if size(zones,1)<size(areas,1)
        bus(:,ZONE)=bus(:,BUS_AREA);       
    end
end

zoneStruct=piecewise(baseMVA,bus,gen,branch);

% add branch ids
brids=(1:size(branch,1))';
branch=[branch brids];
% add gen ids
genids=(1:size(gen,1))';
gen=[gen genids];

busPiec=[];
genPiec=[];
branchPiec=[];
brconnPiec=[];
convergedoPiec=[];

for k=1:size(zoneStruct,2)
    zoneBuses(k,:)=[zoneStruct(k).no,size(zoneStruct(k).bus,1)];
    [busi,geni,branchi,brconni, convergedi]=runEstimateStruct(zoneStruct(k),mpopt);
    busPiec=[busPiec;busi];
    genPiec=[genPiec;geni];
    branchPiec=[branchPiec;branchi];
    brconnPiec=[brconnPiec;brconni];
    convergedoPiec=[convergedoPiec,convergedi];
end

[r,c]=size(brconnPiec);
brconnPiec=sortrows(brconnPiec,c);
% average sf st, sf st are computed twice
brconnPiec=(brconnPiec(1:2:r,:)+brconnPiec(2:2:r,:))/2;
branchPiec=[branchPiec;brconnPiec];

[bus, gen, branch] = int2ext(i2e, bus, gen, branch);
[busPiec, genPiec, branchPiec] = int2ext(i2e, busPiec, genPiec, branchPiec);
converged=k-sum(convergedoPiec);
if converged==0
    converged=1;
else
    converged=0;
end
success={success};
converged={converged};

busPiecSort=sortrows(busPiec,1:size(busPiec,2));
% genPiecSort=sortrows(genPiec,1:size(genPiec,2));
% branchPiecSort=sortrows(branchPiec,1:size(branchPiec,2));
genPiecSort=sortrows(genPiec,size(genPiec,2));
branchPiecSort=sortrows(branchPiec,size(branchPiec,2));

busSort=sortrows(bus,1:size(bus,2));
% genSort=sortrows(gen,1:size(gen,2));
% branchSort=sortrows(branch,1:size(branch,2));
genSort=sortrows(gen,size(gen,2));
branchSort=sortrows(branch,size(branch,2));

outdiff=[{busSort-busPiecSort},{genSort-genPiecSort},{branchSort-branchPiecSort},converged,success];

end