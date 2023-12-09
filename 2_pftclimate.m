%=====================================================
%   根据Poulter et al., (2011)从koppen气候分区对应到PFT
%=====================================================
clear all;close;clc;
% 1------------读取Excel文件及相关变量
Tallo = readtable(['C:/Users/Administrator.DESKTOP-9EGRBRO/Documents/treedata' ...
    '/Tallo_zonecode_matched_39w.csv'], 'VariableNamingRule', 'preserve');

Tallo_bkp=Tallo; %Tallo_bkp是原始读入的数据39w
%%
% 1-----根据zonecode区分粗略的气候区
Tallo.climate(:) = "NA";
% tropical
tro_row=(Tallo.zonecode <= 4) | (Tallo.zonecode == 6);
Tallo.climate(tro_row)="tropical";
% temperate
tem_row=(Tallo.zonecode > 4) & (Tallo.zonecode ~= 6) & (Tallo.zonecode <=16 );
Tallo.climate(tem_row)="temperate";
% boreal
bor_row=(Tallo.zonecode >= 17);
Tallo.climate(bor_row)="boreal";
%%
% 2-----根据zonecode区分细致的气候区
zonecode = Tallo.zonecode;
% 根据Poulter et al., (2011)，使用koppen气候数据对植被进行详细的PFT biome equivalent分类
pft_tropical = [1, 2, 3, 4, 6];
pft_temperatewarm = [5, 7, 8, 11, 14];
pft_temperatecool = [9, 10, 12, 13, 15, 16];
pft_borealwarm = [17, 21, 25];
pft_borealcool = [18, 19, 20, 22, 23, 24, 26, 27, 28, 29, 30];

pftcli = strings(length(zonecode), 1);

for i=1:length(zonecode)
    value = zonecode(i,1);
    if ismember(value, pft_tropical)
        pftcli(i,1) = 'tropical';
    elseif ismember(value, pft_temperatewarm)
        pftcli(i,1) = 'temperatewarm';
    elseif ismember(value, pft_temperatecool)
        pftcli(i,1) = 'temperatecool';
    elseif ismember(value, pft_borealwarm)
        pftcli(i,1) = 'borealwarm';
    elseif ismember(value, pft_borealcool)
        pftcli(i,1) = 'borealcool';
    end
end

Tallo.pftcli = pftcli;
% 输出匹配pftcli后的Tallo到表格：Tallo_matched_39w.csv
filename='C:/Users/Administrator.DESKTOP-9EGRBRO/Documents/treedata/Tallo_zonecode_matched_pftcli_39w.csv';
writetable(Tallo, filename);
save('Tallo_zonecode_matched_pftcli_39w.mat')
%%
% 3-----合并叶片类型和叶片物候类型

selectLeafType_row=(Tallo.LeafTypeFromTRY=="broadleaved") | ...
    (Tallo.LeafTypeFromTRY=="needleleaved");
selectLeafPh_row=(Tallo.LeafPhenologyFromTRY=="evergreen") | ...
    (Tallo.LeafPhenologyFromTRY=="deciduous");
select_row= selectLeafType_row & selectLeafPh_row; %同时满足两种条件才为真
Tallo(select_row==0,:)=[]; %删除叶片类型或叶片物候类型不符合要求的数据55403行，剩下340967行

Tallo.Leaf= strcat(Tallo.LeafTypeFromTRY," ",Tallo.LeafPhenologyFromTRY); %合并为新的一列

Tallo.pft_fullold=strcat(Tallo.climate," ",Tallo.Leaf);

%%
% 4-----根据zonecode和叶片类型、叶片物候类型划分具体的pft，参考Poulter et al., (2011)聚类
Leaf=Tallo.Leaf;
pftcli=Tallo.pftcli;
pft_full = strings(height(Tallo), 1);
pft = strings(height(Tallo), 1);

tic
for i = 1:height(Tallo)
    if strcmp(Leaf{i}, 'broadleaved evergreen') 
        if strcmp(pftcli{i}, 'tropical')
            pft_full(i) = 'tropical broadleaved evergreen';
            pft(i) = 'TBE';
            nTBE=sum(pft == "TBE");
        elseif ismember(pftcli{i}, {'temperatewarm','temperatecool', ...
                'borealwarm','borealcool'})
            pft_full(i) = 'temperate broadleaved evergreen';%划分为温带常绿阔叶林
            pft(i) = 'MBE';
            nMBE=sum(pft == "MBE");
        end
    elseif strcmp(Leaf{i}, 'needleleaved evergreen')
        if ismember(pftcli{i}, {'tropical','temperatewarm', ...
                'temperatecool','borealwarm'})
            pft_full(i) = 'temperate needleleaved evergreen';%划分为温带常绿针叶林
            pft(i) = 'MNE';
            nMNE=sum(pft == "MNE");
        elseif strcmp(pftcli{i}, 'borealcool')
            pft_full(i) = 'boreal needleleaved evergreen';
            pft(i) = 'BNE';
            nBNE=sum(pft == "BNE");
        end
     elseif strcmp(Leaf{i}, 'broadleaved deciduous')
        if ismember(pftcli{i}, {'temperatecool','temperatewarm','borealwarm'})
            pft_full(i) = 'temperate broadleaved deciduous';
            pft(i) = 'MBD';
            nMBD=sum(pft == "MBD");
        elseif strcmp(pftcli{i}, 'tropical')
            pft_full(i) = 'tropical broadleaved deciduous';
            pft(i) = 'TBD';
            nTBD=sum(pft == "TBD");
        elseif strcmp(pftcli{i}, 'borealcool')
            pft_full(i) = 'boreal broadleaved deciduous';
            pft(i) = 'BBD';
            nBBD=sum(pft == "BBD");
        end
     elseif strcmp(Leaf{i}, 'needleleaved deciduous')
        if ismember(pftcli{i}, {'temperatecool','temperatewarm','borealwarm'})
            pft_full(i) = 'temperate needleleaved deciduous';
            pft(i) = 'MND';
            nMND=sum(pft == "MND");
        elseif strcmp(pftcli{i}, 'tropical')
            pft_full(i) = 'tropical needleleaved deciduous';
            pft(i) = 'TND';
            nTND=sum(pft == "TND");
        elseif strcmp(pftcli{i}, 'borealcool')
            pft_full(i) = 'boreal needleleaved deciduous';
            pft(i) = 'BND';
            nBND=sum(pft == "BND");
        end
    end
end
toc
Tallo.pft_full=pft_full;
Tallo.pft=pft;
%%

% 输出匹配pftcli后的Tallo到表格：Tallo_matched_pft_34w.csv
filename='C:/Users/Administrator.DESKTOP-9EGRBRO/Documents/treedata/Tallo_matched_pft_34w.csv';
writetable(Tallo, filename);
save('Tallo_matched_pft_34w.mat')