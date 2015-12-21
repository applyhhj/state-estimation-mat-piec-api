function [ zone,baddata,converged ] = Api_BadDataRecognization( zone,converged )
%%-----  Chi squared test for bad data and bad data rejection  -----
bad_threshold = 6.25;       %% the threshold for bad data = sigma squared
one_at_a_time = 1;
baddata=0;

RR = inv(zone.WWInv) - 0.95 * zone.HH * inv(zone.HH' * zone.WWInv * zone.HH) * zone.HH';
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
    %         if mpopt.verbose
    %             fprintf('\nRejecting %d measurement(s) as bad data:\n', length(rejected));
    %             fprintf('\tindex\t      B\n');
    %             fprintf('\t-----\t-------------\n');
    %             fprintf('\t%4d\t%10.2f\n', [ vv(rejected), B(rejected) ]' );
    %         end
    
    %% update measurement index vector
    %         k = find( B < bad_threshold );
    zone.vv = zone.vv(B < bad_threshold);
end

end
