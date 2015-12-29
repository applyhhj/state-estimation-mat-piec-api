function [ delz,normF,vv ] = Api_V2_FirstEstimation( VaEst,VmEst,VaExt,VmExt,z,zone )
VEst=VmEst.*cos(VaEst)+VmEst.*sin(VaEst)*1j;
VExt=VmExt.*cos(VaExt)+VmExt.*sin(VaExt)*1j;
% input are row vectors, need to transpose
[ delz,normF,vv ] = Api_V1_FirstEstimation( VEst',VExt',z',...
    zone.ref,zone.nb,zone.nbr,...
    zone.f,zone.t,zone.Yf,zone.Yt,zone.Ybus,zone.YbusExt,zone.WInv);

end

