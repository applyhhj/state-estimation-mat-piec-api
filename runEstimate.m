function [bus, gen, branch,brconn,converged]=runEstimate(baseMVA,bus,gen,branch,...
    brconnf,brconnt,busbrconnfout,busbrconntout,mpopt)

%% define named indices into bus, gen, branch matrices
[PQ, PV, REF, NONE, BUS_I, BUS_TYPE, PD, QD, GS, BS, BUS_AREA, VM, ...
    VA, BASE_KV, ZONE, VMAX, VMIN, LAM_P, LAM_Q, MU_VMAX, MU_VMIN] = idx_bus;
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
[GEN_BUS, PG, QG, QMAX, QMIN, VG, MBASE, GEN_STATUS, PMAX, PMIN, ...
    MU_PMAX, MU_PMIN, MU_QMAX, MU_QMIN, PC1, PC2, QC1MIN, QC1MAX, ...
    QC2MIN, QC2MAX, RAMP_AGC, RAMP_10, RAMP_30, RAMP_Q, APF] = idx_gen;

%% convert to matrix
bus=cell2mat(bus);
gen=cell2mat(gen);
branch=cell2mat(branch);
brconnf=cell2mat(brconnf);
brconnt=cell2mat(brconnt);
busbrconnfout=cell2mat(busbrconnfout);
busbrconntout=cell2mat(busbrconntout);

%% reoder bus number
busbrconnout=[busbrconnfout;busbrconntout];
if isempty(busbrconnout)
    buses=bus;
else
    buses=[bus;unique(busbrconnout,'rows')];
end
branches=[branch;brconnf;brconnt];
[ii2efull,buses,gen,branches]=ext2int(buses,gen,branches);

bn=size(bus,1);
% bncfo=size(busbrconnfout,1);
% bncto=size(busbrconntout,1);
brn=size(branch,1);
brncf=size(brconnf,1);
% brnct=size(brconnt,1);

bus=buses(1:bn,:);
ii2e=ii2efull(1:bn,:);
branch=branches(1:brn,:);
brconnf=branches(brn+1:brn+brncf,:);
brconnt=branches(brn+brncf+1:end,:);
% busbrconnfout=buses(bn+1:bn+bncfo,:);
% busbrconntout=buses(bn+bncfo+1:end,:);

%% get bus index lists of each type of bus
[ref, pv, pq] = getBusType(bus, gen);

%% generator info
on = find(gen(:, GEN_STATUS) > 0);      %% which generators are on?
gbus = gen(on, GEN_BUS);                %% what buses are they at?

%% build admittance matrices
[Yd, Yfd, Ytd] = getYMatrix(baseMVA, bus, branch);
[~, Yfconnf, Ytconnf,Yffconn,~,~,Ytfconn] = getYMatrix(baseMVA, buses, brconnf);
[~, Yfconnt, Ytconnt,~,Yttconn,Yftconn,~] = getYMatrix(baseMVA, buses, brconnt);
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

%% in area buses are numbered consecutively before out area buses
bsn=size(buses,1);
Yconnf=sparse(brconnf(:,F_BUS),brconnf(:,T_BUS)-bn,Ytfconn,bn,bsn-bn);
Yconnt=sparse(brconnt(:,T_BUS),brconnt(:,F_BUS)-bn,Yftconn,bn,bsn-bn);
YbusExt=Yconnf+Yconnt;

%% compute complex bus power injections (generation - load)
% Sbus = makeSbus(baseMVA, bus, gen);

%% import some values from load flow solution
Pflf=branch(:,PF);
Qflf=branch(:,QF);
Ptlf=branch(:,PT);
Qtlf=branch(:,QT);
Vm=bus(:,VM);
Va=bus(:,VA).*(pi/180);
V=Vm.*cos(Va)+Vm.*sin(Va).*1j;

%% prepare for estimation
idsOut=bn+1:bsn;
VmOut=buses(idsOut,VM);
VaOut=buses(idsOut,VA).*(pi/180);
VExt=VmOut.*cos(VaOut)+VmOut.*sin(VaOut).*1j;

IExt=YbusExt*VExt;
Ibus=Ybuseq*V+IExt;
Sbuslf = V .* conj(Ibus);
Vlf=V;
vv=validMeasurement(ref,bus,branch);

%% begin estimation
if ~isempty(ref)&&bn==1
    converged=1;
else
    [V, converged, i] = stateEstimate(branch, Ybuseq, Yfd, Ytd, Sbuslf, Vlf,IExt, vv, pv, pq,mpopt);
    if~isempty(ref)
        V(ref(1))=Vlf(ref(1));
    end
end

%% update connection branches
brconnf=updateBranchPf(baseMVA,brconnf,Yfconnf,Ytconnf,[V;VExt]);
brconnt=updateBranchPf(baseMVA,brconnt,Yfconnt,Ytconnt,[V;VExt]);
brconn=int2extBr(ii2efull,[brconnf;brconnt]);

%% update other states
[bus, gen, branch] = pfsoln_benchmark(baseMVA, bus, gen, branch, Ybuseq, Yfd, Ytd, V, ref, pv, pq,IExt);
[bus, gen, branch] = int2ext(ii2e, bus, gen, branch);

%% plot differences from load flow solution
% Ibus=Ybuseq*V+IExt;
% Sbus = V .* conj(Ibus);
% Pfe=branch(:,PF);
% Qfe=branch(:,QF);
% Pte=branch(:,PT);
% Qte=branch(:,QT);
% nbr = length(Pfe);
% if mpopt.verbose>1
%     figure;
%     subplot(3,2,1), plot(180/pi*(angle(Vlf)-angle(V)),'.'), title('Voltage Angle (deg)');
%     subplot(3,2,2), plot(abs(Vlf)-abs(V),'.'), title('Voltage Magnitude (p.u.)');
%     subplot(3,2,3), plot((1:nbr),(Pfe-Pflf),'r.',(1:nbr),(Pte-Ptlf),'b.'), title('Real Flow (MW)');
%     subplot(3,2,4), plot((1:nbr),(Qfe-Qflf),'r.',(1:nbr),(Qte-Qtlf),'b.'), title('Reactive Flow (MVAr)');
%     subplot(3,2,5), plot(baseMVA*real(Sbuslf-Sbus), '.'), title('Real Injection (MW)');
%     subplot(3,2,6), plot(baseMVA*imag(Sbuslf-Sbus), '.'), title('Reactive Injection (MVAr)');
% end

end