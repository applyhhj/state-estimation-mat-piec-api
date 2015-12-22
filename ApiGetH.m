function [ H,HH ] = ApiGetH( zone,VExt )
%% -----  evaluate Hessian  -----
IExt=zone.YbusExt*VExt;
[dSbus_dVm, dSbus_dVa] = dSbus_dV_Piec(zone.Ybus, zone.VEst, IExt);
[dSf_dVa, dSf_dVm, dSt_dVa, dSt_dVm] = Api_dSbr_dV(zone.f,zone.t, zone.Yf, zone.Yt, zone.VEst);
nb=zone.bn;
H = [
    real(dSf_dVa)   real(dSf_dVm);
    real(dSt_dVa)   real(dSt_dVm);
    real(dSbus_dVa) real(dSbus_dVm);
    speye(nb)       sparse(nb,nb);
    imag(dSf_dVa)   imag(dSf_dVm);
    imag(dSt_dVa)   imag(dSt_dVm);
    imag(dSbus_dVa) imag(dSbus_dVm);
    sparse(nb,nb)   speye(nb);
    ];

if nargout>1
    HH=H(zone.vv,zone.ww);
end

end

