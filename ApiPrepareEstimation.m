function [ zone ] = ApiPrepareEstimation( zone )

[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;


%% convert to matrix
bus=zone.bus;
gen=zone.gen;
branch=zone.branch;
brconnf=zone.brconnf;
brconnt=zone.brconnt;
busbrconnfout=zone.brconnf_out_bus;
busbrconntout=zone.brconnt_out_bus;

%% reoder bus number
busbrconnout=[busbrconnfout;busbrconntout];
if isempty(busbrconnout)
    buses=bus;
else
    buses=[bus;unique(busbrconnout,'rows')];
end
branches=[branch;brconnf;brconnt];
[ii2efull,buses,gen,branches]=ext2int(buses,gen,branches);

%% get bus type
[ref, pv, pq] = getBusType(bus, gen);

%% reassign renumbered buses and branches
bn=size(bus,1);
brn=size(branch,1);
brncf=size(brconnf,1);

bus=buses(1:bn,:);
ii2e=ii2efull(1:bn,:);
branch=branches(1:brn,:);
brconnf=branches(brn+1:brn+brncf,:);
brconnt=branches(brn+brncf+1:end,:);

%% assign numbering
zone.ii2e=ii2e;
zone.ii2efull=ii2efull;
zone.bn=bn;

%% build admittance matrices
baseMVA=zone.baseMVA;
[Yd, Yfd, Ytd] = getYMatrix(baseMVA, bus, branch);
[~, Yfconnf, Ytconnf,Yffconn,~,Yftconn,~] = getYMatrix(baseMVA, buses, brconnf);
[~, Yfconnt, Ytconnt,~,Yttconn,~,Ytfconn] = getYMatrix(baseMVA, buses, brconnt);
nbrcf=size(brconnf,1);
Cbrcfbus=sparse(1:nbrcf,brconnf(:,F_BUS),1,nbrcf,bn);
nbrct=size(brconnt,1);
Cbrctbus=sparse(1:nbrct,brconnt(:,T_BUS),1,nbrct,bn);
Yeqf=Cbrcfbus'*Yffconn;
Yeqt=Cbrctbus'*Yttconn;
Yeq=sparse(diag(2*(Yeqf+Yeqt)));
Yb=Yd+Yeq;

YL=[Yffconn;Yttconn];
nYl=size(YL,1);
connbus=[brconnf(:,F_BUS);brconnt(:,T_BUS)];
N=sparse(connbus,1:nYl,1,bn,nYl);

YLdiag=sparse(diag(YL));
Ybuseq=Yb-N*YLdiag*N';

%% assign branches and buses for updating
zone.bus=bus;
zone.branch=branch;
zone.gen=gen;
zone.brconnf=brconnf;
zone.brconnt=brconnt;
zone.Yfconnf=Yfconnf;
zone.Ytconnf=Ytconnf;
zone.Yfconnt=Yfconnt;
zone.Ytconnt=Ytconnt;

%% compute external Ybus
% in area buses are numbered consecutively before out area buses
bsn=size(buses,1);
Yconnf=sparse(brconnf(:,F_BUS),brconnf(:,T_BUS)-bn,Yftconn,bn,bsn-bn);
Yconnt=sparse(brconnt(:,T_BUS),brconnt(:,F_BUS)-bn,Ytfconn,bn,bsn-bn);
YbusExt=Yconnf+Yconnt;

%% assign variables for estimation
zone.f=branch(:, F_BUS);
zone.t=branch(:, T_BUS);
zone.Ybus=Ybuseq;
zone.Yf=Yfd;
zone.Yt=Ytd;
zone.YbusExt=YbusExt;
zone.ref=ref;
zone.pv=pv;
zone.pq=pq;

%% create inverse of covariance matrix with all measurements
Vm=bus(:,VM);
Va=bus(:,VA).*(pi/180);
Vlf=Vm.*cos(Va)+Vm.*sin(Va).*1j;
[~, ~, ~, ~, Sflf, Stlf] = Api_dSbr_dV(zone.f,zone.t,zone.Yf, zone.Yt, Vlf);

idsOut=bn+1:bsn;
VmOut=buses(idsOut,VM);
VaOut=buses(idsOut,VA).*(pi/180);
VExtlf=VmOut.*cos(VaOut)+VmOut.*sin(VaOut).*1j;

%% for test assign external bus voltages with power flow values
zone.VExtlf=VExtlf;
zone.Vlf=Vlf;

IExtlf=YbusExt*VExtlf;
Ibuslf=Ybuseq*Vlf+IExtlf;
Sbuslf = Vlf .* conj(Ibuslf);

nb = length(Vlf);
nbr = size(zone.f, 1);
fullscale = 30;
sigma = [
    0.02 * abs(Sflf)      + 0.0052 * fullscale * ones(nbr,1);
    0.02 * abs(Stlf)      + 0.0052 * fullscale * ones(nbr,1);
    0.02 * abs(Sbuslf)    + 0.0052 * fullscale * ones(nb,1);
    0.2 * pi/180 * 3*ones(nb,1);
    0.02 * abs(Sflf)      + 0.0052 * fullscale * ones(nbr,1);
    0.02 * abs(Stlf)      + 0.0052 * fullscale * ones(nbr,1);
    0.02 * abs(Sbuslf)    + 0.0052 * fullscale * ones(nb,1);
    0.02 * abs(Vlf)      + 0.0052 * 1.1 * ones(nb,1);
    ] ./ 3;
ns = length(sigma);
WInv = sparse(1:ns, 1:ns ,  1 ./ sigma .^ 2, ns, ns );

zone.WInv=WInv;

%% get valid measurement
zone.vv=validMeasurement(ref,bus,branch);
nref = [pv;pq];
zone.ww = [ nref; nb+nref ];
zone.nref=nref;

%% record reference bus voltage
if~isempty(ref)
   zone.VRef=Vlf(ref(1)); 
end

%% initialize estimated voltage
zone.VEst=ones(bn,1);

%% true measurement for test
zone.zTrue = [
    real(Sflf);
    real(Stlf);
    real(Sbuslf);
    angle(Vlf);
    imag(Sflf);
    imag(Stlf);
    imag(Sbuslf);
    abs(Vlf);
    ];
end

