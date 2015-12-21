function [ zone ] = Api_FirstEstimation( zone,VExt )
%% compute estimated measurement
z_est=Api_ComputeEstimate(zone,VExt);

%% measurement residual
zone.delz = zone.z - z_est;
zone.normF = zone.delz' * zone.WInv * zone.delz;

end

