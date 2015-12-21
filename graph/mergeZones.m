function [newZones] = mergeZones( zones,branch,N)

% [F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
%     TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
%     ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;

% %% check if there are connected zones
% zonesToMerge=[];
% for k=1:size(branch,1)
%     f=branch(k,F_BUS);
%     t=branch(k,T_BUS);
%     for kf=1:size(zones,2)
%         for kt=1:size(zones,2)
%             if kf==kt
%                 continue;
%             end
%             nf=size(zones(kf).buses,1);
%             nt=size(zones(kt).buses,1);
%             if  ismember(f,zones(kf).buses)&&ismember(t,zones(kt).buses)&&...
%                     nf+nt<=N
%                 zonesToMerge=[zonesToMerge;min(kf,kt) max(kf,kt) N-nf-nt];
%             end
%         end
%     end
% end
% zonesToMerge=sortrows(unique(zonesToMerge,'rows'),3);
% zonesToMerge=zonesToMerge(:,1:2);
% 
% %% first merge
% for k=1:size(zonesToMerge,1)
%     idxf=zonesToMerge(k,1);
%     idxt=zonesToMerge(k,2);
%     if idxf<0||idxt<0
%         continue;
%     end
%     zones(idxf).buses=[zones(idxf).buses;zones(idxt).buses];
%     zones(idxt)=[];
%     zonesToMerge(zonesToMerge==idxf)=-1;
% end

%% merge according to number of buses in each zone
% sort zones according to number of buses
for m=1:size(zones,2)
    nbm=size(zones(m).buses,1);
    for n=m+1:size(zones,2)
        nbn=size(zones(n).buses,1);
        if nbm>nbn
            zoneTmp=zones(m);
            zones(m)=zones(n);
            zones(n)=zoneTmp;
            nbm=nbn;
        end
    end
end

% merge
nz=size(zones,2);
m=1;
newZones=[];
while m<nz
    n=m+1;
    nsum=size(zones(m).buses,1);
    nbn=size(zones(n).buses,1);
    if nsum+nbn>N
        break;
    end
    while n<=nz
        nbn=size(zones(n).buses,1);
        nsum=nsum+nbn;
        if nsum<N
            n=n+1;
        else
            % merge
            newZones=[newZones;getMergedZone(zones,m,n-1)];
            m=n;
            break;
        end
    end
    
    if n>nz
        newZones=[newZones;getMergedZone(zones,m,n-1)];
        m=n;
    end
end

for k=m:nz
    newZones=[newZones;zones(k)];
end

    function nZone=getMergedZone(zones,m,n)
        nZone.num=zones(m).num;
        nZone.buses=[];
        for l=m:n
            nZone.buses=[nZone.buses;zones(l).buses];
        end
    end

end
