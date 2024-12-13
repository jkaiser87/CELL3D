%% Plot FIJI detected cells into CCF 3D brain

clearvars; clc;

% adapt these settings:

rerun_histology = 0; %redo AP_Histology? an be 0 if already done
medlat = 0; %do classification? can be 0 if already done
channels = {'C1'}; % Define which channels to include in this analysis. 

colorcellsby = 'ML'; % how cells should be colored by in 3D plot: can be 
% --- 'ML' (med/lat/cing)
% --- 'Areas' (brain structures allen),
% --- "channel" to plot by channel color (C1,C2,C3)
% --- or empty for plain color


% This following parameter allows you to additionally copy the *.mat file
% into an additional folder. This allows you to copy several animals into
% the same folder across separate animals by using the same "addfolder" for
% all.

saveadditionally = 1;
addfolder="Z:\Research\Sahni Lab\Data\_Team_ABC\_NPY_Behavior\_Analysis\20240611_APhist";

%% Don't change here
parentFolder = pwd;
cd(parentFolder);

subfolderName = 'OUT';
outputFolderPath = fullfile(parentFolder, subfolderName);

% Check if the subfolder already exists
if ~exist(outputFolderPath, 'dir')
    mkdir(outputFolderPath);
end

% Run AP_histology if needed
if (rerun_histology == 1)
    AP_histology
    fprintf('Go through all steps in AP_histology window, then continue by pressing any key inside the terminal. \nTo stop, press Ctrl + C \n ');
    pause;
end

%% Data processing to classify cells and plot
if (medlat==1)
    MATLAB_Fiji_Medlat_classification_CELLS_channel(pwd, channels) %this will process channel dependent files to get med/lat/cing classifier
end

folderPath_class = fullfile(parentFolder,'OUT');

% Define folders
parentFolder = pwd;
slice_path = fullfile(parentFolder,'OUT'); %this is the folder you set as output in the step before!
save_path = fullfile(slice_path,'CCF'); %slice_path+filesep+'CCFCoords';
if ~exist(save_path, 'dir')
    mkdir(save_path);
end

% Now, to get the name of the parent folder from the parentFolderPath
[parentFolderPath, parentFolderName, ~] = fileparts(parentFolder);
%[~, parentFolderName, ~] = fileparts(parentFolderPath);
disp(['-------- Processing ',parentFolderName]);

%% Gather cell coordinates
folderPath = fullfile(parentFolder, 'CSV');
files = dir(fullfile(folderPath, '*.csv'));

histology_points = cell(numel(files), 1);
histology_classifier = cell(numel(files), 1);

for i = 1:numel(files)
    fileName = files(i).name;
    filePath = fullfile(files(i).folder, fileName);
    dataTable = readtable(filePath);

    if exist('folderPath_class', 'var') == 1
        dataTableclass = readtable(fullfile(folderPath_class, ['CLASS_', fileName(4:end)]));
    end

    if isempty(dataTable) || ~all(ismember({'X', 'Y'}, dataTable.Properties.VariableNames))
        continue;
    else
        dataTable = dataTable(~(dataTable.X == 0 & dataTable.Y == 0), :); % Filter out coordinates where X and Y are both 0
        histology_points{i} = [dataTable.X, dataTable.Y];

        if exist('dataTableclass', 'var') == 1 && ismember('classifier', dataTableclass.Properties.VariableNames)
            selectedColumns = {'classifier', 'PercToMidline'};
            histology_classifier{i} = dataTableclass(:, selectedColumns);
        end
    end

    clear fileName dataTable dataTableclass
end

disp('FIJI cell points were read and parameter created');

if (isempty(histology_classifier) == 0)
    disp('Medial/Lateral classifier calculated and loaded');
end

%% Convert points to CCF
ccf_slice_fn = fullfile(slice_path, 'histology_ccf.mat');
load(ccf_slice_fn);

ccf_alignment_fn = fullfile(slice_path, 'atlas2histology_tform.mat');
load(ccf_alignment_fn);

num_channels = length(channels);
num_entries_per_channel = length(atlas2histology_tform);

ccf_points = cell(num_entries_per_channel, num_channels);
valid_classifier = cell(size(histology_classifier));

for idx = 1:length(histology_points)
    if ~isempty(histology_points{idx})
        channel_idx = floor((idx - 1) / num_entries_per_channel) + 1;
        entry_idx = mod(idx - 1, num_entries_per_channel) + 1;

        tform = affine2d;
        tform.T = atlas2histology_tform{entry_idx};
        tform = invert(tform);

        [histology_points_atlas_x, histology_points_atlas_y] = ...
            transformPointsForward(tform, ...
            histology_points{idx}(:,1), ...
            histology_points{idx}(:,2));

        histology_points_atlas_x = round(histology_points_atlas_x);
        histology_points_atlas_y = round(histology_points_atlas_y);

        [M, N] = size(histology_ccf(entry_idx).av_slices);
        valid_x = (histology_points_atlas_x >= 1 & histology_points_atlas_x <= N);
        valid_y = (histology_points_atlas_y >= 1 & histology_points_atlas_y <= M);
        valid_indices = valid_x & valid_y;

        out_of_range_count = nnz(~valid_indices);

        if out_of_range_count > 0
            warning('Excluded - out of range indices for channel %d, image %d: %d points', channel_idx, entry_idx, out_of_range_count);
        end

        valid_x = histology_points_atlas_x(valid_indices);
        valid_y = histology_points_atlas_y(valid_indices);

        if ~isempty(valid_x)
            probe_points_atlas_idx = sub2ind(size(histology_ccf(entry_idx).av_slices), valid_y, valid_x);

            ccf_points{entry_idx, channel_idx} = ...
                [histology_ccf(entry_idx).plane_ap(probe_points_atlas_idx), ...
                histology_ccf(entry_idx).plane_dv(probe_points_atlas_idx), ...
                histology_ccf(entry_idx).plane_ml(probe_points_atlas_idx)];

            % Store valid classifier data
            valid_classifier{idx} = histology_classifier{idx}(valid_indices, :);
        end
    end
end

disp('Cell coordinates were transferred into CCF space');

%% Concatenate points of all slices into one and round to nearest integer coordinate
ccf_points_cat = [];
concatenated_channel = [];
valid_classifier_cat = [];

for channel_idx = 1:num_channels
    current_channel_data = ccf_points(:, channel_idx);
    current_channel_cat = round(cell2mat(current_channel_data));

    if ~isempty(current_channel_cat)
        channelcolumn = repmat(channels(channel_idx), length(current_channel_cat), 1);
        concatenated_channel = [concatenated_channel; channelcolumn];
        ccf_points_cat = [ccf_points_cat; current_channel_cat];
        
        % Concatenate valid classifier data
        valid_classifier_cat = [valid_classifier_cat; vertcat(valid_classifier{:, channel_idx})];
    end

    clear current_channel_data current_channel_cat channelcolumn
end

ccf_summary = table(ccf_points_cat(:, 1), ccf_points_cat(:, 2), ccf_points_cat(:, 3), concatenated_channel, ...
    'VariableNames', {'Z', 'X', 'Y', 'Channel'});

%% Calculate if cells are in L or R hemisphere
yCenter = 575;
ccf_points_cat_side = repmat("L", size(ccf_points_cat, 1), 1);
ccf_points_cat_side(ccf_points_cat(:, 3) > yCenter) = "R";
ccf_points_cat_side_str = string(ccf_points_cat_side);
ccf_summary.Hemisphere = ccf_points_cat_side_str;

disp('Coordinates annotated by hemisphere (L/R)');

%% Calculate Z percentage
allen_data = struct('x_limits', [7.5, 1320], ...
    'y_limits', [57.5, 1092.5], ...
    'z_limits', [22.5, 757.5]);

z_min = round(allen_data.x_limits(1));
z_max = round(allen_data.x_limits(2));
normalized_z = num2cell(((ccf_points_cat(:, 1) - z_min) / (z_max - z_min)) * 100);
ccf_summary.Zperc = normalized_z;

disp('Coordinates annotated by rostral to caudal axis (% front to back)');

%% Add med/lat to table
if ~isempty(valid_classifier_cat)
    if height(valid_classifier_cat) == height(ccf_summary)
        ccf_summary = [ccf_summary, valid_classifier_cat];
    else
        warning('Classifier data length does not match points data length. Excluding classifier data from the table.');
    end
end

disp('Med/Lat classifier transferred to table (med/lat/cingulate)');

%% Save results
save(fullfile(save_path, [parentFolderName, '_CCF_coords.mat']), "ccf_summary", "ccf_points_cat");
savename = fullfile(save_path, [parentFolderName, '_CCFCoords.csv']);
writetable(ccf_summary, savename);
disp(['Full list of converted coordinates saved as ', savename]);

%% Calculate cells per brain structure
allen_atlas_path = fullfile(userpath, 'AP_histology\allenAtlas');
tv = readNPY([allen_atlas_path filesep 'template_volume_10um.npy']);
av = readNPY([allen_atlas_path filesep 'annotation_volume_10um_by_index.npy']);
st = loadStructureTree([allen_atlas_path filesep 'structure_tree_safe_2017.csv']);

ccf_points_idx = sub2ind(size(av), ccf_points_cat(:, 1), ccf_points_cat(:, 2), ccf_points_cat(:, 3));
ccf_points_av = av(ccf_points_idx);
ccf_points_areas = st(ccf_points_av, :).safe_name;
ccf_summary.Brainstruct = ccf_points_areas;

save(fullfile(save_path, [parentFolderName, '_CCF_coords.mat']), "ccf_points_areas", "ccf_summary", '-append');

if (saveadditionally == 1)
    save(fullfile(addfolder, [parentFolderName, '_CCF_coords.mat']), "ccf_points_areas", "ccf_summary");
end

[uniqueEntries, ~, idx] = unique(ccf_points_areas);
counts = accumarray(idx, 1);
summaryTable = table(uniqueEntries, counts, 'VariableNames', {'Structure', 'Count'});

savename = fullfile(save_path, [parentFolderName, '_CellsPerAllenBrainArea.csv']);
writetable(summaryTable, savename);
disp(['Cells per Allen brain structure calculated. Summary Counts saved as ', savename]);

%% Plot cells in 3D
if (~isempty(ccf_summary.classifier))
    allowedValues = {'Medial', 'Lateral', 'Cingulate'};
    filteredRows = ismember(ccf_summary.classifier, allowedValues);
    ccf_summary = ccf_summary(filteredRows, :);
end

disp(['Plotting cells in 3D, colored by ', colorcellsby]);
AP_ccf_outline_coords_JK(ccf_summary, colorcellsby);

disp('Done.');
