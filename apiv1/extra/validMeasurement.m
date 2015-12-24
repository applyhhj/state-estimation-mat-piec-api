function [vv]=validMeasurement(ref,bus,branch)
[F_BUS, T_BUS, BR_R, BR_X, BR_B, RATE_A, RATE_B, RATE_C, ...
    TAP, SHIFT, BR_STATUS, PF, QF, PT, QT, MU_SF, MU_ST, ...
    ANGMIN, ANGMAX, MU_ANGMIN, MU_ANGMAX] = idx_brch;
%% index vector for measurements that are to be used
%%%%%% NOTE: Any variable that is related to  reference bus   %%%%%%
%%%%%%       is ignored.                                      %%%%%%

nb=size(bus,1);
nbr=size(branch,1);
busids=(1:nb)';

%% valid pf
[~,sfids]=diffRep(branch(:,F_BUS),ref);
[~,stids]=diffRep(branch(:,T_BUS),ref);
[~,sbVids]=diffRep(busids,ref);

vv=[sfids;...                   %% pf
    stids+nbr;...               %% pt
    sbVids+2*nbr;...            %% pbus
    sbVids+2*nbr+nb;...          %% va
    sfids+2*nbr+2*nb;...         %% qf
    stids+3*nbr+2*nb;...         %% qt
    sbVids+4*nbr+2*nb;...        %% qbus
    sbVids+4*nbr+3*nb;...        %% vm
    ];

end