function [ zone,baddata,converged,maxB ] = Api_BadDataRecognization( zone,converged,mpopt )
%% default arguments
if nargin < 3
    mpopt = mpoption;
end

%%-----  Chi squared test for bad data and bad data rejection  -----
% bad_threshold = 6.25;       %% the threshold for bad data = sigma squared
bad_threshold = 7;       %% the threshold for bad data = sum sigma squared
one_at_a_time =0;
baddata=0;

% RR = inv(zone.WWInv) - ((0.95 * zone.HH)/(zone.HH' * zone.WWInv * zone.HH)) * zone.HH';
RR = zone.WW - ((0.95 * zone.HH)/(zone.HH' * zone.WWInv * zone.HH)) * zone.HH';
rr = diag(RR);
B = zone.ddelz .^ 2 ./ rr;
[maxB,i_maxB] = max(B);

if one_at_a_time
    if maxB >= bad_threshold
        rejected = i_maxB;
    else
        rejected = [];
    end
else
    rejected = find( B >= bad_threshold );
end

if ~isempty(rejected)
    baddata = 1;
    converged = 0;
    if mpopt.verbose
        fprintf('\n\tZone %d rejecting %d measurement(s) as bad data.',zone.no, length(rejected));
    end
    %         if mpopt.verbose
    %             fprintf('\nRejecting %d measurement(s) as bad data:\n', length(rejected));
    %             fprintf('\tindex\t      B\n');
    %             fprintf('\t-----\t-------------\n');
    %             fprintf('\t%4d\t%10.2f\n', [ vv(rejected), B(rejected) ]' );
    %         end
    
    %% update measurement index vector
    %         k = find( B < bad_threshold );
    ids=1:size(zone.vv,1);
    ids=setdiff(ids',rejected);
    zone.vv = zone.vv(ids);
end

end

