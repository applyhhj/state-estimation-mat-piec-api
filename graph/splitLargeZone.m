function [ zones ] = splitLargeZone( zones,C,N,maxZoneIdx )
nz=size(zones,2);
newZoneIdx=0;
newZones=[];
% the first zone is the reference bus
for k=2:nz
    replaced=0;
    restZone=[];
    if size(zones(k).buses,1)>N*1.1
        Ctmp=C(zones(k).buses,zones(k).buses);
        splitZones=BFSDivideGraph(Ctmp,zones(k).buses);
        for m=1:size(splitZones,2)
            while size(splitZones(m).graph,1)>N
                if ~replaced
                    zones(k).buses= splitZones(m).graph(1:N);
                    replaced=1;
                else
                    newZoneIdx=newZoneIdx+1;
                    newZones(newZoneIdx).buses=splitZones(m).graph(1:N);
                end
                splitZones(m).graph(1:N)=[];
            end
            % merge the rest of the zone
            restZone=[restZone;splitZones(m).graph];
        end
        
        while size(restZone,1)>N
            if ~replaced
                zones(k).buses= restZone(1:N);
                replaced=1;
            else
                newZoneIdx=newZoneIdx+1;
                newZones(newZoneIdx).buses=restZone(1:N);
            end
            restZone(1:N)=[];
        end
        
        if ~isempty(restZone)
            if ~replaced
                zones(k).buses= restZone;
                replaced=1;
            else
                newZoneIdx=newZoneIdx+1;
                newZones(newZoneIdx).buses=restZone;
            end
        end
    end
end

if ~isempty(newZones)
    for k=1:size(newZones,2)
        zones(nz+k).num=maxZoneIdx+k;
        zones(nz+k).buses=newZones(k).buses;
    end
end

end

