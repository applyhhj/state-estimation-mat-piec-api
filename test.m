clc;clear;

[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;

load('zoneStruct');
zone1=zoneStruct(2);

[i2e, bus, gen, branch] = ext2int(zone1.bus, zone1.gen, zone1.branch);

bn=size(bus,1);
C=sparse(branch(:,F_BUS),branch(:,T_BUS),1,bn,bn);
C=C+C';

subZones=BFSDivideGraph(C);

load('vv');

mbus=[branch(:,F_BUS);branch(:,T_BUS);(1:bn)';(1:bn)';branch(:,F_BUS);branch(:,T_BUS);(1:bn)';(1:bn)'];
mbusnew=mbus(vvnew);
l=0;
ids=[];
for k=1:bn
    idx=bus(k,1);
    rb=size(mbusnew(mbusnew==idx),1);
   if rb<2;
       ids=[ids;idx];
      fprintf('\n bus %d can not be observed.',idx);       
      l=l+1;
   end
end

fprintf('\ntotal %d',l);

