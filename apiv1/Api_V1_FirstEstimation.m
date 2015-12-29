function [ delz,normF,vv ] = Api_V1_FirstEstimation( VEst,VExt,z,ref,nb,nbr,f,t,Yf,Yt,Ybus,YbusExt,WInv)
%% compute estimated measurement
z_est=Api_V1_ComputeEstimate(VEst,f,t,Yf,Yt,Ybus,YbusExt,VExt);

%% measurement residual
delz = z - z_est;
normF = delz' * WInv * delz;

%% initialize vv
vv=validMeasurement(ref,nb,nbr,f,t);
end

