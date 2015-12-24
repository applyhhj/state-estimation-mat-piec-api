function [zone, converged, i] = ApiStateEstimateNormal(zone,VExt, mpopt)

% as reference bus is processed seperately so we do not need nref

%STATE_EST  Solves a state estimation problem.
%   [V, CONVERGED, I] = STATE_EST(BRANCH, YBUS, YF, YT, SBUS, ...
%                                   V0, REF, PV, PQ, MPOPT)
%   State estimator (under construction) based on code from James S. Thorp.

%   MATPOWER
%   Copyright (c) 1996-2015 by Power System Engineering Research Center (PSERC)
%   by Ray Zimmerman, PSERC Cornell
%   based on code by James S. Thorp, June 2004
%
%   $Id: state_est.m 2644 2015-03-11 19:34:22Z ray $
%
%   This file is part of MATPOWER.
%   Covered by the 3-clause BSD License (see LICENSE file for details).
%   See http://www.pserc.cornell.edu/matpower/ for more info.

%% default arguments
if nargin < 3
    mpopt = mpoption;
end

%% options
tol     = mpopt.pf.tol;
max_it  = mpopt.pf.nr.max_it;

%% initialize
converged = 0;
i = 0;

%% initial estimation
% zone=Api_FirstEstimation( zone,VExt );
[ zone.delz,zone.normF ] = Api_V1_FirstEstimation( zone.VEst,zone.f,zone.t,...
    zone.Yf,zone.Yt,zone.Ybus,zone.YbusExt,zone.z,zone.WInv ,VExt);

%% check tolerance
if mpopt.verbose > 1
    fprintf('\n it     norm( F )       step size');
    fprintf('\n----  --------------  --------------');
    fprintf('\n%3d    %10.3e      %10.3e', i, zone.normF, 0);
end
if zone.normF < tol
    converged = 1;
    if mpopt.verbose > 1
        fprintf('\nConverged!\n');
    end
end

%% bad data loop
max_it_bad_data = 50;
ibd = 1;

while (~converged && ibd <= max_it_bad_data) 
    
%     zone = Api_GetReducedMatrix( zone );    
    [ zone.HH,zone.WW,zone.WWInv,zone.ddelz ] = Api_V1_GetReducedMatrix( ...
        zone.H,zone.W,zone.WInv,zone.delz,zone.vv,zone.ww );
    %%-----  do Newton iterations  -----
    i = 0;
    while (~converged && i < max_it)
        %% update iteration counter
        i = i + 1;        
%         zone = Api_EstimateOnce( zone,VExt);
        [ zone.VVa,zone.VVm,zone.VEst,zone.delz,zone.ddelz,zone.normF,zone.step ,...
            success] = Api_V1_EstimateOnce( zone.HH,zone.WWInv,zone.ddelz,...
            zone.vv,zone.ww,zone.VVa,zone.VVm,zone.VEst,zone.nref,...
    zone.z,zone.f,zone.t,zone.Yf,zone.Yt,zone.Ybus,zone.YbusExt,VExt );
        
        %% output
        if mpopt.verbose > 1
            fprintf('\n%3d    %10.3e      %10.3e', i, zone.normF, zone.step);
        end
        if (zone.step < tol)
            converged = 1;
            if mpopt.verbose
                fprintf('\nState estimator converged in %d iterations.\n', i);
            end
        end
    end
    if mpopt.verbose
        if ~converged
            fprintf('\nState estimator did not converge in %d iterations.\n', i);
        end
    end
    
    %% bad data recognization
%     [ zone,baddata,converged,maxB ] = Api_BadDataRecognization( zone,converged,mpopt );
    [ zone.vv,baddata,converged,maxB ] = Api_V1_BadDataRecognization( ...
        zone.WW,zone.HH,zone.WWInv,zone.vv,zone.ddelz,zone.bad_threshold,converged );
    
    if (baddata == 0)
        converged = 1;
        if mpopt.verbose
            fprintf('\nNo remaining bad data, after discarding data %d time(s).\n', ibd-1);
            fprintf('Largest value of B = %.2f\n', maxB);
        end
    end
    ibd = ibd + 1;
end

