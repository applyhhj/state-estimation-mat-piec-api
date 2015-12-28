function [ vv,converged ] = Api_V1_BadDataRecognization( WW,HH,WWInv,vv,ddelz,bad_threshold)

%%-----  Chi squared test for bad data and bad data rejection  -----
% bad_threshold = 6.25;       %% the threshold for bad data = sigma squared
% need to compute it
% bad_threshold = 7;       %% the threshold for bad data = sum sigma squared
one_at_a_time =0;
% baddata=0;

% RR = inv(zone.WWInv) - ((0.95 * zone.HH)/(zone.HH' * zone.WWInv * zone.HH)) * zone.HH';
RR = WW - ((0.95 * HH)/(HH' * WWInv * HH)) * HH';
rr = diag(RR);
B = ddelz .^ 2 ./ rr;
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
%     baddata = 1;
    converged = 0;
    
    %% update measurement index vector
    %         k = find( B < bad_threshold );
    ids=1:size(vv,1);
    ids=setdiff(ids',rejected);
    vv = vv(ids);
else
    converged = 1;
%     if mpopt.verbose
%         fprintf('\nNo remaining bad data, after discarding data %d time(s).\n', ibd-1);
%         fprintf('Largest value of B = %.2f\n', maxB);
%     end
end

end

