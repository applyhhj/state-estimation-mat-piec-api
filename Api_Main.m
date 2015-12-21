clc;clear;close all;
global debug reassign
path(path,'.\graph');

% casessmall={'case30' 'case300' 'case24_ieee_rts' 'case39'};
% caseslarge={'case2383wp','case2736sp','case2746wp','case2869pegase'};

matpath='F:\projects\matpower5.1';
%matpath='E:\matpower5.1';
exclude_files={'info','format'};
cases=getAllCases(matpath,exclude_files);

% case14Test has disconnected networks in a zone
casestst={'case1354pegase'};
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
    fprintf('Processing case %15s\n',cases{k});
    [outdiff,zoneBuses]=test_Api_CompareEst(cases{k},N,mpopt);
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