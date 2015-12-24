function [ HH,WW,WWInv,ddelz ] = Api_V1_GetReducedMatrix( H,W,WInv,delz,vv,ww )
%% find reduced Hessian, covariance matrix, measurements
% if H is updated by the estimated state then
% we have to use Vlf as the initial value of VEst to create H matrix and we can not use
% flat start for case case2869pegase and case case9241pegase as bad data
% recognization will reject too many measurements that the iteration can
% not converge. (rank(HH) is less than number of state that need to be estimated)

% however if we use power flow data, which represent the real state of the
% system to create H matrix and keep it constant all through the estimation
% then we can use flat start. here we do it this way.

HH = H(vv,ww);
WW=W(vv,vv);
WWInv = WInv(vv,vv);
ddelz = delz(vv);
end

