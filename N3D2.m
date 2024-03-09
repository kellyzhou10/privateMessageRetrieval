clc
clear all
close all
format default

K = 6;
D = 2;
N = D + 1;

combos = de2bi(0:2^K-1);
noQueries = 2^K;
want = bi2de([combos(2,:);combos(3,:)]);
subtable = [];
for i = 1:noQueries
    j = 1;
    while j <= D
        if combos(i,j) ~= 0
            break;
        end
        j = j + 1;
    end
    if (j == D + 1)
        subtable = [subtable;combos(i,:)];
    end
end
subtable = [bi2de(subtable),zeros(size(subtable,1),D)];
table = [];
temp = cat(3,[1,0;0,1],[1,0;1,1],[1,1;0,1],[1,1;1,1]);
for i = 1:size(temp,3)
    subtable(1,:) = [subtable(1,1),(temp(:,:,i)*want)'];
    for j = 2:size(subtable,1)
        for k = 2:size(subtable,2)
            subtable(j,k) = subtable(j,1) + subtable(1,k);
        end
    end
    table = [table;subtable];
end
noRows = size(table,1);
f = zeros(noRows,1);
coefs = zeros(noQueries,noRows);
for r = 1:noRows
    for c = 1:N
        coefs(table(r,c)+1,r) = coefs(table(r,c)+1,r) + 1;
        if table(r,c) ~= 0
            f(r) = f(r) + 1;
        end
    end
end
G = cell(1,K-1);
for q = 1:noQueries-2
    v = de2bi(q);
    G{sum(v)} = [G{sum(v)},q];
end
Aeq = [];
beq = [];
for i = 1:K-1
    q0 = G{i}(1);
    v0 = coefs(q0+1,:);
    for q = G{i}(2:end)
        v = coefs(q+1,:);
        Aeq = [Aeq; v0-v];
        beq = [beq; 0];
    end
end
Aeq = [Aeq; ones(1,noRows)];
beq = [beq; 1];
LB = zeros(1,noRows);
UB = ones(1,noRows);
[x,fval] = linprog(f,[],[],Aeq,beq,LB,UB);
[x,table]