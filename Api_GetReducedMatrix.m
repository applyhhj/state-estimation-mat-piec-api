function [ zone ] = Api_GetReducedMatrix( zone )
    %% find reduced Hessian, covariance matrix, measurements
    zone.HH = zone.H(zone.vv,zone.ww);
    zone.WWInv = zone.WInv(zone.vv,zone.vv);
    zone.ddelz = zone.delz(zone.vv);
    zone.VVa = angle(zone.VEst(zone.nref));
    zone.VVm = abs(zone.VEst(zone.nref));
end

