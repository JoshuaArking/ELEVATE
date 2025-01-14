fid = fopen('nedc.tsv');
nedc = textscan(fid, '%f%f','HeaderLines',1, 'Delimiter','\n', 'CollectOutput',1);
fclose(fid);

nedc = cell2mat(nedc(1));

for i=1:4

    len = length(nedc);

    out = [0 0];

    for x=2:len-1
        out(2*x-1,1) = nedc(x,1);
        out(2*x-1,2) = nedc(x,2);
        out(2*x,1) = mean([nedc(x,1) nedc(x+1,1)]);
        out(2*x,2) = mean([nedc(x,2) nedc(x+1,2)]);
    end

    nedc = out;

    clear val out
    
end

nedc = nedc(17:end,:);

dlmwrite('nedc2.tsv',nedc,'\t');