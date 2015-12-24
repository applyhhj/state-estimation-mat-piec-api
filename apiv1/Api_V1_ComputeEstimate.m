function [ z_est ] = Api_V1_ComputeEstimate( VEst,f,t,Yf,Yt,Ybus,YbusExt,VExt )

Sfe = VEst(f) .* conj(Yf * VEst);
Ste = VEst(t) .* conj(Yt * VEst);

% should consider injection from connection branches
IExt=YbusExt*VExt;
Sbuse = VEst .* conj(Ybus * VEst+IExt);
z_est = [
    real(Sfe);
    real(Ste);
    real(Sbuse);
    angle(VEst);
    imag(Sfe);
    imag(Ste);
    imag(Sbuse);
    abs(VEst);
    ];

end

