function [ VVa,VVm,VEst,delz,ddelz,normF,step ,success] = Api_V1_EstimateOnce( HH,WWInv,ddelz,vv,ww,VVa,VVm,VEst,nref,...
    z,f,t,Yf,Yt,Ybus,YbusExt,VExt )
success=1;
%% compute update step
F = HH' * WWInv * ddelz;
J = HH' * WWInv * HH;
dx = (J \ F);

if ~isempty(find(isnan(dx),1))
    success=0;
    fprintf('has nan');
end

%% update voltage
nstat=size(ww,1)/2;
VVa = VVa + dx(1:nstat);
VVm = VVm + dx(nstat+1:end);
VEst(nref) = VVm .* exp(1j * VVa);

%% udpate H matrix
% we treat H as a constant matrix
% if nargin>2
%     [H,HH] = ApiGetH( zone,VExt );
% end

%% compute estimated measurement
z_est=Api_V1_ComputeEstimate(VEst,f,t,Yf,Yt,Ybus,YbusExt,VExt);

%% measurement residual
delz = z - z_est;
ddelz = delz(vv);
normF = ddelz' * WWInv * ddelz;

%% check for convergence
step = dx' * dx;

end

