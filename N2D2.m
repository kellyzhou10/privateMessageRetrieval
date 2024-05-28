clc
clear all
close all
format default

K = 4;
D = 2;
N = D;

combos = de2bi(0:2^K-1);
noQueries = 2^K;
want = [];
for i = 1:D
    want = [want;2^(i-1)];
end
interference = [];
for i = 1:noQueries
    j = 1;
    while j <= D
        if combos(i,j) ~= 0
            break;
        end
        j = j + 1;
    end
    if (j == D + 1)
        interference = [interference;combos(i,:)];
    end
end
interference = bi2de(interference);

table = [];
global visited;
visited = zeros(noQueries,noQueries,noQueries,noQueries);
N1helper = [];
for i = 0:3
    for j = 0:3
        N1helper = cat(3,N1helper,[de2bi(i,2);de2bi(j,2)]);
    end
end
N2helper = cat(3,[1 0;0 1],[1 1;0 1],[1 0;1 1],[1 1;1 1]);

for N1addon = 1:size(N1helper,3)

    % server1: q1 = q2 = null
    % server2: [q1,q2] = {[1,0;0,1],[1,1;0,1],[1,0;1,1],[1,1;1,1]} * [a;b]
    server1 = zeros(2,1) + N1helper(:,:,N1addon) * want;
    subtable = [];
    for i = 1:size(N2helper,3)
        server2 = N2helper(:,:,i) * want;
        row = [server1 server2];
        subtable = addRow(row,subtable);
        row = row';
        subtable = addRow(row,subtable);
    end
    table = cat(3,table,subtable);
    
    % server1: q1 = null, q2 = k
    % server2: [q1,q2] = {[1,0;0,1],[1,1;0,1],[1,0;1,1],[1,1;1,1]} * [a;b] + [k;k]
    for i = (D+1):K
        subtable = [];
        server1 = [0;2^(i-1)] + N1helper(:,:,N1addon) * want;
        for j = 1:size(N2helper,3)
            server2 = N2helper(:,:,j) * want + 2^(i-1) * ones(D,1);
            row = [server1 server2];
            subtable = addRow(row,subtable);
            row = row';
            subtable = addRow(row,subtable);
            if (j ~= size(N2helper,3))
                row(2,[1 2]) = row(2,[2 1]);
                subtable = addRow(row,subtable);
            end
        end
        table = cat(3,table,subtable);
    end
    
    % server1: q1 = linear combination of interference, q2 = linear combination of interference
    % server2: [q1,q2] = {[1,0;0,1],[1,1;0,1],[1,0;1,1],[1,1;1,1]} * [a;b] + server1
    for i = 1:size(interference,1)
        for j = i:size(interference,1)
            if (i ~= 1 && i ~= j) || (i == 1 && ~isSingleton(interference(j))) || (~isSingleton(interference(i)) && ~isSingleton(interference(j)))
                subtable = [];
                server1 = [interference(i);interference(j)];
                for k = 1:size(N2helper,3)
                    server2 = N2helper(:,:,k) * want + server1;
                    row = [server1+N1helper(:,:,N1addon)*want server2];
                    subtable = addRow(row,subtable);
                    row(2,[1 2]) = row(2,[2 1]);
                    subtable = addRow(row,subtable);
                    if (k ~= size(N2helper,3) && i ~= j)
                        tempServer1 = server1;
                        tempServer1([1 2]) = tempServer1([2 1]);
                        server2 = N2helper(:,:,k) * want + tempServer1;
                        row = [tempServer1+N1helper(:,:,N1addon)*want server2];
                        subtable = addRow(row,subtable);
                        row(2,[1 2]) = row(2,[2 1]);
                        subtable = addRow(row,subtable);
                    end
                end
                table = cat(3,table,subtable);
            end
        end
    end
end
noRows = size(table,3);
table;

f = zeros(noRows,1);
coefs = zeros(noQueries,noQueries,noRows); % q1xq2xrow
for r = 1:noRows
    for n = 1:N
        coefs(table(1,n,r)+1,table(2,n,r)+1,r) = coefs(table(1,n,r)+1,table(2,n,r)+1,r) + 1;
        for q = 1:2
            if table(q,n,r) ~= 0
                f(r) = f(r) + 1;
            end
        end
    end
end
Aeq = [];
beq = [];
G = cell(1,K+1);
for q = 0:noQueries-1
    v = de2bi(q);
    G{sum(v)+1} = [G{sum(v)+1},q];
end
visited2 = zeros(noQueries,noQueries);
eqs = [];
for i = 1:K
    q0_1 = G{i}(1);
    for j = i:K+1
        for q0_2 = G{j}(1:end)
            if ~visited2(q0_1+1,q0_2+1)
                visited2(q0_1+1,q0_2+1) = 1;
                visited2(q0_2+1,q0_1+1) = 1;
                v0 = coefs(q0_1+1,q0_2+1,:);
                q0_1_b = de2bi(q0_1,K);
                q0_2_b = de2bi(q0_2,K);
                q0_1_size = sum(q0_1_b);
                q0_2_size = sum(q0_2_b);
                shared = sharedFiles(q0_1_b,q0_2_b);
                for q_1 = G{i}(1:end)
                    for q_2 = G{j}(1:end)
                        if visited2(q_1+1,q_2+1)
                            continue;
                        end
                        q_1_b = de2bi(q_1,K);
                        q_2_b = de2bi(q_2,K);
                        if (sum(q_1_b) == q0_1_size && sum(q_2_b) == q0_2_size && sharedFiles(q_1_b,q_2_b) == shared)
                            visited2(q_1+1,q_2+1) = 1;
                            visited2(q_2+1,q_1+1) = 1;
                            if (q_1 > q_2)
                                v = coefs(q_2+1,q_1+1,:);
                            else
                                v = coefs(q_1+1,q_2+1,:);
                            end
                            eqs = [eqs; q0_1 q0_2 q_1 q_2];
                            Aeq = [Aeq; v0(1,:)-v(1,:)];
                            beq = [beq; 0];
                        end
                    end
                end
            end
        end
    end
end
Aeq = [Aeq;ones(1,noRows)];
beq = [beq;1];
LB = zeros(1,noRows);
UB = ones(1,noRows);
[x,fval] = linprog(f,[],[],Aeq,beq,LB,UB);
I = find(x ~= 0);
newx = x(I);
results_table = [];
for i = 1:length(I)
    results_table = [results_table; reshape(table(:,:,I(i)),1,4)];
end
disp([results_table,newx]);

% alphEq = [];
% for i = 1:size(eqs,1)
%     rowEq = [];
%     for j = 1:size(eqs,2)
%         temp = de2bi(eqs(i,j),K);
%         str = "";
%         if temp(1) str = str + "a"; end
%         if temp(2) str = str + "b"; end
%         if temp(3) str = str + "c"; end
%         if temp(4) str = str + "d"; end
%         if temp(5) str = str + "e"; end
%         rowEq = [rowEq,str];
%     end
%     alphEq = [alphEq;rowEq];
% end

function x = isSingleton(encoding)
    if encoding == 1
        x = false;
    else
        x = log2(encoding) == ceil(log2(encoding));
    end
end

function shared = sharedFiles(arr1, arr2)
    shared = 0;
    for i = 1:length(arr1)
        if (arr1(i) == 1 && arr2(i) == 1)
            shared = shared + 1;
        end
    end
end

function table = addRow(row,table)
    global visited;
    row = [sort(row(:,1)) sort(row(:,2))];
    for i = 1:2
        if isSingleton(row(1,i)) && isSingleton(row(2,i)) && row(1,i) == row(2,i)
            row(1,i) = 0;
        end
    end
    if ~visited(row(1,1)+1,row(2,1)+1,row(1,2)+1,row(2,2)+1)
        table = cat(3,table,row);
        visited(row(1,1)+1,row(2,1)+1,row(1,2)+1,row(2,2)+1) = 1;
        visited(row(1,2)+1,row(2,2)+1,row(1,1)+1,row(2,1)+1) = 1;
    end
end