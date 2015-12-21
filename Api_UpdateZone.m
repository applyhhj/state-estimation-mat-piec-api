function [ zone ] = Api_UpdateZone( zone,VExt )

%% update connection branches
brconnf=updateBranchPf(zone.baseMVA,zone.brconnf,zone.Yfconnf,zone.Ytconnf,[zone.VEst;VExt]);
brconnt=updateBranchPf(zone.baseMVA,zone.brconnt,zone.Yfconnt,zone.Ytconnt,[zone.VEst;VExt]);
zone.brconn=int2extBr(zone.ii2efull,[brconnf;brconnt]);

%% update other states
IExt=zone.YbusExt*VExt;
[bus, gen, branch] = pfsoln_benchmark(zone.baseMVA, zone.bus, zone.gen, zone.branch,...
    zone.Ybus, zone.Yf, zone.Yt, zone.VEst, zone.ref, zone.pv, zone.pq,IExt);
[zone.bus, zone.gen, zone.branch] = int2ext(zone.ii2e, bus, gen, branch);
end

