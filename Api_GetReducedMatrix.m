function [ zone ] = Api_GetReducedMatrix( zone,VExt )
%% find reduced Hessian, covariance matrix, measurements
% we use Vlf as the initial value of VEst to create H matrix we can not use
% flat start for case case2869pegase and case case9241pegase as bad data
% recognization will reject too many measurements that the iteration can
% not converge. (rank(HH) is less than number of state that need to be estimated)

if ~isfield(zone,'H')&&nargin>1
    zone.H= ApiGetH( zone,VExt );
%     zone.VEst=ones(zone.bn,1);
end
if ~isfield(zone,'VVa')
    zone.VVa = angle(zone.VEst(zone.nref));
end
if ~isfield(zone,'VVm')
    zone.VVm = abs(zone.VEst(zone.nref));
end
zone.HH = zone.H(zone.vv,zone.ww);
zone.WWInv = zone.WInv(zone.vv,zone.vv);
zone.ddelz = zone.delz(zone.vv);
end

