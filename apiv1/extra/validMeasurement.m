function [vv]=validMeasurement(ref,nb,nbr,f,t)
%% index vector for measurements that are to be used
%%%%%% NOTE: Any variable that is related to  reference bus   %%%%%%
%%%%%%       is ignored.                                      %%%%%%

busids=(1:nb)';
%% valid pf
[~,sfids]=diffRep(f,ref);
[~,stids]=diffRep(t,ref);
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