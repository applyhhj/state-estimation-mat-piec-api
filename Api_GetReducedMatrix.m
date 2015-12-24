function [ zone ] = Api_GetReducedMatrix( zone )
%% find reduced Hessian, covariance matrix, measurements
% if H is updated by the estimated state then
% we have to use Vlf as the initial value of VEst to create H matrix and we can not use
% flat start for case case2869pegase and case case9241pegase as bad data
% recognization will reject too many measurements that the iteration can
% not converge. (rank(HH) is less than number of state that need to be estimated)

% however if we use power flow data, which represent the real state of the
% system to create H matrix and keep it constant all through the estimation
% then we can use flat start. here we do it this way.

if ~isfield(zone,'H')
    zone.H= ApiGetH( zone );
    zone.VEst=ones(zone.bn,1);
end
if ~isfield(zone,'VVa')
    zone.VVa = angle(zone.VEst(zone.nref));
end
if ~isfield(zone,'VVm')
    zone.VVm = abs(zone.VEst(zone.nref));
end
zone.HH = zone.H(zone.vv,zone.ww);
zone.WW=zone.W(zone.vv,zone.vv);
zone.WWInv = zone.WInv(zone.vv,zone.vv);
zone.ddelz = zone.delz(zone.vv);
end

