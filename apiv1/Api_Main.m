clc;clear;close all;
global debug reassign

%% in windows
% path(path,'.\graph');
% path(path,'.\extra');
% matpath='F:\projects\matpower5.1';
% matpath='E:\matpower5.1';

%% in linux
path(path,'./graph');
path(path,'./extra');
matpath='/home/hjh/software/matpower5.1';

% casessmall={'case30' 'case300' 'case24_ieee_rts' 'case39'};
% caseslarge={'case2383wp','case2736sp','case2746wp','case2869pegase','case9241pegase'};

exclude_files={'info','format'};
cases=getAllCases(matpath,exclude_files);

% case14Test has disconnected networks in a zone
casestst={'case2869pegase'};
mpopt = mpoption('verbose',0);
N=300;

% 0 test cases with error, 
% 1 test cases with bus number less than 300 no err,
% 2 test dedicated case no err, 
% 3 test all cases no err
debug=2;
reassign=1;

if debug==2
    cases=casestst;
end

warning('off');
for k=1:size(cases,2)
    fprintf('\nProcessing case %15s',cases{k});
    [outdiff,zoneBuses]=Api_CompareEst(cases{k},N,mpopt);
    res(k).case=cases{k};
    res(k).maxBusDiff=max(max(abs(outdiff{1})));
    res(k).maxGenDiff=max(max(abs(outdiff{2})));
    res(k).maxBranchDiff=max(max(abs(outdiff{3})));
    res(k).EstConvergence=outdiff{4};
    res(k).PFSuccess=outdiff{end};
    res(k).zoneBuses=zoneBuses;
    res(k).outdiff=outdiff;
end

printRes(res);

fprintf('Saving result!\n');
save(['result',datestr(now,30)],'res');
fprintf('Done!\n')

warning('on');