function [ z_est ] = Api_V2_ComputeEstimate(VaEst,VmEst, VaExt,VmExt,f,t,Yf,Yt,Ybus,YbusExt)
VExt=VmExt.*cos(VaExt)+VmExt.*sin(VaExt)*1j;
VEst=VmEst.*cos(VaEst)+VmEst.*sin(VaEst)*1j;
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

