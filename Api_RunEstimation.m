function [ zone,converged ] = Api_RunEstimation( zone,mpopt )
%% default arguments
if nargin < 2
    mpopt = mpoption;
end

[ zone ] = Api_PrepareEstimation( zone );

%% measurement with error
err = normrnd( zeros(size(zone.sigma)), zone.sigma );
zone.z=zone.zTrue+err*0;

VExt=zone.VExtlf;
%% begin estimation
if ~isempty(zone.ref)&&isempty(zone.f)
    zone.VEst(zone.ref(1))=zone.VRef;
    converged=1;
else
    [zone, converged, i] = Api_StateEstimateNormal(zone,VExt, mpopt);
    if~isempty(zone.ref)
        zone.VEst(zone.ref(1))=zone.VRef;
    end
end

zone = Api_UpdateZone( zone,VExt );
end

