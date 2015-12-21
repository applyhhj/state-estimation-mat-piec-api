function printRes(res)

fprintf('Output differences between estimation and power flow.\n');
fprintf('--------------------------------------------------------------------------------------------------------\n');
fprintf('%-20s%-15s%-15s%-15s%-15s%-15s%-15s\n','CaseName','Bus','Gen','Branch','EstConv','PFConv','Zone');
fprintf('========================================================================================================');

for k=1:size(res,2)
    fprintf('\n%-20s%-15.6f%-15.6f%-15.6f',res(k).case,res(k).maxBusDiff,res(k).maxGenDiff,res(k).maxBranchDiff);
    
    color=1;
    if ~res(k).EstConvergence,color=2;end
    fprintf(color,'%-15d',res(k).EstConvergence);
    color=1;
    if ~res(k).PFSuccess,color=2;end
    fprintf(color,'%-15d\t',res(k).PFSuccess);
    
    for l=1:size(res(k).zoneBuses,1)
        fprintf('%-d:%-d|',res(k).zoneBuses(l,:));
    end
    
end

fprintf('\n');
fprintf('=======================================================================================================\n');