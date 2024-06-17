clc
clear all
close all
format default

prompt = "Enter K:" + newline;
K = input(prompt);
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

N2helper = cat(3,[1 0;0 1],[1 1;0 1],[1 0;1 1],[1 1;1 1]);
% server1: q1 = q2 = null
% server2: [q1,q2] = {[1,0;0,1],[1,1;0,1],[1,0;1,1],[1,1;1,1]} * [a;b]
subtable = [];
server1 = [0;0];
for i = 1:size(N2helper,3)
    server2 = N2helper(:,:,i) * want;
    row = [server1 server2];
    subtable = addRow(row,subtable,K);
    subtable = addRow(row',subtable,K);
end
table = cat(3,table,subtable);

N1helper = de2bi(0:D^D-1);
N2helper = cat(3,[1 0 0;0 1 1],[1 0 1;0 1 0],[1 1 1;1 1 1],[0 0 1;1 1 0],[0 0 0;1 1 1],[1 0 1;1 0 1],[0 1 1;0 1 1]);
% server1: q1 = null, q2 = n1helper * [a;b] + k
% server2: [q1,q2] = N2helper * [a;b;*]
for i = 2:size(interference,1)
    box = interference(i);
    subtable = [];
    for j = 1:size(N2helper,3)
        server2 = N2helper(:,:,j) * [want;box];
        for k = 1:length(N1helper)
            if j < 3 || j == 3 && isSingleton(box) || j == 4 && k > 1 && k < 4
                server1 = [0;N1helper(k,:)*want+box];
                row = [server1 server2];
                subtable = addRow(row,subtable,K);
                if k == 1 && (j == 1 || j == 2) || isSingleton(box) && (j == 1 && k == 3 || j == 2 && k == 2)
                    subtable = addRow(row',subtable,K);
                    row(2,[1 2]) = row(2,[2 1]);
                    subtable = addRow(row,subtable,K);
                end
            end
        end
        for k = 2:length(N1helper)
            if j == 3 && isSingleton(box)
                server1 = [0;N1helper(k,:)*want];
                subtable = addRow([server1 server2],subtable,K);
            elseif j == 5
                server1 = [box;N1helper(k,:)*want];
                subtable = addRow([server1 server2],subtable,K);
            end
        end
        if j > 5 && isSingleton(box)
            server1 = [0;want(8-j)+box]; % want(8-j) is b when j is 6 and a when j is 7
            subtable = addRow([server1 server2],subtable,K);
            server1 = [0;want(1)+want(2)];
            subtable = addRow([server1 server2],subtable,K);
            server1 = [0;want(1)+want(2)+box];
            subtable = addRow([server1 server2],subtable,K);
        end
    end
    table = cat(3,table,subtable);
end

N2helper = cat(3,[1 0 0;0 1 1],[1 0 1;0 1 0],[1 1 1;1 1 1],[1 0 1;1 0 1],[0 1 1;0 1 1]);
% two interference: same and not singleton
% server2: [q1,q2] = N2helper * [a;b;*]
for i = 2:size(interference,1)
    star = interference(i);
    if ~isSingleton(star)
        subtable = [];
        for j = 1:size(N2helper,3)
            server2 = N2helper(:,:,j) * [want;star];
            if j < 4
                for k = 1:length(N1helper)
                    server1 = [N1helper(k,:)*want+star;N1helper(k,:)*want+star];
                    subtable = addRow([server1 server2],subtable,K);
                end
                if j == 3
                    for k = 2:length(N1helper)
                        server1 = [star;N1helper(k,:)*want];
                        subtable = addRow([server1 server2],subtable,K);
                    end
                end            
            else
                server1 = [star;want(6-j)]; % want(6-j) is b when j is 6 and a when j is 7
                subtable = addRow([server1 server2],subtable,K);
                server1 = [star;want(1)+want(2)];
                subtable = addRow([server1 server2],subtable,K);
            end
        end
        table = cat(3,table,subtable);
    end
end

% two interference: different and singletons
N2helper = cat(3,[1 0 0 0;0 1 1 0],[1 0 0 0;0 1 0 1],[1 0 1 0;0 1 0 0],[1 0 0 1;0 1 0 0],[1 0 0 0;0 1 1 1], ...
    [1 0 1 1;0 1 0 0],[1 0 1 0;0 1 0 1],[1 0 0 1;0 1 1 0],[1 1 1 0;1 1 1 0],[1 1 0 1;1 1 0 1], ...
    [1 1 1 1;1 1 1 1],[0 0 1 1;1 0 0 0],[0 0 1 1;0 1 0 0],[0 0 1 1;1 1 0 0],[0 0 1 0;1 1 0 1], ...
    [0 0 0 1;1 1 1 0],[1 0 1 1;1 0 1 1],[0 1 1 1;0 1 1 1]);
% server2: [q1,q2] = N2helper * [a;b;*;^]
for i = 2:size(interference,1)
    for j = i+1:size(interference,1)
        star = interference(i);
        delta = interference(j);
        if isSingleton(star) && isSingleton(delta)
            subtable = [];
            for k = 1:size(N2helper,3)
                server2 = N2helper(:,:,k) * [want;star;delta];
                if k < 5
                    for m = 1:length(N1helper)
                        server1 = [N1helper(m,:)*want+star+delta;N1helper(m,:)*want+star+delta];
                        subtable = addRow([server1 server2],subtable,K);
                    end
                elseif k < 7
                    for m = 1:2
                        for n = 1:length(N1helper)
                            if m == 1
                                server1 = [star;N1helper(n,:)*want+delta];
                                subtable = addRow([server1 server2],subtable,K);
                                server1 = [delta;N1helper(n,:)*want+star];
                                subtable = addRow([server1 server2],subtable,K);
                            else
                                server1 = [N1helper(n,:)*want+star+delta;N1helper(n,:)*want+star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            end
                        end
                    end
                elseif k < 9
                    server1 = server2 - [want(1);want(2)];
                    row = [server1 server2];
                    subtable = addRow(row,subtable,K);
                    row(2,[1 2]) = row(2,[2 1]);
                    subtable = addRow(row,subtable,K);
                    for m = 1:3
                        for n = 1:length(N1helper)
                            if m == 1 && n > 1
                                server1 = [star;N1helper(n,:)*want+delta];
                                subtable = addRow([server1 server2],subtable,K);
                                server1 = [delta;N1helper(n,:)*want+star];
                                subtable = addRow([server1 server2],subtable,K);
                            elseif m == 2 && n > 1
                                server1 = [N1helper(n,:)*want;star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            elseif m == 3
                                server1 = [N1helper(n,:)*want+star+delta;N1helper(n,:)*want+star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            end
                        end
                    end
                    server1 = [want(1);want(2)+star+delta];
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [want(2);want(1)+star+delta];
                    subtable = addRow([server1 server2],subtable,K);
                    subtable = addRow([server2 server2],subtable,K);
                    subtable = addRow([server2 server2]',subtable,K);
                    server1 = [want(1)+delta;want(2)+star];
                    subtable = addRow([server1 server2],subtable,K);
                elseif k < 11
                    for m = 1:2
                        for n = 1:length(N1helper)
                            if m == 1 && n > 1
                                if k == 9
                                    server1 = [N1helper(n,:)*want+delta;N1helper(n,:)*want+delta];
                                    subtable = addRow([server1 server2],subtable,K);
                                else
                                    server1 = [N1helper(n,:)*want+star;N1helper(n,:)*want+star];
                                    subtable = addRow([server1 server2],subtable,K);
                                end
                            elseif m == 2
                                server1 = [N1helper(n,:)*want+star+delta;N1helper(n,:)*want+star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            end
                        end
                    end
                elseif k < 12
                    for m = 1:5
                        for n = 1:length(N1helper)
                            if m == 1 && n > 1
                                server1 = [star;N1helper(n,:)*want];
                                subtable = addRow([server1 server2],subtable,K);
                                server1 = [delta;N1helper(n,:)*want];
                                subtable = addRow([server1 server2],subtable,K);
                            elseif m == 2
                                server1 = [star;N1helper(n,:)*want+delta];
                                subtable = addRow([server1 server2],subtable,K);
                                server1 = [delta;N1helper(n,:)*want+star];
                                subtable = addRow([server1 server2],subtable,K);
                            elseif m == 3 && n > 1 && n < 4
                                server1 = [N1helper(n,:)*want+star;N1helper(n,:)*want+star];
                                subtable = addRow([server1 server2],subtable,K);
                                server1 = [N1helper(n,:)*want+delta;N1helper(n,:)*want+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            elseif m == 4 && n > 1
                                server1 = [N1helper(n,:)*want;star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            elseif m == 5
                                server1 = [N1helper(n,:)*want+star+delta;N1helper(n,:)*want+star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            end
                        end
                    end
                elseif k < 14
                    server1 = [star;want(14-k)+delta]; % want(14-k) is b when k is 12 and a when k is 13
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [delta;want(14-k)+star];
                    subtable = addRow([server1 server2],subtable,K);
                elseif k < 15
                    for m = 2:length(N1helper)-1
                        server1 = [star;N1helper(m,:)*want+delta];
                        subtable = addRow([server1 server2],subtable,K);
                        server1 = [delta;N1helper(m,:)*want+star];
                        subtable = addRow([server1 server2],subtable,K);
                    end
                elseif k < 17
                    for m = 2:length(N1helper)
                        server1 = [star+delta;N1helper(m,:)*want];
                        subtable = addRow([server1 server2],subtable,K);
                    end
                else
                    server1 = [star;want(19-k)]; % want(19-k) is b when k is 17 and a when k is 18
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [delta;want(19-k)];
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [star;want(1)+want(2)];
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [delta;want(1)+want(2)];
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [star;want(19-k)+delta];
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [delta;want(19-k)+star];
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [star;want(1)+want(2)+delta];
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [delta;want(1)+want(2)+star];
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [want(19-k)+star;want(19-k)+star];
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [want(19-k)+delta;want(19-k)+delta];
                    subtable = addRow([server1 server2],subtable,K);
                end
            end
            row = [star delta;want(1)+want(2)+delta want(1)+want(2)+star];
            subtable = addRow(row,subtable,K);
            row = [want(1)+star+delta want(2)+star+delta;want(1)+star+delta want(2)+star+delta];
            subtable = addRow(row,subtable,K);
            table = cat(3,table,subtable);
        end
    end
end

% two interference: star is a singleton and delta is not a singleton
N2helper = cat(3,[1 0 0 0;0 1 0 1],[1 0 0 1;0 1 0 0],[1 0 0 0;0 1 1 1],[1 0 1 1;0 1 0 0],[1 0 1 0;0 1 0 1], ...
    [1 0 0 1;0 1 1 0],[1 1 1 1;1 1 1 1],[0 0 1 1;1 0 0 0],[0 0 1 1;0 1 0 0],[0 0 1 1;1 1 0 0], ...
    [0 0 1 0;1 1 0 1],[0 0 0 1;1 1 1 0]);
% server2: [q1,q2] = N2helper * [a;b;*;^]
for i = 2:size(interference,1)
    for j = 2:size(interference,1)
        star = interference(i);
        delta = interference(j);
        if isSingleton(star) && ~isSingleton(delta) && ~shareFiles(star,delta,K)
            subtable = [];
            for k = 1:size(N2helper,3)
                server2 = N2helper(:,:,k) * [want;star;delta];
                if k < 3
                    for m = 1:length(N1helper)
                        server1 = [N1helper(m,:)*want+star+delta;N1helper(m,:)*want+star+delta];
                        subtable = addRow([server1 server2],subtable,K);
                    end
                elseif k < 5
                    for m = 1:2
                        for n = 1:length(N1helper)
                            if m == 1
                                server1 = [star;N1helper(n,:)*want+delta];
                                subtable = addRow([server1 server2],subtable,K);
                                server1 = [delta;N1helper(n,:)*want+star];
                                subtable = addRow([server1 server2],subtable,K);
                            else
                                server1 = [N1helper(n,:)*want+star+delta;N1helper(n,:)*want+star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            end
                        end
                    end
                elseif k < 7
                    server1 = server2 - [want(1);want(2)];
                    row = [server1 server2];
                    subtable = addRow(row,subtable,K);
                    row(2,[1 2]) = row(2,[2 1]);
                    subtable = addRow(row,subtable,K);
                    for m = 1:2
                        for n = 2:length(N1helper)
                            if m == 1
                                server1 = [star;N1helper(n,:)*want+delta];
                                subtable = addRow([server1 server2],subtable,K);
                                server1 = [delta;N1helper(n,:)*want+star];
                                subtable = addRow([server1 server2],subtable,K);
                            else
                                server1 = [N1helper(n,:)*want;star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            end
                        end
                    end
                    server1 = [want(1);want(2)+star+delta];
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [want(2);want(1)+star+delta];
                    subtable = addRow([server1 server2],subtable,K);
                    subtable = addRow([server2 server2],subtable,K);
                    server1 = [want(1)+delta;want(2)+star];
                    subtable = addRow([server1 server2],subtable,K);
                elseif k < 8
                    for m = 1:3
                        for n = 1:length(N1helper)
                            if m == 1 && n > 1
                                server1 = [delta;N1helper(n,:)*want];
                                subtable = addRow([server1 server2],subtable,K);
                            elseif m == 2 && n > 1
                                server1 = [N1helper(n,:)*want;star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            elseif m == 3
                                server1 = [N1helper(n,:)*want+star+delta;N1helper(n,:)*want+star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            end
                        end
                    end
                elseif k < 10
                    server1 = [star;want(10-k)+delta]; % want(10-k) is b when k is 8 and a when k is 9
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [delta;want(10-k)+star];
                    subtable = addRow([server1 server2],subtable,K);
                elseif k < 11
                    for m = 2:length(N1helper)-1
                        server1 = [star;N1helper(m,:)*want+delta];
                        subtable = addRow([server1 server2],subtable,K);
                        server1 = [delta;N1helper(m,:)*want+star];
                        subtable = addRow([server1 server2],subtable,K);
                    end
                else
                    for m = 2:length(N1helper)
                        server1 = [star+delta;N1helper(m,:)*want];
                        subtable = addRow([server1 server2],subtable,K);
                    end
                end
            end
            row = [star delta;want(1)+want(2)+delta want(1)+want(2)+star];
            subtable = addRow(row,subtable,K);
            row = [want(1)+star+delta want(2)+star+delta;want(1)+star+delta want(2)+star+delta];
            subtable = addRow(row,subtable,K);
            table = cat(3,table,subtable);
        end
    end
end

% two interference: different and not singletons
N2helper = cat(3,[1 0 0 0;0 1 1 1],[1 0 1 1;0 1 0 0],[1 0 1 0;0 1 0 1],[1 0 0 1;0 1 1 0],[1 1 1 1;1 1 1 1], ...
    [0 0 1 1;1 0 0 0],[0 0 1 1;0 1 0 0],[0 0 1 1;1 1 0 0],[0 0 1 0;1 1 0 1],[0 0 0 1;1 1 1 0]);
% server2: [q1,q2] = N2helper * [a;b;*;^]
for i = 2:size(interference,1)
    for j = i+1:size(interference,1)
        star = interference(i);
        delta = interference(j);
        if ~isSingleton(star) && ~isSingleton(delta) && ~shareFiles(star,delta,K)
            subtable = [];
            for k = 1:size(N2helper,3)
                server2 = N2helper(:,:,k) * [want;star;delta];
                if k < 3
                    for m = 1:2
                        for n = 1:length(N1helper)
                            if m == 1
                                server1 = [star;N1helper(n,:)*want+delta];
                                subtable = addRow([server1 server2],subtable,K);
                                server1 = [delta;N1helper(n,:)*want+star];
                                subtable = addRow([server1 server2],subtable,K);
                            else
                                server1 = [N1helper(n,:)*want+star+delta;N1helper(n,:)*want+star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            end
                        end
                    end
                elseif k < 5
                    server1 = server2 - [want(1);want(2)];
                    row = [server1 server2];
                    subtable = addRow(row,subtable,K);
                    row(2,[1 2]) = row(2,[2 1]);
                    subtable = addRow(row,subtable,K);
                    for m = 1:2
                        for n = 2:length(N1helper)
                            if m == 1
                                server1 = [star;N1helper(n,:)*want+delta];
                                subtable = addRow([server1 server2],subtable,K);
                                server1 = [delta;N1helper(n,:)*want+star];
                                subtable = addRow([server1 server2],subtable,K);
                            else
                                server1 = [N1helper(n,:)*want;star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            end
                        end
                    end
                    server1 = [want(1);want(2)+star+delta];
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [want(2);want(1)+star+delta];
                    subtable = addRow([server1 server2],subtable,K);
                    subtable = addRow([server2 server2],subtable,K);
                    server1 = [want(1)+delta;want(2)+star];
                    subtable = addRow([server1 server2],subtable,K);
                elseif k < 6
                    for m = 1:2
                        for n = 1:length(N1helper)
                            if m == 1 && n > 1
                                server1 = [N1helper(n,:)*want;star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            elseif m == 2
                                server1 = [N1helper(n,:)*want+star+delta;N1helper(n,:)*want+star+delta];
                                subtable = addRow([server1 server2],subtable,K);
                            end
                        end
                    end
                elseif k < 8
                    server1 = [star;want(8-k)+delta]; % want(8-k) is b when k is 6 and a when k is 7
                    subtable = addRow([server1 server2],subtable,K);
                    server1 = [delta;want(8-k)+star];
                    subtable = addRow([server1 server2],subtable,K);
                elseif k < 9
                    for m = 2:length(N1helper)-1
                        server1 = [star;N1helper(m,:)*want+delta];
                        subtable = addRow([server1 server2],subtable,K);
                        server1 = [delta;N1helper(m,:)*want+star];
                        subtable = addRow([server1 server2],subtable,K);
                    end
                else
                    for m = 2:length(N1helper)
                        server1 = [star+delta;N1helper(m,:)*want];
                        subtable = addRow([server1 server2],subtable,K);
                    end
                end
            end
            row = [star delta;want(1)+want(2)+delta want(1)+want(2)+star];
            subtable = addRow(row,subtable,K);
            row = [want(1)+star+delta want(2)+star+delta;want(1)+star+delta want(2)+star+delta];
            subtable = addRow(row,subtable,K);
            table = cat(3,table,subtable);
        end
    end
end
% table
table = reshape(table,[4,size(table,3)])';
table = unique(table,'rows','stable');

noRows = size(table,1);
downloadCnt = zeros(noRows,1);
coefs = zeros(noQueries,noQueries,noRows); % q1xq2xrow
for r = 1:noRows
    coefs(table(r,1)+1,table(r,2)+1,r) = coefs(table(r,1)+1,table(r,2)+1,r) + 1;
    coefs(table(r,3)+1,table(r,4)+1,r) = coefs(table(r,3)+1,table(r,4)+1,r) + 1;
    for q = 1:4
        if table(r,q) ~= 0
            downloadCnt(r) = downloadCnt(r) + 1;
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
            if ~visited2(q0_1+1,q0_2+1) && (q0_1 == q0_2 || ~shareFiles(q0_1,q0_2,K))
                visited2(q0_1+1,q0_2+1) = 1;
                visited2(q0_2+1,q0_1+1) = 1;
                v0 = coefs(q0_1+1,q0_2+1,:);
                q0_1_b = de2bi(q0_1,K);
                q0_2_b = de2bi(q0_2,K);
                q0_1_size = sum(q0_1_b);
                q0_2_size = sum(q0_2_b);
                same = all(q0_1_b == q0_2_b);
                for q_1 = G{i}(1:end)
                    for q_2 = G{j}(1:end)
                        if visited2(q_1+1,q_2+1) || q_1 ~= q_2 && shareFiles(q_1,q_2,K)
                            continue;
                        end
                        q_1_b = de2bi(q_1,K);
                        q_2_b = de2bi(q_2,K);
                        if (sum(q_1_b) == q0_1_size && sum(q_2_b) == q0_2_size && all(q_1_b == q_2_b) == same)
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
[x,fval] = linprog(downloadCnt,[],[],Aeq,beq,LB,UB);
I = find(x ~= 0);
newx = x(I);
results_table = [];
for i = 1:length(I)
    results_table = [results_table; table(I(i),:)];
end
fprintf('%10s%10s%10s%10s%10s%10s','row','leftt','leftb','rightt','rightb','prob');
disp(newline);
disp([I,results_table,newx]);

results_alpha = [];
for i = 1:size(results_table,1)
    row = [];
    for j = 1:size(results_table,2)
        temp = de2bi(results_table(i,j),K);
        str = "";
        if temp(1) str = str + "a"; end
        if K > 1 && temp(2) str = str + "b"; end
        if K > 2 && temp(3) str = str + "c"; end
        if K > 3 && temp(4) str = str + "d"; end
        if K > 4 && temp(5) str = str + "e"; end
        if K > 5 && temp(6) str = str + "f"; end
        row = [row,str];
    end
    results_alpha = [results_alpha;row];
end
results_alpha = reshape(results_alpha',[2,2,size(results_alpha,1)]);

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

function share = shareFiles(num1,num2,K)
    arr1 = de2bi(num1,K);
    arr2 = de2bi(num2,K);
    for i = 1:length(arr1)
        if (arr1(i) == 1 && arr2(i) == 1)
            share = true;
            return;
        end
    end
    share = false;
end

function table = addRow(row,table,K)
    for i = 1:2
        if shareFiles(row(1,i),row(2,i),K) && row(1,i) ~= row(2,i)
            return;
        end
    end
    row = [sort(row(:,1)) sort(row(:,2))];
    if (row(1,1) > row(1,2))
        row = [row(:,2) row(:,1)];
    end
    table = cat(3,table,row);
end