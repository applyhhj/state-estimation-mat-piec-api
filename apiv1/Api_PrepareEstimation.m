function [ zoneout ] = Api_PrepareEstimation( zone )

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
baseMVA=zone.baseMVA;
num=zone.no;

%% make sure empty matrics are emtpy
if isempty(bus)
   bus=[]; 
end
if isempty(gen)
   gen=[]; 
end
if isempty(branch)
   branch=[]; 
end
if isempty(brconnf)
   brconnf=[]; 
end
if isempty(brconnt)
   brconnt=[]; 
end
if isempty(busbrconnfout)
   busbrconnfout=[]; 
end
if isempty(busbrconntout)
   busbrconntout=[]; 
end

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
if ~isempty(busbrconnout)
    ii2eout=ii2efull(bn+1:end,:);
else
    ii2eout=[];
end
branch=branches(1:brn,:);
brconnf=branches(brn+1:brn+brncf,:);
brconnt=branches(brn+brncf+1:end,:);

%% build admittance matrices
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

%% compute external Ybus
% in area buses are numbered consecutively before out area buses
bsn=size(buses,1);
Yconnf=sparse(brconnf(:,F_BUS),brconnf(:,T_BUS)-bn,Yftconn,bn,bsn-bn);
Yconnt=sparse(brconnt(:,T_BUS),brconnt(:,F_BUS)-bn,Ytfconn,bn,bsn-bn);
YbusExt=Yconnf+Yconnt;

%% create inverse of covariance matrix with all measurements
Vm=bus(:,VM);
Va=bus(:,VA).*(pi/180);
Vlf=Vm.*cos(Va)+Vm.*sin(Va).*1j;
f=branch(:, F_BUS);
t=branch(:, T_BUS);
[~, ~, ~, ~, Sflf, Stlf] = dSbr_dV_Api(f,t,Yfd, Ytd, Vlf);

idsOut=bn+1:bsn;
VmOut=buses(idsOut,VM);
VaOut=buses(idsOut,VA).*(pi/180);
VExtlf=VmOut.*cos(VaOut)+VmOut.*sin(VaOut).*1j;

IExtlf=YbusExt*VExtlf;
Ibuslf=Ybuseq*Vlf+IExtlf;
Sbuslf = Vlf .* conj(Ibuslf);

nb = length(Vlf);
nbr = size(f, 1);
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
W = sparse(1:ns, 1:ns ,  sigma .^ 2, ns, ns );
WInv = sparse(1:ns, 1:ns ,  1 ./ sigma .^ 2, ns, ns );
bad_threshold=sum(sigma.^2);

%% get state indices
nref = [pv;pq];
ww = [ nref; nb+nref ];

%% record reference bus voltage
if~isempty(ref)
   refout=ii2e;
   VRef=Vlf(ref(1)); 
   VaRef=Va(ref(1));
   VmRef=Vm(ref(1));
else
    VRef=[];
end

%% true measurement for test
zTrue = [
    real(Sflf);
    real(Stlf);
    real(Sbuslf);
    angle(Vlf);
    imag(Sflf);
    imag(Stlf);
    imag(Sbuslf);
    abs(Vlf);
    ];

%% branch indics
brids=branch(:,end);

%% ----------------assign section-------------------
% zone number and base S
zoneout.num=num;
zoneout.baseMVA=baseMVA;

% assign numbering
zoneout.ii2e=ii2e;
zoneout.ii2eout=ii2eout;
zoneout.ii2efull=ii2efull;
zoneout.brids=brids;
zoneout.nb=bn;
zoneout.nbr=brn;

% assign branches and buses for updating
zoneout.bus=bus;
zoneout.branch=branch;
zoneout.gen=gen;
zoneout.brconnf=brconnf;
zoneout.brconnt=brconnt;
zoneout.Yfconnf=Yfconnf;
zoneout.Ytconnf=Ytconnf;
zoneout.Yfconnt=Yfconnt;
zoneout.Ytconnt=Ytconnt;

% assign variables for estimation
zoneout.f=f;
zoneout.t=t;
zoneout.Ybus=Ybuseq;
zoneout.Yf=Yfd;
zoneout.Yt=Ytd;
zoneout.YbusExt=YbusExt;
zoneout.ref=ref;
zoneout.pv=pv;
zoneout.pq=pq;

% assign external bus voltages with power flow values
zoneout.VExtlf=VExtlf;
zoneout.Vlf=Vlf;

zoneout.bad_threshold=bad_threshold;
zoneout.W=W;
zoneout.WInv=WInv;
zoneout.sigma=sigma;

zoneout.nref=nref;
zoneout.ww = ww;
zoneout.VRef=VRef; 
zoneout.zTrue=zTrue;

if~isempty(ref)
    zoneout.refout=refout;
    zoneout.VaRef=VaRef;
    zoneout.VmRef=VmRef;
end

% cmopute H
zoneout.H=Api_GetH( zoneout );
end

