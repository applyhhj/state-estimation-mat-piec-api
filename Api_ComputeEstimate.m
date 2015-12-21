function [ z_est ] = Api_ComputeEstimate( zone,VExt )

Sfe = zone.VEst(zone.f) .* conj(zone.Yf * zone.VEst);
Ste = zone.VEst(zone.t) .* conj(zone.Yt * zone.VEst);

% should consider injection from connection branches
IExt=zone.YbusExt*VExt;
Sbuse = zone.VEst .* conj(zone.Ybus * zone.VEst+IExt);
z_est = [
    real(Sfe);
    real(Ste);
    real(Sbuse);
    angle(zone.VEst);
    imag(Sfe);
    imag(Ste);
    imag(Sbuse);
    abs(zone.VEst);
    ];

end

