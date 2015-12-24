function [ delz,normF ] = Api_V1_FirstEstimation( VEst,f,t,Yf,Yt,Ybus,YbusExt,z,WInv,VExt)
%% compute estimated measurement
z_est=Api_V1_ComputeEstimate(VEst,f,t,Yf,Yt,Ybus,YbusExt,VExt);

%% measurement residual
delz = z - z_est;
normF = delz' * WInv * delz;

end

