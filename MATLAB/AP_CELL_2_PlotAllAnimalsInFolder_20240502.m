% This script summarized all animals within a given folder and plots them
% into one 3D brain (flipped if necessary)

% open folder that contains either "*_CCF_Coords.mat" files or subfolders
% with animals that have been processed

% single channel only for now, not sure how to display seperate channels
% AND seperate groups... (maybe as seperate plots?)

%also add to exclude excluded animals lol

clearvars; clc;
ExperimentName = 'EDS';
fliptoright = 0; %flips the coordinates to the right hemisphere if wanted, otherwise put to 0 to keep it at the side it was traced at (eg if bilateral)
owncolors = 1; %do you want to define your own colors for groups instead of using default (red, green, blue)?
alphaValue = 0.1; %how transparent each volume should be (1 = fully visible, 0 = not visible)
savevideo = 1;

%% Ask the user for the number and names of groups
prompt = {'Enter the number of groups:'};
dlgtitle = 'Number of Groups';
dims = [1 35];
num_groups_str = inputdlg(prompt, dlgtitle, dims);
num_groups = str2double(num_groups_str{1}); % Convert to number

% Check if the number is valid
if isnan(num_groups) || num_groups <= 0
    error('Please enter a valid number of groups.');
end

% Prepare prompts for entering group names
group_names_prompt = cell(num_groups, 1);
for i = 1:num_groups
    group_names_prompt{i} = sprintf('Enter name for group %d:', i);
end

% Ask the user for group names
group_dlg_title = 'Group Names';
group_names = inputdlg(group_names_prompt, group_dlg_title, [1 50]);

% Display the entered group names
if isempty(group_names)
    disp('No group names were entered.');
else
    fprintf('Group names entered:\n');
    fprintf('%s ',group_names{:});
end


%% Assign group to animals or exclude
% Define base directory and find files
baseDir = pwd;
files = dir(fullfile(baseDir, '**', '*_CCF_coords.mat'));

% Extract animal names from filenames
animal_names = unique(cellfun(@(f) f(1:strfind(f, '_')-1), {files.name}, 'UniformOutput', false));

% Define group names + "exclude" option
group_names_assign = [group_names; 'Exclude'];

group_assignments = assign_groups_to_animals(animal_names, group_names_assign);

%% own color palette

% Initialize containers.Map for the default colors
default_colors = containers.Map('KeyType', 'char', 'ValueType', 'any');

base_colors = {[1, 0, 0], [0, 1, 0], [0, 0, 1], [0, 1, 1], [1, 1, 0], [1, 0, 1], [0.5, 0.5, 0.5]};  % Red, Green, Blue, Cyan, Yellow, Magenta, Gray
% Assign colors to groups
for i = 1:numel(group_names)
    if i <= length(base_colors)
        default_colors(group_names{i}) = base_colors{i};
    else
        % Generate a random color if more groups than base colors
        default_colors(group_names{i}) = rand(1, 3);
    end
end

% Call the function to get group colors
if (owncolors == 1)
    try
        group_colors = select_group_colors(group_names);
        if isempty(group_colors)
            error('Color selection was cancelled or failed.');  % Trigger fallback on empty return
            group_colors = default_colors;
        end
    catch
        disp('Failed to select custom colors, using default colors.');
        group_colors = default_colors;
    end
else
    group_colors = default_colors;  % Use default colors
end

% Prepare color scheme
%colorAdjustmentFactor = linspace(0.7, 1, numel(animal_names)); % Generate lightness adjustments
hueIncrement = linspace(-0.05, 0.05, numel(animal_names));  % Small increments around the base hue
saturationFactor = linspace(0.6, 1, numel(animal_names));  % Ensure this stays within 0 to 1 after adjustment

%% Initialize variables for concatenation

organizedData = table() ; % For tables
% Process each file and add group information
for i = 1:length(files)
    fullFilePath = fullfile(files(i).folder, files(i).name);
    load(fullFilePath, 'ccf_summary');

    % Find group for the current animal
    animalName = animal_names{i};
    group = 'Unassigned';  % Default group
    for j = 1:length(group_assignments)
        if strcmp(group_assignments(j).Animal, animalName)
            group = group_assignments(j).Group;
            break;
        end
    end

    % Make column name checks case-insensitive
    ccf_summary_col_names = lower(ccf_summary.Properties.VariableNames);
    organizedData_col_names = lower(organizedData.Properties.VariableNames);

    % Add group to ccf_summary if not already present
    if ~ismember('group', ccf_summary_col_names)
        ccf_summary.group = repmat({group}, height(ccf_summary), 1);
    end

    % Add animal name to ccf_summary if not already present
    if ~ismember('animal', ccf_summary_col_names)
        ccf_summary.animal = repmat({animalName}, height(ccf_summary), 1);
    end


    % Append data
    if isempty(organizedData)
        organizedData = ccf_summary;  % If first file, initialize the table
    else
        % Check for missing and extra columns
        missingVarsInOrganizedData = setdiff(ccf_summary.Properties.VariableNames, organizedData.Properties.VariableNames);
        extraVarsInOrganizedData = setdiff(organizedData.Properties.VariableNames, ccf_summary.Properties.VariableNames);

        % Highlight missing and extra columns
        if ~isempty(missingVarsInOrganizedData)
            fprintf('Missing columns in organizedData: %s\n', strjoin(missingVarsInOrganizedData, ', '));

        end
        if ~isempty(extraVarsInOrganizedData)
            fprintf('Extra columns in organizedData: %s\n', strjoin(extraVarsInOrganizedData, ', '));
        end

        % Append data
        organizedData = [organizedData; ccf_summary];  % Append data
    end


end

% Rename variable and save consolidated data
writetable(organizedData, [ExperimentName,'_ConsolidatedCCF.csv']);


%% Initialize figures
figure1 = figure('Name', 'All Animals Combined', 'Color', 'w');
fig1ax = axes;
set(fig1ax, 'ZDir', 'reverse');

figure2 = figure('Name', 'Individual Animals', 'Color', 'w');
fig2ax = axes;
set(fig2ax, 'ZDir', 'reverse');
numAnimals = length(animal_names);
numRows = ceil(sqrt(numAnimals));
numCols = ceil(numAnimals / numRows);

midline = 575;

% Prepare the brain outline for both figures
allen_atlas_path = fullfile(userpath, 'AP_histology', 'allenAtlas');
av = readNPY(fullfile(allen_atlas_path, 'annotation_volume_10um_by_index.npy'));
slice_spacing = 5;
reduced_av = av(1:slice_spacing:end, 1:slice_spacing:end, 1:slice_spacing:end);
brain_volume = bwmorph3(bwmorph3(reduced_av > 1, 'majority'), 'majority');
brain_outline_patchdata = isosurface(permute(brain_volume, [3,1,2]), 0.5);

% Plot brain in figure 1 (combined plot)
figure(figure1);
patch('Vertices', brain_outline_patchdata.vertices * slice_spacing, ...
    'Faces', brain_outline_patchdata.faces, ...
    'FaceColor', [0.7, 0.7, 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.1);
hold on;

legendHandles = [];
legends = {};

grouped_data = containers.Map;

% Process each animal
for idx = 1:length(animal_names)
    fullPath = fullfile(files(idx).folder, files(idx).name);
    animalName = animal_names{idx};

    % Find group for the current animal
    group = 'Unassigned';
    for i = 1:length(group_assignments)
        if strcmp(group_assignments(i).Animal, animalName)
            group = group_assignments(i).Group;
            break;
        end
    end

    % Get color for the group
    if isKey(group_colors, group)
        baseColor = group_colors(group);
    else
        baseColor = [0.5, 0.5, 0.5];  % Default gray if no color assigned
    end

    % Adjust color for animal
    hsvColor = rgb2hsv(baseColor);
    hsvColor(1) = mod(hsvColor(1) + hueIncrement(idx), 1);  % Adjust hue
    hsvColor(2) = min(1, max(0, hsvColor(2) * saturationFactor(idx)));  % Adjust saturation
    adjustedColor = hsv2rgb(hsvColor);

    % Load data
    load(fullPath, 'ccf_summary');

    if fliptoright == 1 %flips to one hemisphere if wanted
        y_coords = ccf_summary.Y;
        flip_indices = y_coords < midline;
        ccf_summary.Y(flip_indices) = 2 * midline - y_coords(flip_indices);
    end

    % Plot in the combined figure
    figure(figure1);
    h = scatter3(ccf_summary.Z, ccf_summary.Y, ccf_summary.X, ...
        80, adjustedColor, 'filled', 'MarkerEdgeAlpha', alphaValue, 'MarkerFaceAlpha', alphaValue, 'DisplayName', animalName);
    legendHandles(end+1) = h;
    legends{end+1} = sprintf('%s', animalName);

    % Collect data by group for plotting in the group figure
    if isKey(grouped_data, group)
        grouped_data(group) = [grouped_data(group); ccf_summary];
    else
        grouped_data(group) = ccf_summary;
    end

    % Plot in the individual subplot
    figure(figure2);
    subplot(numRows, numCols, idx);
    patch('Vertices', brain_outline_patchdata.vertices * slice_spacing, ...
        'Faces', brain_outline_patchdata.faces, ...
        'FaceColor', [0.7, 0.7, 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.1);
    hold on;
    set(gca, 'ZDir', 'reverse');
    set(gca, 'Color', 'w');
    axis('vis3d', 'equal');
    axis('off');
    view(90, 90);
    axis tight;
    rotate3d on;
    scatter3(ccf_summary.Z, ccf_summary.Y, ccf_summary.X, ...
        30, adjustedColor, 'filled', 'MarkerEdgeAlpha', alphaValue, 'MarkerFaceAlpha', alphaValue);
    title(animalName);
end


% Add legend to the combined figure
figure(figure1);
legend(legendHandles, legends, 'Location', 'bestoutside');
legend(['Brain', legends], 'Location', 'northeastoutside', 'NumColumns', 1);
set(gca, 'ZDir', 'reverse');
set(gca, 'Color', 'w');
axis('vis3d', 'equal');
axis('off');
view(90, 90);
axis tight;
rotate3d on;

savename = fullfile(baseDir, [ExperimentName, '_3DPlot_Combined']);
savefig(figure1, savename);
print([savename, '.png'], '-dpng');
disp(['Figure 1 saved as ', savename, '.png and .m']);
%print('-dpng', '-r300', fullfile(baseDir, 'All_Animals_Combined_HighRes.png'));  % Save as High-Resolution PNG

if(savevideo == 1)
    %Save as video
    view(90, 90);
    axis tight;
    rotate3d on;
    lgd = findobj('type', 'legend');
    delete(lgd);

    OptionZ.FrameRate=60;OptionZ.Duration=5.5;OptionZ.Periodic=true;
    CaptureFigVid([90,90;-50,45;90,90], [ExperimentName,'__3DPlot_Combined'],OptionZ)
end


savename = fullfile(baseDir, [ExperimentName, '_3DPlot_OverviewAnimals']);
savefig(figure2, savename);
print([savename, '.png'], '-dpng');
disp(['Figure 2 saved as ', savename, '.png and .m']);

%%
figure3 = figure('Name', 'Groups Combined', 'Color', 'w');

fig3ax = axes;
set(fig3ax, 'ZDir', 'reverse');
numGroups = length(group_names);
numGroupCols = 2;  % Fixed number of columns
numGroupRows = ceil(numGroups / numGroupCols);

% Plot in the group figure
figure(figure3);
for i = 1:length(group_names)
    group = group_names{i};
    if isKey(grouped_data, group)
        ccf_summary_group = grouped_data(group);
        adjustedColor = group_colors(group);

        % Create subplot for each group
        subplot(numGroupRows, numGroupCols, i);
        patch('Vertices', brain_outline_patchdata.vertices * slice_spacing, ...
            'Faces', brain_outline_patchdata.faces, ...
            'FaceColor', [0.7, 0.7, 0.7], 'EdgeColor', 'none', 'FaceAlpha', 0.1);
        hold on;
        view([90, 90]);
        axis('vis3d', 'equal', 'off', 'manual');
        axis tight;
        scatter3(ccf_summary_group.Z, ccf_summary_group.Y, ccf_summary_group.X, ...
            30, adjustedColor, 'filled', 'MarkerEdgeAlpha', alphaValue, 'MarkerFaceAlpha', alphaValue);
        title(group);
    end
end

savename = fullfile(baseDir, [ExperimentName, '_3DPlot_Groups']);
savefig(figure3, savename);
print([savename, '.png'], '-dpng');
disp(['Figure 3 saved as ', savename, '.png and .m']);

%%

%print('-dpng', '-r300', fullfile(baseDir, 'All_Animals_Combined_HighRes.png'));  % Save as High-Resolution PNG