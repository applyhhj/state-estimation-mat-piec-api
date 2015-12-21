function [z_est]=computeEstimatePiec(f,t,Yf,Yt,Ybus,V,IExt)

Sfe = V(f) .* conj(Yf * V);
Ste = V(t) .* conj(Yt * V);

% should consider injection from connection branches
Sbuse = V .* conj(Ybus * V+IExt);
z_est = [
    real(Sfe);
    real(Ste);
    real(Sbuse);
    angle(V);
    imag(Sfe);
    imag(Ste);
    imag(Sbuse);
    abs(V);
    ];

end