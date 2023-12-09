% ================================================================
% aim：根据species_Tallo对应species_TRY，提取叶片类型和叶片物候类型
%=================================================================

% 1-----读取表格
Tallo = readtable(['C:\Users\Administrator.DESKTOP-9EGRBRO\Documents\treedata\TALLO-main\DB\Tallo.csv\' ...
    'Tallo.csv'],'VariableNamingRule', 'preserve');
TRY = readtable(['C:\Users\Administrator.DESKTOP-9EGRBRO\Documents\treedata\' ...
    'Try2023911153959TRY_Categorical_Traits_Lookup_Table_2012_03_17_TestRelease\' ...
    'TRY_Categorical_Traits_Lookup_Table_2012_03_17_TestRelease.xlsx'],'VariableNamingRule', 'preserve');
Tallo_bkp=Tallo; %原始表格备份
TRY_bkp=TRY;
%%
% 2-----数据质量控制，49w减少为43w
% ***1st. control：排除H<1.3m，D<1cm的树木（Tallo原数据已剔除，无需操作）
% ***2nd. control：剔除由Mahalanobis distance选出的H、CR异常极值，
%               根据height_outlier\crown_radius_outlier=Y控制

%任意有一个满足就删除这一行
rows_to_delete = strcmp(Tallo.height_outlier, 'Y') | strcmp(Tallo.crown_radius_outlier, 'Y'); % |表示“或” 
Tallo(rows_to_delete, :) = []; %剔除980行，Tallo的行数从498838减少为497858

% ***3rd. control：剔除没有species信息的行，根据species=NA控制

rows_species_na = strcmp(Tallo.species, 'NA');
Tallo(rows_species_na, :) = []; %剔除61053行，Tallo的行数从497858减少为436805
%%
% 3-----匹配柯本气候分区
% 读取nc文件
ncfile = "C:\Users\Administrator.DESKTOP-9EGRBRO\Documents\treedata" + ...
    "\koppen\pft_par_climate\Beck_KG_V1\Beck_KG_V1_present_0p0083.nc";

lat = ncread(ncfile, 'lat');
lon = ncread(ncfile, 'lon');
zonecode = ncread(ncfile, 'zonecode');

% 获取站点经纬度数据
sitelat = Tallo.latitude;
sitelon = Tallo.longitude;

% 创建空数组存储结果
zone = [];

% 循环处理每个站点
for i = 1:length(sitelat)
    % 计算最近的经纬度索引
    [~, lat_idx] = min(abs(lat - sitelat(i)));
    [~, lon_idx] = min(abs(lon - sitelon(i)));
    % 获取对应的气候分区代码
    zonecode_val = zonecode(lon_idx, lat_idx);
    zone = [zone; zonecode_val];
end

% 将zonecode添加到 Tallo 表中
Tallo.zonecode = zone;

% 写入 CSV 文件
writetable(Tallo, ['C:\Users\Administrator.DESKTOP-9EGRBRO\Documents' ...
    '\treedata\Tallo_43w_zonecode_wait4match.csv']);
save('Tallo_43w_zonecode_wait4match.csv.mat') % 保存工作区
%%


%%
% 4-----两表species对应，匹配到的物种数量为：396370
tic
% 找到Tallo中与TRY匹配的物种名称的索引
[matchTallorow, matchTRYrow] = ismember(Tallo.species, TRY.AccSpeciesName);
% 计算匹配和不匹配的数量
numMatch = sum(matchTallorow);
numMismatch = height(Tallo) - numMatch;
disp(['匹配到的物种数量为：', num2str(numMatch)]);
disp(['未匹配到的物种数量为：', num2str(numMismatch)]);
% 初始化所有值为 'NA'
Tallo.LeafTypeFromTRY(:) = "NA";
Tallo.LeafPhenologyFromTRY(:) = "NA";
Tallo.PlantGrowthFormFromTRY(:) = "NA";
Tallo.GenusFromTRY(:) = "NA";
Tallo.FamilyFromTRY(:) = "NA";
% 将匹配到的值赋值给 Tallo
idx = matchTallorow & matchTRYrow > 0; % 只赋值匹配到的部分
Tallo.LeafTypeFromTRY(idx) = TRY.LeafType(matchTRYrow(idx));
Tallo.LeafPhenologyFromTRY(idx) = TRY.LeafPhenology(matchTRYrow(idx));
Tallo.PlantGrowthFormFromTRY(idx) = TRY.PlantGrowthForm(matchTRYrow(idx));
Tallo.GenusFromTRY(idx) = TRY.Genus(matchTRYrow(idx));
Tallo.FamilyFromTRY(idx) = TRY.Family(matchTRYrow(idx));
toc
%%
% 5-----未匹配species的行，根据matchTallorow逻辑数组中的0控制
rows_mismatch = find(~matchTallorow);
Tallo(rows_mismatch, :) = []; %剔除40435行，Tallo的行数从436805减少为396370
%%
% 6-----输出匹配扩展后的Tallo到表格：Tallo_matched_39w.csv
filename='C:/Users/Administrator.DESKTOP-9EGRBRO/Documents/treedata/Tallo_zonecode_matched_39w.csv';
writetable(Tallo, filename);
save('Tallo_zonecode_matched_39w.mat')
%%
% 7-----初步展示分类结果
var = ["LeafType", "LeafPhenology", "PlantGrowthForm"];
for i = 1:length(var)
    % 构建列名称
    columnName = var(i) + "FromTRY";
    % 提取当前 var 元素对应的列中唯一的值和出现次数
    [C,ia,ic] = unique(Tallo.(columnName),'stable');
    % C 返回包含的各个元素名称
    % ia返回C中每个元素名称第一次出现的行数
    % accumarray计算 C 中的每个元素在 a 中出现的次数
    counts = accumarray(ic,1);
    % 创建一个新表格，包含当前 var 元素列中唯一的值和出现次数
    count_tb = table(C, counts, 'VariableNames', {char(columnName), 'num'});  
    % 按照出现次数降序排列表格
    count_tb = sortrows(count_tb, 'num', 'descend')
    % % 输出表格
    % disp(count_tb);
end
%%
% 使用逻辑索引选择符合条件的行（落叶阔叶）
selected_rows = (Tallo.LeafTypeFromTRY == 'broadleaved') ...
    & (Tallo.LeafPhenologyFromTRY == 'deciduous')...
    & (Tallo.latitude >= 45 | Tallo.latitude <= -45);

% 统计符合条件的行数
num_selected_rows = sum(selected_rows);

% 输出结果
fprintf("±45°以外落叶阔叶树样本为 %d\n", num_selected_rows);
% 使用逻辑索引选择符合条件的行（落叶针叶）
selected_rows = (Tallo.LeafTypeFromTRY == 'needleleaved') ...
    & (Tallo.LeafPhenologyFromTRY == 'deciduous')...
    & (Tallo.latitude >= 45 | Tallo.latitude <= -45);

% 统计符合条件的行数
num_selected_rows = sum(selected_rows);

% 输出结果
fprintf("±45°以外落叶针叶树样本为 %d\n", num_selected_rows);
