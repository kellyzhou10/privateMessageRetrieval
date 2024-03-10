clc
clear all
close all
format default

K = 5;
D = 2;
N = D;

combos = de2bi(0:2^K-1);
noQueries = 2^K;
want = [];
for i = 1:D
    want = [want;2^(i-1)];
end
notWant = [];
for i = 1:noQueries
    j = 1;
    while j <= D
        if combos(i,j) ~= 0
            break;
        end
        j = j + 1;
    end
    if (j == D + 1)
        notWant = [notWant;combos(i,:)];
    end
end
notWant = bi2de(notWant);

table = [];
temp = cat(3,[1 0;0 1],[1 1;0 1],[1 0;1 1],[1 1;1 1]);

% server1: q1 = q2 = null
% server2: [q1,q2] = {[1,0;0,1],[1,1;0,1],[1,0;1,1],[1,1;1,1]} * [a;b]
server1 = zeros(2,1);
subtable = [];
for i = 1:size(temp,3)
    server2 = temp(:,:,i) * want;
    subtable = cat(3,subtable,[server1 server2]);
end
for i = 1:size(temp,3)
    subtable = cat(3,subtable,subtable(:,:,i)');
end
table = cat(3,table,subtable);

% server1: q1 = null, q2 = k
% server2: [q1,q2] = {[1,0;0,1],[1,1;0,1],[1,0;1,1],[1,1;1,1]} * [a;b] + [k;k]
for i = (D+1):K
    subtable = [];
    server1(2) = 2^(i-1);
    for j = 1:size(temp,3)
        server2 = temp(:,:,j) * want + 2^(i-1) * ones(D,1);
        subtable = cat(3,subtable,[server1 server2]);
    end
    for j = 1:size(temp,3)
        subtable = cat(3,subtable,subtable(:,:,j)');
    end
    for j = 1:size(temp,3)-1
        row = subtable(:,:,j);
        row(2,[1 2]) = row(2,[2 1]);
        subtable = cat(3,subtable,row');
    end
    table = cat(3,table,subtable);
end

% server1: q1 = linear combination of notWants, q2 = linear combination of notWants
% server2: [q1,q2] = {[1,0;0,1],[1,1;0,1],[1,0;1,1],[1,1;1,1]} * [a;b] + server1
for i = 2:size(notWant,1)
    for j = (i+1):size(notWant,1)
        subtable = [];
        server1 = [notWant(i);notWant(j)];
        for k = 1:size(temp,3)
            server2 = temp(:,:,k) * want + server1;
            subtable = cat(3,subtable,[server1 server2]);
        end
        for k = 1:size(temp,3)
            row = subtable(:,:,k);
            row(2,[1 2]) = row(2,[2 1]);
            subtable = cat(3,subtable,row);
        end
        table = cat(3,table,subtable);
    end
end
noRows = size(table,3);


f = zeros(noRows,1);
coefs = zeros(noQueries,noRows);
for r = 1:noRows
    for q = 1:2
        for n = 1:N
            coefs(table(n,q,r)+1,r) = coefs(table(n,q,r)+1,r) + 1;
            if table(n,q,r) ~= 0
                f(r) = f(r) + 1;
            end
        end
    end
end
Aeq = [];
beq = [];
G = cell(1,K-1);
for q = 1:noQueries-2
    v = de2bi(q);
    G{sum(v)} = [G{sum(v)},q];
end
for i = 1:K-1
    q0 = G{i}(1);
    v0 = coefs(q0+1,:);
    for q = G{i}(2:end)
        v = coefs(q+1,:);
        Aeq = [Aeq; v0-v];
        beq = [beq; 0];
    end
end
Aeq = [Aeq;ones(1,noRows)];
beq = [beq;1];
LB = zeros(1,noRows);
UB = ones(1,noRows);
[x,fval] = linprog(f,[],[],Aeq,beq,LB,UB);