function [zone, converged, i] = Api_StateEstimateNormal(zone,VExt, mpopt)

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

%% reset state
% initialize estimated voltage
% zone.VEst=Vlf;
zone.VEst=ones(zone.bn,1);
% initialize VVa VVm
zone.VVa = angle(zone.VEst(zone.nref));
zone.VVm = abs(zone.VEst(zone.nref));
% get valid measurement
zone.vv=validMeasurement(zone.ref,zone.bus,zone.branch);

%% first estimation, compute delz
zone=Api_FirstEstimation( zone,VExt );

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
    
    zone = Api_GetReducedMatrix( zone );    
    %% -----  do Newton iterations  -----
    i = 0;
    while (~converged && i < max_it)
        % update iteration counter
        i = i + 1;        
        zone = Api_EstimateOnce( zone,VExt);
        
        % output
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
    [ zone,baddata,converged,maxB ] = Api_BadDataRecognization( zone,converged,mpopt );
    
    if (baddata == 0)
        converged = 1;
        if mpopt.verbose
            fprintf('\nNo remaining bad data, after discarding data %d time(s).\n', ibd-1);
            fprintf('Largest value of B = %.2f\n', maxB);
        end
    end
    ibd = ibd + 1;
end

