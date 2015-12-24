function [ zone ] = Api_EstimateOnce( zone,VExt )
%% compute update step
F = zone.HH' * zone.WWInv * zone.ddelz;
J = zone.HH' * zone.WWInv * zone.HH;
dx = (J \ F);

if ~isempty(find(isnan(dx),1))
    warning('\n\t*****Case %s ,%d has unobservable states after bad data recognization.',zone.case,zone.no);
end

%% update voltage
nstat=size(zone.ww,1)/2;
zone.VVa = zone.VVa + dx(1:nstat);
zone.VVm = zone.VVm + dx(nstat+1:end);
zone.VEst(zone.nref) = zone.VVm .* exp(1j * zone.VVa);

%% udpate H matrix
% we treat H as a constant matrix
% if nargin>2
%     [zoen.H,zone.HH] = ApiGetH( zone,VExt );
% end

%% compute estimated measurement
z_est=Api_ComputeEstimate( zone,VExt );

%% measurement residual
zone.delz = zone.z - z_est;
zone.ddelz = zone.delz(zone.vv);
zone.normF = zone.ddelz' * zone.WWInv * zone.ddelz;

%% check for convergence
zone.step = dx' * dx;

end

