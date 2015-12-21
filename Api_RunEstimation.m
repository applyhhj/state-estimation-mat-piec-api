function [ zone,converged ] = Api_RunEstimation( zone,mpopt )
%% default arguments
if nargin < 2
    mpopt = mpoption;
end

[ zone ] = ApiPrepareEstimation( zone );
zone.z=zone.zTrue;
VExt=zone.VExtlf;
%% begin estimation
if ~isempty(zone.ref)&&isempty(zone.f)
    converged=1;
else
    [zone, converged, i] = ApiStateEstimate(zone,VExt, mpopt);
    if~isempty(zone.ref)
        zone.VEst(zone.ref(1))=zone.VRef;
    end
end

zone = Api_UpdateZone( zone,VExt );
end

