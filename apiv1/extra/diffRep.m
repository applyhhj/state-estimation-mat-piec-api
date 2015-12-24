function [c,ia]=diffRep(a,b)
% vector difference
if isempty(b)
    ia=(1:max(size(a,1)))';
    if size(a,1)<size(a,2)
        c=a';
    else
        c=a;
    end
    return;
end

if isempty(a)
    ia=[];
    c=[];
    return;
end

ia=ones(max(size(a)),1);
if size(a,1)<size(a,2)
    atmp=a';
else
    atmp=a;
end

for k=1:max(size(b))
    ia=ia&(atmp~=b(k));
end
ia=find(ia);
c=atmp(ia);
end