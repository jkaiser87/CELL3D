%add L and R hemisphere counts for counting?
%to be added: check that save_atlas_paths exists and points to a correct
%location, otherwise help user to make it

function CELL3D_Step1_Animal_GUI(baseDir)
if ~checkDependencies()
    return; % Exit if dependencies are missing
end

if nargin < 1 || isempty(baseDir)
    baseDir = pwd; % Default to current directory if no input provided
end

if ~isfolder(baseDir)
    error('Specified folder does not exist: %s', baseDir);
end

%setup parameter
handles = struct();
handles.baseDir = baseDir;

% Define color scheme (RGB 0-1)
handles.colors.lightBg = [0.96 0.96 0.96];    % #F5F5F5
handles.colors.thistle = [244 237 234]/255;    % #DBC2CF
handles.colors.coolGray = [0.62 0.64 0.70];   % #9FA2B2
handles.colors.cerulean = [0.24 0.48 0.54];   % #3C7A89
handles.colors.charcoal = [0.18 0.28 0.34];   % #2E4756
handles.colors.gunmetal = [0.09 0.15 0.18];   % #16262E
handles.colors.white = [1 1 1];               % #FFFFFF
handles.colors.errorRed = [0.8 0.2 0.2];      % For error messages
handles.colors.warningColor = [1.0 0.8 0.4];           % pastel amber, hex #FFCC66
handles.colors.successColor = [0.35 0.75 0.45];

% Status colors (adjusted to match your scheme)
handles.colors.statusPending = [0.62 0.64 0.70];  % Your existing coolGray (#9FA2B2)
handles.colors.statusSuccess = [0.30 0.58 0.40];  % Darker, richer green (adjusted from successColor)
handles.colors.statusWarning = [0.85 0.65 0.30];  % Warmer amber (adjusted from warningColor)
handles.colors.statusNotDone = [0.75 0.75 0.78];  % Lighter cool gray variant
handles.colors.statusError = [0.72 0.30 0.30];    % Deeper red (adjusted from errorRed)

% Text colors for contrast (use with above backgrounds)
handles.colors.statusTextDark = [0.18 0.28 0.34]; % Your charcoal (#2E4756)
handles.colors.statusTextLight = [0.96 0.96 0.96]; % Your lightBg (#F5F5F5)
handles.alpha = 0.4;
handles.cellsize = 20;

%GUI setup
handles.fig = uifigure('Name', 'CELL3D Step1 - Animal', 'Position', [100 100 1400 700]);
handles.fig.Color = handles.colors.lightBg;

handles.mainLayout = uigridlayout(handles.fig, [1, 2]);  % Two major sections in GUI
handles.mainLayout.RowHeight = {'1x'};
handles.mainLayout.ColumnWidth = {'3x', '2x'};
handles.mainLayout.Padding = [0 0 0 0];

%left side

% LEFT SIDE UI
handles.uiLeft = uigridlayout(handles.mainLayout, [2, 1]); % 2 rows on left
handles.uiLeft.Layout.Row = 1;
handles.uiLeft.Layout.Column = 1;
handles.uiLeft.RowHeight = {40, '1x'};
handles.uiLeft.Padding = [10 10 10 10];

%----- Setup Header
handles.headerPanel = uipanel(handles.uiLeft, 'Title', '', ...
    'BorderType', 'none', ...  % Changed from 'line' to 'none' for cleaner look
    'BackgroundColor', handles.colors.charcoal, ...
    'HighlightColor', handles.colors.cerulean, ...  % Border highlight color when needed
    'ForegroundColor', handles.colors.white);  % Changed from 'white' to colors.white for consistency

handles.headerLayout = uigridlayout(handles.headerPanel, [1 3]);
handles.headerLayout.ColumnWidth = {'1x', 100, 'fit'};
handles.headerLayout.Padding = [10 5 10 5];
handles.headerLayout.BackgroundColor = handles.colors.charcoal; % Ensure full coverage

uilabel(handles.headerLayout, 'Text', 'CELL3D Step 1 - Animal', ...
    'FontSize', 18, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'FontColor', handles.colors.white, ...  % Explicitly set font color
    'BackgroundColor', handles.colors.charcoal); % Match panel background

% Change folder
handles.browseButton = uibutton(handles.headerLayout, 'Text', 'Change Folder');
handles.browseButton.Layout.Row = 1;
handles.browseButton.Layout.Column = 2;

% Help Button
handles.btnHelp = uibutton(handles.headerLayout, 'Text', 'Help');
handles.btnHelp.Layout.Row = 1;
handles.btnHelp.Layout.Column = 3;
handles.btnHelp.FontColor = handles.colors.white;  % White text
handles.btnHelp.BackgroundColor = handles.colors.gunmetal;  % Grey background to stand out


%----- Main Section (TIFF List + Setup)
% column 1> tif list
handles.uiLeftMain = uigridlayout(handles.uiLeft, [1, 2]); % 2 columns
handles.uiLeftMain.ColumnWidth = {'fit', '1x'};
handles.uiLeftMain.Layout.Row = 2;

handles.tiffListBox = uitable(handles.uiLeftMain, 'Data', cell(0, 1), 'ColumnName', {'Files in Folder'}, 'RowName', []);
handles.tiffListBox.Layout.Column = 1;

% ---  Create Left Right box with setup and buttons as 2 "rows" (first
% setup, 2nd buttons)

handles.uiLeftRight = uigridlayout(handles.uiLeftMain, [4, 1]);
handles.uiLeftRight.Layout.Row = 1;
handles.uiLeftRight.Layout.Column = 2;
handles.uiLeftRight.Padding = [0 0 0 0];
handles.uiLeftRight.RowHeight = {'1x', 80, 150, 150};  % setup panel - status bar - button bar (2 rows now) - status label

% Row 1: Create a dedicated panel for setup options
handles.configPanel = uipanel(handles.uiLeftRight, 'Title', 'Setup');
handles.configPanel.Layout.Column = 1;
handles.configPanel.Layout.Row = 1;
handles.configPanel.FontWeight = 'bold';
handles.configPanel.FontSize = 12;

% Grid layout for the configuration panel
handles.configGrid = uigridlayout(handles.configPanel, [3, 2]);
handles.configGrid.ColumnWidth = {100, '1x'};
handles.configGrid.RowHeight = {'1x', '1x', '1x'};
handles.configGrid.Padding = [10 10 10 10];

% Label for Channel Selection
handles.channelLabel = uilabel(handles.configGrid, 'Text', 'Channels:');
handles.channelLabel.Layout.Row = 1;
handles.channelLabel.Layout.Column = 1;
handles.channelLabel.VerticalAlignment = 'center';

% Grid layout inside the panel for checkboxes
handles.channelsGrid = uigridlayout(handles.configGrid, [1, 4]); % Adjust grid size based on needs
handles.channelsGrid.Layout.Row = 1;
handles.channelsGrid.Layout.Column = 2;
% Creating checkboxes for C1 to C4
handles.channelCheckboxes = gobjects(1, 4); % Pre-allocate a graphics array for checkboxes
channelNames = {'C1', 'C2', 'C3', 'C4'};
for i = 1:4
    handles.channelCheckboxes(i) = uicheckbox(handles.channelsGrid, 'Text', channelNames{i});
    handles.channelCheckboxes(i).Layout.Row = 1;
    handles.channelCheckboxes(i).Layout.Column = i;
end

% Label for Group
handles.groupLabel = uilabel(handles.configGrid, 'Text', 'Group:');
handles.groupLabel.Layout.Row = 2;
handles.groupLabel.Layout.Column = 1;
handles.groupLabel.VerticalAlignment = 'center';

% Text field for Group input
handles.groupEditField = uieditfield(handles.configGrid, 'text');
handles.groupEditField.Layout.Row = 2;
handles.groupEditField.Layout.Column = 2;
handles.groupEditField.Placeholder = 'Enter group (optional)';

% Label for Atlas Type
handles.atlasTypeLabel = uilabel(handles.configGrid, 'Text', 'Atlas Type:');
handles.atlasTypeLabel.Layout.Row = 3;
handles.atlasTypeLabel.Layout.Column = 1;
handles.atlasTypeLabel.VerticalAlignment = 'center';

% Dropdown for Atlas Type
atlasTypes = getAvailableAtlasTypes();
handles.atlasTypeDropdown = uidropdown(handles.configGrid);
handles.atlasTypeDropdown.Items = atlasTypes;
handles.atlasTypeDropdown.Value = '-- SELECT ATLAS --'; % Set default to empty
handles.atlasTypeDropdown.Layout.Row = 3;
handles.atlasTypeDropdown.Layout.Column = 2;

handles.atlasValid = false; % Start as invalid

% status bar

% --- Status Panel (Row 4)
handles.statusGrid = uigridlayout(handles.uiLeftRight, [1, 4]);
handles.statusGrid.Layout.Row = 2;
handles.statusGrid.Layout.Column = 1;
handles.statusGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
handles.statusGrid.Padding = [5 5 5 5];
handles.statusGrid.BackgroundColor = handles.colors.lightBg;

statusNames = {'FIJI Coordinates', 'AP_histology', 'Med/Lat', 'Cell3D Coordinates'};
handles.statusPanels = gobjects(1, 4);
handles.statusLabels = gobjects(1, 4);

for i = 1:4
    handles.statusPanels(i) = uipanel(handles.statusGrid, ...
        'Title', statusNames{i}, ...
        'FontWeight', 'bold');
    handles.statusPanels(i).Layout.Row = 1;
    handles.statusPanels(i).Layout.Column = i;

    % Add centered label inside each panel
    panelLayout = uigridlayout(handles.statusPanels(i), [1, 1]);
    panelLayout.RowHeight = {'1x'};
    panelLayout.ColumnWidth = {'1x'};
    panelLayout.Padding = [0 0 0 0];

    handles.statusLabels(i) = uilabel(panelLayout, ...
        'Text', 'Not available', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'center', ...
        'BackgroundColor', handles.colors.warningColor, ...
        'FontWeight', 'bold', ...
        'FontSize', 12, ...
        'FontColor', handles.colors.gunmetal);
end

%----- Buttons Row

% Create a horizontal layout inside Row 4, Column 2
handles.buttonGrid = uigridlayout(handles.uiLeftRight, [2, 3]);
handles.buttonGrid.Layout.Row = 3;
handles.buttonGrid.Layout.Column = 1;
handles.buttonGrid.RowHeight = {'1x', '1x'};
handles.buttonGrid.ColumnWidth = {'1x', '1x', '1x'};
handles.buttonGrid.Padding = [0 0 0 0];

handles.btnAPHistology = uibutton(handles.buttonGrid, 'Text', 'Run AP_histology', ...
    'Enable', 'off', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'FontColor', handles.colors.white);
handles.btnAPHistology.Layout.Row = 1;
handles.btnAPHistology.Layout.Column = 1;

handles.btnMedLat = uibutton(handles.buttonGrid, 'Text', 'Med/Lat', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'FontColor', handles.colors.white, ...
    'Enable', 'off');

handles.btnMedLat.Layout.Row = 1;
handles.btnMedLat.Layout.Column = 2;

handles.btnRun = uibutton(handles.buttonGrid, 'Text', 'Coordinates → CCF', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontWeight','Bold', ...
    'FontColor', handles.colors.white, ...
    'Enable', 'off');

handles.btnRun.Layout.Row = 1;
handles.btnRun.Layout.Column = 3;

% ---- button row 2

%======= add save coords to diff folder button
subGrid = uigridlayout(handles.buttonGrid);
subGrid.RowHeight = {'1x', '3x'};
subGrid.ColumnWidth = {'1x', '1x', '1x'};
subGrid.Layout.Row = 2;  % Place it in the second row of the parent grid
subGrid.Layout.Column = [1 3];  % Span all three columns of the parent grid
subGrid.Padding = [0 0 0 0];

% save to additional folder
header1 = uilabel(subGrid, 'Text', 'Save to Additional Folder', 'HorizontalAlignment', 'left');
header1.Layout.Row = 1;
header1.Layout.Column = 1;  % Span all three columns for the header

handles.btnSaveAdditional = uibutton(subGrid, 'Text', 'Choose folder...', ...
    'BackgroundColor', handles.colors.coolGray, ...
    'FontColor', handles.colors.white, ...
    'Enable', 'off');
handles.btnSaveAdditional.Layout.Row = 2;
handles.btnSaveAdditional.Layout.Column = 1;

%flip dropdown
header2 = uilabel(subGrid, 'Text', 'Flip to Hemisphere', 'HorizontalAlignment', 'left');
header2.Layout.Row = 1;
header2.Layout.Column = 2;

handles.flipDropdown = uidropdown(subGrid, 'Items', {'None', 'Left', 'Right'}, 'Value', 'None', 'Enable','off');
handles.flipDropdown.Layout.Row = 2;
handles.flipDropdown.Layout.Column = 2;

% Dropdown for 'Color By'
header3 = uilabel(subGrid, 'Text', 'Color Cells By', 'HorizontalAlignment', 'left');
header3.Layout.Row = 1;
header3.Layout.Column = 3;

handles.colorDropdown = uidropdown(subGrid, 'Items', {'Animal'}, 'Value', 'Animal', 'Enable', 'off');
handles.colorDropdown.Layout.Row = 2;
handles.colorDropdown.Layout.Column = 3;

%--- message box
handles.msgLabelLayout = uigridlayout(handles.uiLeftRight, [1, 1]); % One row, two columns
handles.msgLabelLayout.ColumnWidth = {'1x'};
handles.msgLabelLayout.Layout.Row = 4;
handles.msgLabelLayout.Padding = [0 0 0 0]; % No padding

handles.msgPanel = uipanel(handles.msgLabelLayout, 'Title', 'Status', ...
    'BorderType', 'line', ...
    'HighlightColor', handles.colors.charcoal,  ...
    'BackgroundColor', handles.colors.white);          % #3C7A89 (Cerulean)
handles.msgPanel.Layout.Column = 1;

handles.msgLayout = uigridlayout(handles.msgPanel, [1, 1]); % One cell grid layout
handles.msgLayout.RowHeight = {'1x'};
handles.msgLayout.ColumnWidth = {'1x'};
handles.msgLayout.Padding = [0 0 0 0];  % No padding

handles.msgLabel = uilabel(handles.msgLayout, ...
    'Text', 'No errors in the setup', ...
    'FontWeight', 'bold', ...
    'FontSize', 13, ...
    'HorizontalAlignment', 'center', ...  % Center horizontally
    'VerticalAlignment', 'center', ...  % Center vertically
    'FontColor', handles.colors.charcoal, ...
    'BackgroundColor', handles.colors.white, ...
    'WordWrap', 'on');

% --------- RIGHT SIDE AXES FOR PLOTTING
handles.rightPanel = uipanel(handles.mainLayout, ...
    'BorderType','none', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'ForegroundColor', handles.colors.white);

handles.rightPanel.Layout.Row = 1;
handles.rightPanel.Layout.Column = 2;

handles.rightLayout = uigridlayout(handles.rightPanel, [4, 1]);
handles.rightLayout.RowHeight = {40, 50,'1x', 50};
handles.rightLayout.Padding = [10 20 10 10];


%----- Header
%----- Row 1: Right Header (renamed from headerPanel to rightHeader)
handles.rightHeader = uipanel(handles.rightLayout, 'Title', '', ...
    'BorderType', 'none', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'ForegroundColor', handles.colors.white);

handles.rightHeader.Layout.Row = 1;  % Assign to first row of rightLayout

handles.rightHeaderLayout = uigridlayout(handles.rightHeader, [1, 1]);
handles.rightHeaderLayout.Padding = [10 5 10 5];
handles.rightHeaderLayout.BackgroundColor = handles.colors.charcoal;

uilabel(handles.rightHeaderLayout, 'Text', 'CCF Coordinates Plot', ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'FontColor', handles.colors.white, ...
    'BackgroundColor', handles.colors.charcoal);

% ---- Row 2 View Buttons
handles.viewControlGrid = uigridlayout(handles.rightLayout, [1, 3]); % One row, three columns for buttons
handles.viewControlGrid.Layout.Row = 2;  % Assign to second row
% Define buttons

handles.btnSideView = uibutton(handles.viewControlGrid, 'Text', 'Side View');
handles.btnTopView = uibutton(handles.viewControlGrid, 'Text', 'Top View');
handles.btnFrontView = uibutton(handles.viewControlGrid, 'Text', 'Frontal View');

% Distribute buttons equally
handles.btnSideView.Layout.Column = 1;
handles.btnTopView.Layout.Column = 2;
handles.btnFrontView.Layout.Column = 3;

%----- Row 3: Axes (plot area)
handles.ax = uiaxes(handles.rightLayout);
handles.ax.Layout.Row = 3;
handles.ax.XColor = handles.colors.charcoal;  % Axis text/lines
handles.ax.YColor = handles.colors.charcoal;
handles.ax.ZColor = handles.colors.charcoal;

xlabel(handles.ax, 'X (ML)');
ylabel(handles.ax, 'Y (DV)');
zlabel(handles.ax, 'Z (AP)');

view(handles.ax, 90, 90); %default: set to top view

%----- Row 3: Button
handles.bottomControlGrid = uigridlayout(handles.rightLayout, [1, 3]);
handles.bottomControlGrid.Layout.Row = 4;
handles.bottomControlGrid.ColumnWidth = {'1x', '1x','1x'};
handles.bottomControlGrid.Padding = [0 0 0 0];  % no padding for tight fit

% define pallette button
handles.btnCustomPalette = uibutton(handles.bottomControlGrid, 'Text', 'Define Color Palette', ...
    'Enable', 'off');
handles.btnCustomPalette.Layout.Row = 1;
handles.btnCustomPalette.Layout.Column = 1;

% Update button
handles.btnUpdatePlot = uibutton(handles.bottomControlGrid, 'Text', 'Update Plot', ...
    'BackgroundColor', handles.colors.coolGray, ...
    'FontColor', handles.colors.gunmetal, ...
    'FontWeight', 'bold', ...
    'Enable', 'off');
handles.btnUpdatePlot.Layout.Row = 1;
handles.btnUpdatePlot.Layout.Column = 2;

% save Current view
handles.btnSavePreview = uibutton(handles.bottomControlGrid, ...
    'Text', 'Save Plot', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontColor', handles.colors.white, ...
    'FontWeight', 'bold', ...
    'FontSize', 12, ...
    'Enable', 'off');
handles.btnSavePreview.Layout.Row = 1;
handles.btnSavePreview.Layout.Column = 3;


% trigger all events here
updateTiffList(handles.baseDir, handles);
tifFiles = dir(fullfile(handles.baseDir, '*.tif'));
if isempty(tifFiles)
    handles.msgLabel.Text = 'No TIF files found. Please choose another folder.';
    handles.msgLabel.FontColor = handles.colors.errorRed;
else
    checkChannelAvailability(handles);
    handles = updateStatusPanels(handles);
end

handles = LoadCCFSummary(handles);
guidata(handles.fig, handles);  % store updated struct

% Set callbacks after initialization
handles.browseButton.ButtonPushedFcn = @(btn, event) ...
    guidata(btn, browseForFolder(guidata(btn)));
handles.btnHelp.ButtonPushedFcn = @(btn,event) openHelpDialog();

handles.atlasTypeDropdown.ValueChangedFcn = @(src,event) guidata(src, validateAtlasSelection(guidata(src)));

handles.btnAPHistology.ButtonPushedFcn = @(btn, event) guidata(btn, launchAPHistology(guidata(btn)));
handles.btnMedLat.ButtonPushedFcn = @(btn, event) ...
    guidata(btn, runMedLat(guidata(btn), getSelectedChannels(guidata(btn))));
handles.btnRun.ButtonPushedFcn = @(btn, event) ...
    runCell3DTransformation(guidata(btn), getSelectedChannels(guidata(btn)));
handles.btnCustomPalette.ButtonPushedFcn = @(src,evt) openPaletteEditor(guidata(src));
handles.btnUpdatePlot.ButtonPushedFcn = @(btn, event) guidata(btn, updatePlot(guidata(btn)));
handles.btnSavePreview.ButtonPushedFcn = @(btn, event) saveCurrentPlot(guidata(btn));
handles.btnSideView.ButtonPushedFcn = @(btn,event) view(handles.ax, 0, 0);
handles.btnTopView.ButtonPushedFcn = @(btn,event) view(handles.ax, 90, 90);
handles.btnFrontView.ButtonPushedFcn = @(btn,event) view(handles.ax, -90, 0);
handles.btnSaveAdditional.ButtonPushedFcn = @(btn, event) guidata(btn, saveCCFToAdditionalFolder(guidata(btn)));

% Update plot if data exists
if isfield(handles, 'ccf_summary') && ~isempty(handles.ccf_summary)
    guidata(handles.fig, handles);
    updatePlot(handles);
end

handles = validateAtlasSelection(handles);
guidata(handles.fig, handles);

end

%% Set up functions

function handles = browseForFolder(handles);
folder_name = uigetdir();
if folder_name ~= 0
    handles.baseDir = folder_name;
    updateTiffList(folder_name, handles);

    tifFiles = dir(fullfile(folder_name, '*.tif'));
    if isempty(tifFiles)
        handles.msgLabel.Text = 'No TIF files found in folder. Please choose another one.';
        handles.msgLabel.FontColor = handles.colors.errorRed;
    else
        handles = LoadCCFSummary(handles); % <- reloads CCF if present
        checkChannelAvailability(handles);
        handles = updateStatusPanels(handles); % <- calls updatePlotControlsAvailability
        updatePlot(handles); % <- optional, plot automatically
    end

    guidata(handles.fig, handles);  % <- Save updated handles!
    cd(folder_name); % not critical, but keeps file dialogs consistent
end

end


function updateTiffList(folderPath, handles)
% Find TIFF files in the specified folder, considering common TIFF extensions
tiffFiles = dir(fullfile(folderPath, '*.tif'));

if isempty(tiffFiles)
    handles.tiffListBox.Data = {'Empty'};
    handles.msgLabel.Text = 'No TIF files found! Select another folder containing tif files.';
    handles.msgLabel.FontColor = handles.colors.warningColor;
else
    % Extract file names and populate the table
    handles.tiffListBox.Data = {tiffFiles.name}';
    handles.msgLabel.Text = 'TIF Files loaded successfully';
    handles.msgLabel.FontColor = handles.colors.charcoal;
end
end

function checkChannelAvailability(handles)
% Define the subfolder path for CSV files
csvFolderPath = fullfile(handles.baseDir, 'CSV');

% Check if the CSV folder exists
if ~exist(csvFolderPath, 'dir')
    handles.msgLabel.Text = sprintf('CSV subfolder does not exist in the specified directory: \n%s', csvFolderPath);
    handles.msgLabel.FontColor = handles.colors.errorRed;
end

% Get a list of CSV files in the folder
csvFiles = dir(fullfile(csvFolderPath, '*.csv'));
csvFileNames = {csvFiles.name};

% Determine available channels based on file names
channels = {'C1', 'C2', 'C3', 'C4'};
channelAvailable = false(1, length(channels)); % Initialize availability array

for i = 1:length(channels)
    % Check for each channel if there is a corresponding file
    pattern = sprintf('%s_*', channels{i}); % e.g., 'C1_*'
    match = any(~cellfun(@isempty, regexp(csvFileNames, pattern)));
    channelAvailable(i) = match;

    % Enable/disable the checkbox based on file presence
    handles.channelCheckboxes(i).Enable = 'on';
    handles.channelCheckboxes(i).Value = true;
    if ~match
        handles.channelCheckboxes(i).Enable = 'off';
        handles.channelCheckboxes(i).Value = false;
    end
end
end

function atlasTypes = getAvailableAtlasTypes()
% Locate AP_histology path
ap_histology_path = which('AP_histology');
if isempty(ap_histology_path)
    error('AP_histology.m not found in MATLAB path.');
end
ap_histology_dir = fileparts(ap_histology_path);

% Check for the existence of the atlas settings file
atlas_settings_path = fullfile(ap_histology_dir, 'atlas_paths.mat');
if ~exist(atlas_settings_path, 'file')
    error('atlas_paths.mat not found. Please run save_atlas_paths.m first.');
end

% Load available templates from atlas settings
load(atlas_settings_path, 'templates');

% Extract and return all available atlas types
atlasTypes = ['-- SELECT ATLAS --'; fieldnames(templates)];
end



function handles = updateStatusPanels(handles)
status = checkProcessingSteps(handles.baseDir);

% Match status field names to order in GUI
keys = {'fiji', 'aphist', 'medlat', 'cell3d'};
for i = 1:numel(keys)
    key = keys{i};
    val = status.(key);
    label = handles.statusLabels(i);

    % General handler for enriched status information
    if val == "available"
        % Get additional context information if available
        extraInfoFields = setdiff(fieldnames(status), keys);
        matchedExtras = startsWith(extraInfoFields, key);
        infoToShow = '';

        for ef = extraInfoFields(matchedExtras)'
            valExtra = status.(ef{1});
            if iscell(valExtra)
                infoToShow = strjoin(valExtra, ' | ');
            elseif isstring(valExtra) || ischar(valExtra)
                infoToShow = valExtra;
            end
        end

        % Set label text and styling
        if ~isempty(infoToShow)
            label.Text = ['Done (', infoToShow, ')'];
        else
            label.Text = 'Done';
        end
        label.BackgroundColor = handles.colors.statusSuccess;
        label.FontColor = handles.colors.statusTextLight;

    elseif val == "in_progress"
        label.Text = 'In Process';
        label.BackgroundColor = handles.colors.statusWarning;
        label.FontColor = handles.colors.statusTextDark;

    elseif val == "not_started"
        label.Text = 'Not Started';
        label.BackgroundColor = handles.colors.statusNotDone;
        label.FontColor = handles.colors.statusTextDark;

    else % "not_available"
        label.Text = 'Not Available';
        label.BackgroundColor = handles.colors.statusError;
        label.FontColor = handles.colors.statusTextLight;
    end
end

updatePlotControlsAvailability(handles, status);

% Update color dropdown if CCF data exists
if strcmp(status.cell3d, "available") && isfield(handles, 'ccf_summary')
    handles = updateColorDropdown(handles);
    guidata(handles.fig, handles); % Save the updated handles
end
end

function status = checkProcessingSteps(baseDir)
status = struct();

% --- 0. Check for base TIF files ---
tifFiles = dir(fullfile(baseDir, '*.tif'));
status.tifs = "not_available";
if ~isempty(tifFiles)
    status.tifs = "available";
end

% --- 1. FIJI Coordinates ---
csvDir = fullfile(baseDir, 'CSV');
status.fiji = "not_available"; % default

if isfolder(csvDir)
    processedChannels = {};
    for c = 1:4
        pattern = sprintf('C%d_*.csv', c);
        if ~isempty(dir(fullfile(csvDir, pattern)))
            processedChannels{end+1} = sprintf('C%d', c);
        end
    end

    if ~isempty(processedChannels)
        status.fiji = "available";
        status.fiji_channels = processedChannels;
    else
        status.fiji = "not_started"; % CSV folder exists but no files
    end
end

% --- 2. AP Histology ---
outDir = fullfile(baseDir, 'OUT');
status.aphist = "not_available"; % default

% Check if AP histology is installed (basic check)
if ~exist('AP_histology', 'file')
    status.aphist = "not_available";
elseif isfolder(outDir)
    histologyFiles = dir(fullfile(outDir, 'atlas2histology_*tform.mat'));
    intermediateTifs = dir(fullfile(outDir, 'slice_*.tif'));

    if ~isempty(histologyFiles)
        status.aphist = "available";
        atlasTypes = {};

        for f = 1:length(histologyFiles)
            tokens = regexp(histologyFiles(f).name, 'atlas2histology_([^_]+)?tform\.mat', 'tokens');
            if ~isempty(tokens)
                match = tokens{1}{1};
                if isempty(match)
                    atlasTypes{end+1} = 'adult';
                else
                    atlasTypes{end+1} = match;
                end
            end
        end

        if ~isempty(atlasTypes)
            status.aphist_atlas = strjoin(unique(atlasTypes), ' | ');
        end

    elseif ~isempty(intermediateTifs)
        status.aphist = "in_progress";
    elseif status.tifs == "available"
        status.aphist = "not_started"; % TIFs exist but no processing started
    end
elseif status.tifs == "available"
    status.aphist = "not_started"; % TIFs exist but OUT folder doesn't
end

% --- 3. Med/Lat Classification ---
coordDir = fullfile(baseDir, 'CSV', 'COORD');
status.medlat = "not_available"; % default

if isfolder(coordDir)
    classMat = fullfile(baseDir, 'OUT', 'CLASS', 'CLASS_MedLat_All.mat');
    if isfile(classMat)
        loaded = load(classMat);
        if isstruct(loaded.MedLatClassification)
            status.medlat = "available";
            status.medlat_channels = fieldnames(loaded.MedLatClassification);
        else
            status.medlat = "not_started"; % File exists but invalid
        end
    else
        status.medlat = "not_started"; % COORD exists but no classification
    end
end

% --- 4. Cell3D Coordinates ---
[~, name] = fileparts(baseDir);
ccfDir = fullfile(baseDir, 'OUT', 'CCF');
status.cell3d = "not_available"; % default

% Check if AP histology is complete first
if strcmp(status.aphist, "available")
    if isfolder(ccfDir)
        coordFiles = dir(fullfile(ccfDir, [name, '_CCF_coords_*.mat']));
        if ~isempty(coordFiles)
            status.cell3d = "available";
            % Extract atlas type
            tokens = regexp(coordFiles(1).name, '_CCF_coords_(.*)\.mat', 'tokens');
            if ~isempty(tokens)
                status.cell3d_atlas = tokens{1}{1};
            end
        else
            status.cell3d = "not_started"; % CCF folder exists but no files
        end
    else
        status.cell3d = "not_started"; % AP hist done but no CCF folder
    end
end
end

function handles = validateAtlasSelection(handles)
% Check if a valid atlas is selected (not the placeholder)
selectedAtlas = handles.atlasTypeDropdown.Value;
handles.atlasValid = ~strcmp(selectedAtlas, '-- SELECT ATLAS --');

% Update button states
status = checkProcessingSteps(handles.baseDir);
updatePlotControlsAvailability(handles, status);

% Update status message
if handles.atlasValid
    handles.msgLabel.Text = ['Selected atlas: ' selectedAtlas];
    handles.msgLabel.FontColor = handles.colors.charcoal;
else
    handles.msgLabel.Text = 'Please select a valid atlas type before proceeding.';
    handles.msgLabel.FontColor = handles.colors.warningColor;
end
end


function handles = LoadCCFSummary(handles)
% Store current selection if it exists
if isfield(handles, 'colorDropdown') && isvalid(handles.colorDropdown)
    currentSelection = handles.colorDropdown.Value;
else
    currentSelection = 'Animal';
end

% Look for CCF summary in OUT/CCF
ccfDir = fullfile(handles.baseDir, 'OUT', 'CCF');
if ~isfolder(ccfDir), return; end

[~, name] = fileparts(handles.baseDir);
ccfFiles = dir(fullfile(ccfDir, [name, '_CCF_coords_*.mat']));
if isempty(ccfFiles), return; end

try
    loaded = load(fullfile(ccfDir, ccfFiles(1).name));
    if isfield(loaded, 'ccf_summary')
        handles.ccf_summary = loaded.ccf_summary;
    end
    if isfield(loaded, 'atlasType')
        handles.atlasType = loaded.atlasType;
    end

    % Update dropdown and enable related controls
    handles = updateColorDropdown(handles);

    updatePlotControlsAvailability(handles, checkProcessingSteps(handles.baseDir));


catch ME
    warning(["Failed to load CCF data: ", ME.message]);
end

% Restore selection after loading
if isfield(handles, 'colorDropdown') && isvalid(handles.colorDropdown)
    if any(strcmp(handles.colorDropdown.Items, currentSelection))
        handles.colorDropdown.Value = currentSelection;
    else
        handles.colorDropdown.Value = 'Animal'; % Fallback
    end
end

guidata(handles.fig, handles); % Save the state
end




function updatePlotControlsAvailability(handles, status)
% Enable plot-related controls if CCF coords exist
hasCCF = strcmp(status.cell3d, "available");

% List of controls that depend on CCF data
ccfControls = {handles.colorDropdown, handles.btnUpdatePlot, ...
    handles.btnSavePreview, handles.btnCustomPalette, ...
    handles.btnSaveAdditional, handles.flipDropdown};

for i = 1:numel(ccfControls)
    if isvalid(ccfControls{i})
        ccfControls{i}.Enable = bool2onoff(hasCCF);
    end
end


% Med/Lat button depends on CSV files
if isfield(handles, 'btnMedLat') && isvalid(handles.btnMedLat)
    handles.btnMedLat.Enable = bool2onoff(strcmp(status.fiji, "available"));
end

% AP_histology requires TIFs AND valid atlas selection
if isfield(handles, 'btnAPHistology') && isvalid(handles.btnAPHistology)
    handles.btnAPHistology.Enable = bool2onoff(...
        strcmp(status.tifs, "available") && handles.atlasValid);
end

% Run button requires AP_histology completion AND valid atlas
if isfield(handles, 'btnRun') && isvalid(handles.btnRun)
    handles.btnRun.Enable = bool2onoff(...
        strcmp(status.aphist, "available") && handles.atlasValid);
end
end

function val = bool2onoff(flag)
val = 'off';
if flag
    val = 'on';
end
end


%% Processing steps

% ------ AP Histology launch
%does not update status about process while open
function handles = launchAPHistology(handles)
% Check if atlas is valid
if ~handles.atlasValid
    handles.msgLabel.Text = 'Please select a valid atlas type before running AP_histology.';
    handles.msgLabel.FontColor = handles.colors.errorRed;
    return;
end
handles.msgLabel.Text = sprintf([ ...
    'Loading AP_histology GUI for atlas type "%s"...\n', ...
    'Run through all steps including manual alignment of histology to atlas. \n Reload this GUI after running it.'], ...
    handles.atlasTypeDropdown.Value);
handles.msgLabel.FontColor = handles.colors.charcoal;
drawnow;  % update label before running

AP_histology(handles.atlasTypeDropdown.Value);
guidata(handles.fig, handles);
end

% ------- med/lat classification

function handles = runMedLat(handles, channels)
folderPath = handles.baseDir;

handles.msgLabel.Text = ['Med/Lat classification running... (', strjoin(channels, ' | '), ')'];
handles.msgLabel.FontColor = handles.colors.warningColor;


csvFolderPath = fullfile(folderPath, 'CSV');
coordsFolderPath = fullfile(csvFolderPath, 'COORD');
outFolderPath = fullfile(folderPath, 'OUT');
figFolderPath = fullfile(outFolderPath, 'FIG');
classfigFolderPath = fullfile(figFolderPath, 'CLASS');
classFolderPath = fullfile(outFolderPath, 'CLASS');

% Create output directories if they do not exist
folders = {outFolderPath, figFolderPath, classfigFolderPath, classFolderPath};
for i = 1:numel(folders)
    if ~exist(folders{i}, 'dir')
        mkdir(folders{i});
    end
end

tifFiles = dir(fullfile(folderPath, '*.tif'));

% start structure

% Load previous results if they exist
classFilePath = fullfile(classFolderPath, 'CLASS_MedLat_All.mat');
if isfile(classFilePath)
    loaded = load(classFilePath);
    MedLatClassification = loaded.MedLatClassification;
else
    MedLatClassification = struct();
end

for i = 1:length(tifFiles)
    baseName = tifFiles(i).name;
    [~, name] = fileparts(baseName);
    info = imfinfo(fullfile(folderPath, baseName));
    imgWidth = info.Width; imgHeight = info.Height;
    coordsCsv = fullfile(coordsFolderPath, [name, '.csv']);

    for ch = 1:length(channels)
        csvFiles = dir(fullfile(csvFolderPath, '*.csv'));
        sep = regexp(csvFiles(1).name, '[-_]', 'match', 'once');
        csvPath = fullfile(csvFolderPath, [channels{ch}, sep, name, '.csv']);

        if isfile(csvPath) && isfile(coordsCsv)
            coords = readtable(coordsCsv);
            leftX = coords.X(1); midX = coords.X(2); rightX = coords.X(3);
            cells = readtable(csvPath);

            % Annotate with coords and metadata
            cells.leftX = repmat(leftX, height(cells), 1);
            cells.midX = repmat(midX, height(cells), 1);
            cells.rightX = repmat(rightX, height(cells), 1);
            cells.imgWidth = repmat(imgWidth, height(cells), 1);
            cells.imgHeight = repmat(imgHeight, height(cells), 1);
            cells.channel = repmat(channels(ch), height(cells), 1);

            % Classification
            secW_L = (midX - leftX)/5;
            secW_R = (rightX - midX)/5;
            section = zeros(height(cells), 1);
            hemi = strings(height(cells), 1);
            classifier = strings(height(cells), 1);

            for cc = 1:height(cells)
                xCoord = cells.X(cc);

                if xCoord < midX  % Left hemisphere
                    section(cc) = ceil((xCoord - leftX) / secW_L);
                    hemi(cc) = "L";
                else  % Right hemisphere
                    section(cc) = ceil((rightX - xCoord) / secW_R);
                    hemi(cc) = "R";
                end

                switch section(cc)
                    case {1, 2}
                        classifier(cc) = "Lateral";
                    case {3, 4}
                        classifier(cc) = "Medial";
                    case 5
                        classifier(cc) = "Cingulate";
                    otherwise
                        classifier(cc) = "Undefined";
                end
            end

            cells.section = section;
            cells.hemisphere = hemi;
            cells.classifier = classifier;

            % Percentage to midline
            percToMid = zeros(height(cells), 1);
            for pp = 1:height(cells)
                if cells.X(pp) < midX
                    percToMid(pp) = ((midX - cells.X(pp)) / (midX - leftX)) * 100;
                else
                    percToMid(pp) = ((cells.X(pp) - midX) / (rightX - midX)) * 100;
                end
            end
            cells.PercToMidline = percToMid;

            % Plot
            [~, ~, classIdx] = unique(classifier);
            fig = figure('Visible', 'off');
            scatter(cells.X, cells.Y, 10, classIdx, 'filled');
            axis([0 imgWidth 0 imgHeight]); axis equal; set(gca, 'YDir','reverse');
            xline(midX, 'k-', 'Midline');
            for b = 1:4
                xline(leftX + b * secW_L, '--');
                xline(midX + b * secW_R, '--');
            end
            title('Cell Distribution with Classification'); xlabel('X'); ylabel('Y');
            colormap(jet(max(classIdx)));
            colorbar('Ticks', 1:length(unique(classifier)), 'TickLabels', unique(classifier));
            %saveas(fig, fullfile(classfigFolderPath, ['CLASS_' channels{ch} '_' name '.fig']));
            exportgraphics(fig, fullfile(classfigFolderPath, ['CLASS_' channels{ch} '_' name '.png']), 'Resolution', 300);
            close(fig);

            entry = struct( ...
                'FileName', name, ...
                'Channel', channels{ch}, ...
                'X', cells.X, ...
                'Y', cells.Y, ...
                'Classifier', classifier, ...
                'Section', section, ...
                'Hemisphere', hemi, ...
                'PercToMidline', percToMid ...
                );

            channelKey = channels{ch};
            if isfield(MedLatClassification, channelKey)
                MedLatClassification.(channelKey)(end+1) = entry;
            else
                MedLatClassification.(channelKey) = entry;
            end

            writetable(cells, fullfile(classFolderPath, ['CLASS_' channels{ch} '_' name '.csv']));
        else
            handles.msgLabel.Text = sprintf('Missing CSV: channel %s in file %s', channels{ch}, name);
            handles.msgLabel.FontColor = handles.colors.errorRed;
            %warning('Missing CSV for channel %s in file %s', channels{ch}, name);
        end
    end
end

save(classFilePath, 'MedLatClassification');

handles.msgLabel.Text = 'Med/Lat classification saved.';
handles.msgLabel.FontColor = handles.colors.charcoal;
handles = updateStatusPanels(handles);
end

%----- CCF transformation

function runCell3DTransformation(handles, channels)
folderPath = handles.baseDir;
atlasType = handles.atlasTypeDropdown.Value;

handles.msgLabel.Text = sprintf('Transforming coordinates into CCF... (Atlas: %s)', atlasType);
handles.msgLabel.FontColor = handles.colors.warningColor;
drawnow;

% --- Load all required data upfront ---
slice_path = fullfile(folderPath, 'OUT');
atlas_files = dir(fullfile(slice_path, sprintf('histology*%s*ccf.mat', atlasType)));
if isempty(atlas_files)
    atlas_files = dir(fullfile(slice_path, 'histology_ccf.mat')); % fallback to adult
    atlasType = 'adult';
end
load(fullfile(slice_path, atlas_files(1).name), 'histology_ccf');

% --- Load transform ---
if strcmp(atlasType, 'adult')
    tformFile = fullfile(slice_path, 'atlas2histology_tform.mat');
else
    tformFile = fullfile(slice_path, sprintf('atlas2histology_%stform.mat', atlasType));
end
load(tformFile, 'atlas2histology_tform');

% --- Load CSV cell points ---
csvPath = fullfile(folderPath, 'CSV');
all_files = dir(fullfile(csvPath, '*.csv'));
files = all_files(arrayfun(@(f) any(startsWith(f.name, channels)), all_files));

% Load MedLat classification struct
classPath = fullfile(folderPath, 'OUT', 'CLASS');
matPath = fullfile(classPath, 'CLASS_MedLat_All.mat');
if isfile(matPath)
    loaded = load(matPath);
    MedLatStruct = loaded.MedLatClassification;
    medlat = 1;
else
    medlat = 0;
    handles.msgLabel.Text = sprintf('MedLat classification .mat file not found. \n Proceeding transformation without.');
    handles.msgLabel.FontColor = handles.colors.warningColor;
    drawnow;
end

if (medlat == 1), histology_classifier = cell(numel(files), 1); end

% Process each CSV file for cell points and classifiers
for i = 1:numel(files)
    fileName = files(i).name;
    % Split the filename at the first underscore to extract the channel and the rest of the filename
    splitName = strsplit(fileName, '_', 'CollapseDelimiters', false);
    channel = splitName{1};
    filewochannel = erase(strjoin(splitName(2:end), '_'),'.csv');  % Rejoin the remaining parts if there are more underscores

    % get cell coordinates
    dataTable = readtable(fullfile(files(i).folder, fileName));
    dataTable = dataTable(~(dataTable.X == 0 & dataTable.Y == 0), :);

    % Skip files that only contain a placeholder cell at (1,1)
    if height(dataTable) == 1 && all([dataTable.X, dataTable.Y] == [1, 1])
        %         disp(['Skipping file with only placeholder cell at (1,1): ', fileName]);
        histology_points{i} = [];
        if medlat, histology_classifier{i} = []; end
        continue;
    end


    histology_points{i} = [dataTable.X, dataTable.Y];

    if (medlat == 1)
        if isfield(MedLatStruct, channel)
            entries = MedLatStruct.(channel);
            matchIdx = find(strcmp({entries.FileName}, filewochannel), 1);  % Match the filename
            if ~isempty(matchIdx)
                classifierData = entries(matchIdx);
                % Check if the lengths match
                if height(dataTable) == numel(classifierData.Classifier)
                    histology_classifier{i} = table(classifierData.Classifier, classifierData.PercToMidline, 'VariableNames', {'classifier', 'PercToMidline'});
                else
                    disp(['Mismatch in number of points for file: ', filewochannel]);  % Debugging output
                    histology_classifier{i} = [];  % or handle the mismatch differently
                end
            else
                histology_classifier{i} = [];
            end
        end
    end
end

% --- Transform to CCF ---
num_channels = length(channels);
num_entries = length(atlas2histology_tform);
ccf_points = cell(num_entries, num_channels);
valid_classifier = cell(size(histology_classifier));

for idx = 1:length(histology_points)
    if isempty(histology_points{idx}), continue; end
    ch = floor((idx - 1)/num_entries) + 1;
    slice = mod((idx - 1), num_entries) + 1;
    tform = invert(affine2d(atlas2histology_tform{slice}));
    [x, y] = transformPointsForward(tform, histology_points{idx}(:,1), histology_points{idx}(:,2));
    x = round(x); y = round(y);

    sz = size(histology_ccf(slice).av_slices);
    valid = x >= 1 & x <= sz(2) & y >= 1 & y <= sz(1);
    idx_linear = sub2ind(sz, y(valid), x(valid));
    ccf_points{slice, ch} = [ ...
        histology_ccf(slice).plane_ap(idx_linear), ...
        histology_ccf(slice).plane_dv(idx_linear), ...
        histology_ccf(slice).plane_ml(idx_linear)];

    if medlat && ~isempty(histology_classifier{idx})
        valid_classifier{idx} = histology_classifier{idx}(valid, :);
    end
end

% --- Concatenate all CCF data ---
ccf_points_cat = [];
concatenated_channel = [];
concatenated_validity = [];
for ch = 1:num_channels
    slice_data = ccf_points(:, ch);
    for slice = 1:num_entries
        if ~isempty(slice_data{slice})
            combined = round(slice_data{slice});
            channel_col = repmat(channels(ch), size(combined, 1), 1);
            valid_col = true(size(combined, 1), 1);

            % Concatenate valid points
            ccf_points_cat = [ccf_points_cat; combined];
            concatenated_channel = [concatenated_channel; channel_col];
            concatenated_validity = [concatenated_validity; valid_col];
        end
    end
end

% Include invalid points as 'outside'
for i = 1:length(histology_points)
    if isempty(histology_points{i}), continue; end
    ch = floor((i - 1)/num_entries) + 1;
    slice = mod((i - 1), num_entries) + 1;

    invalid = ~(x >= 1 & x <= sz(2) & y >= 1 & y <= sz(1));
    if any(invalid)
        invalid_points = [x(invalid), y(invalid), repmat(slice, sum(invalid), 1)];
        channel_col = repmat(channels(ch), size(invalid_points, 1), 1);
        valid_col = false(size(invalid_points, 1), 1);

        ccf_points_cat = [ccf_points_cat; invalid_points];
        concatenated_channel = [concatenated_channel; channel_col];
        concatenated_validity = [concatenated_validity; valid_col];
    end
end

if medlat
    valid_classifier_cat = vertcat(valid_classifier{:});
end

% --- Hemisphere and summary ---
[~, ~, brain_data] = getAtlasFilesForType(atlasType);

yCenter = mean([min(brain_data.brain.v(:,2)) max(brain_data.brain.v(:,2))]);
hemi = repmat("L", size(ccf_points_cat, 1), 1);
hemi(ccf_points_cat(:,3) > yCenter) = "R";

z_min = min(brain_data.brain.v(:, 2));
z_max = max(brain_data.brain.v(:, 2));

z_perc = ((ccf_points_cat(:,1) - z_min) / (z_max - z_min)) * 100;
% Add hemisphere and percentage to summary table
ccf_summary = table(ccf_points_cat(:,1), ccf_points_cat(:,2), ccf_points_cat(:,3), ...
    concatenated_channel, hemi, z_perc, ...
    'VariableNames', {'Z', 'X', 'Y', 'Channel', 'Hemisphere', 'Zperc'});

if medlat && ~isempty(valid_classifier_cat)
    ccf_summary = [ccf_summary, valid_classifier_cat];
end

% --- Load atlas files and structure tree ---
[tv, av, st] = load_atlas_files(atlasType);

% Calculate CCF points indices based on the atlas volume
ccf_points_idx = sub2ind(size(av), ccf_points_cat(:, 1), ccf_points_cat(:, 2), ccf_points_cat(:, 3));
ccf_points_av = av(ccf_points_idx);

% Initialize Brainstruct array to 'outside' as default
ccf_summary.Brainstruct = repmat({'outside'}, size(ccf_points_cat, 1), 1);

if ~strcmpi(atlasType, 'adult')
    % Handling developmental atlases with specific age adjustments
    age_str = char(atlasType);
    if startsWith(age_str, 'P') && length(age_str) == 2
        age_str = ['P0', age_str(2)]; % Normalize the age string format
    end

    % Filter structures available at this age
    if ismember(age_str, st.Properties.VariableNames)
        available_structures = st{:, age_str} == 1;
        st = st(available_structures, :);
    else
        error('Age column "%s" not found in structure tree!', age_str);
    end

    % Map indices to structure names for developmental atlas
    [found, loc] = ismember(ccf_points_av, st.index);
    ccf_points_areas = ccf_summary.Brainstruct;
    ccf_points_areas(found) = st.safe_name(loc(found));
    ccf_summary.Brainstruct = ccf_points_areas;

else
    % Specific handling for 'adult' atlas
    [found, loc] = ismember(ccf_points_av, st.index);
    valid_structure_names = st.safe_name(loc(found));

    % Only assign names to found indices
    ccf_points_areas = ccf_summary.Brainstruct;
    ccf_points_areas(found) = valid_structure_names;

    % Detect and handle 'Basic cell groups and regions' and invalid indices
    basic_cell_groups = strcmp(st.safe_name(loc(found)), 'Basic cell groups and regions');
    ccf_points_areas(found & basic_cell_groups) = {'outside'};

    % Update the Brainstruct for all points
    ccf_summary.Brainstruct = ccf_points_areas;
end

% --- Save output ---
savePath = fullfile(folderPath, 'OUT', 'CCF');
if ~exist(savePath, 'dir'), mkdir(savePath); end
[~, name] = fileparts(folderPath);
mat_save_name = [name, '_CCF_coords_', atlasType, '.mat'];
csv_save_name = [name, '_CCF_coords_', atlasType, '.csv'];
count_csv_name = [name, '_CCF_counts_', atlasType, '.csv'];
if isempty(handles.groupEditField.Value)
    Group = '';  % Default to empty string if no input is provided
else
    Group = handles.groupEditField.Value;
end


% Count cells per brain structure and save summary table as CSV
if ~iscell(ccf_summary.Brainstruct)
    ccf_summary.Brainstruct = cellstr(ccf_summary.Brainstruct);
end
[uniqueEntries, ~, idx] = unique(ccf_summary.Brainstruct);
counts = accumarray(idx, 1);
summaryTable = table(uniqueEntries, counts, 'VariableNames', {'Structure', 'Count'});
writetable(summaryTable, fullfile(savePath, count_csv_name));

if strcmp(atlasType, 'adult') || isempty(atlasType)

    % --- Generate summary without layers ---
    % Normalize structure names by removing anything after 'area'
    hasArea = contains(ccf_summary.Brainstruct, 'area', 'IgnoreCase', true);
    baseStructNames = ccf_summary.Brainstruct;  % start with full names
    baseStructNames(hasArea) = regexprep(ccf_summary.Brainstruct(hasArea), '(?<=area).*', '', 'ignorecase');
    baseStructNames = strtrim(baseStructNames);  % clean up whitespace
    ccf_summary.short_brainstruct = baseStructNames;

    [uniqueBase, ~, baseIdx] = unique(baseStructNames);
    baseCounts = accumarray(baseIdx, 1);
    baseSummaryTable = table(uniqueBase, baseCounts, 'VariableNames', {'Structure_wo_Layer', 'Count'});

    % Save additional summary CSV
    base_count_csv_name = [name, '_CCF_counts_', atlasType, '_noLayer.csv'];
    writetable(baseSummaryTable, fullfile(savePath, base_count_csv_name));
end

% Save .mat file after adding short names
save(fullfile(savePath, mat_save_name), ...
    'ccf_summary', 'ccf_points_cat', 'atlasType', 'Group');

% Save coordinate summary CSV
writetable(ccf_summary, fullfile(savePath, csv_save_name));

handles.msgLabel.Text = sprintf('Cell3D coordinates transformed. \nSaved as %s',mat_save_name);
handles.msgLabel.FontColor = handles.colors.successColor;

%plot once ccf_summary exists
handles = LoadCCFSummary(handles);

handles = updateColorDropdown(handles);
handles = updateStatusPanels(handles);
updatePlot(handles);

% Final guidata update to capture any changes from the above functions
guidata(handles.fig, handles);
end

function handles = saveCCFToAdditionalFolder(handles)
% Check if CCF file exists in the expected location
ccfDir = fullfile(handles.baseDir, 'OUT', 'CCF');
ccfFiles = dir(fullfile(ccfDir, '*CCF_coords_*.mat'));

if isempty(ccfFiles)
    handles.msgLabel.Text = 'Error: No CCF coordinate file found in OUT/CCF folder';
    handles.msgLabel.FontColor = handles.colors.errorRed;
    return;
end

% Get the most recent CCF file if multiple exist
[~, idx] = max([ccfFiles.datenum]);
sourceFile = fullfile(ccfDir, ccfFiles(idx).name);

% Ask user where to save the file
targetDir = uigetdir(handles.baseDir, 'Select Folder to Save CCF File');
if isequal(targetDir, 0)
    return; % User canceled
end

% Copy the file
try
    destinationFile = fullfile(targetDir, ccfFiles(idx).name);
    copyfile(sourceFile, destinationFile);

    handles.msgLabel.Text = sprintf('CCF coordinate file successfully copied to:\n%s', ...
        destinationFile);
    handles.msgLabel.FontColor = handles.colors.successColor;
catch ME
    handles.msgLabel.Text = sprintf('Error: File could not be copied\n%s', ME.message);
    handles.msgLabel.FontColor = handles.colors.errorRed;
end

guidata(handles.fig, handles);
end



%% plotting

function handles = updatePlot(handles)
% Debug: Check what's actually in handles
if ~isfield(handles, 'ccf_summary') || isempty(handles.ccf_summary)
    handles = LoadCCFSummary(handles); % Attempt to reload
    guidata(handles.fig, handles); % Save updates

    % Check if loading succeeded
    if ~isfield(handles, 'ccf_summary') || isempty(handles.ccf_summary)
        handles.msgLabel.Text = 'No coordinate data available for plotting.';
        handles.msgLabel.FontColor = handles.colors.errorRed;
        return;
    end
end

selectedLabel = handles.colorDropdown.Value;
if strcmp(selectedLabel, 'Animal')
    colorField = '';
elseif isfield(handles, 'colorDropdownMap') && isKey(handles.colorDropdownMap, selectedLabel)
    colorField = handles.colorDropdownMap(selectedLabel);
else
    colorField = '';
end

plotCCFcoordinatesInGUI(handles);
end


function plotCCFcoordinatesInGUI(handles)
ax = handles.ax;
ccf_summary = handles.ccf_summary;
colorcellsby = handles.colorDropdown.Value;
atlasType = handles.atlasType;
[az, el] = view(ax);


% Get flip direction safely
if isfield(handles, 'flipDropdown') && isvalid(handles.flipDropdown)
    flipDirection = handles.flipDropdown.Value;
elseif isfield(handles, 'flipDirection')
    flipDirection = handles.flipDirection;
else
    flipDirection = 'none';
end

% --- Load brain mesh (outline) ---
[~, ~, brain_data] = getAtlasFilesForType(atlasType);
v = brain_data.brain.v;
f = brain_data.brain.f;

% Clear previous contents
cla(ax);
legend(ax, 'off');
colorbar(ax, 'off');

% Plot brain outline
patch(ax, ...
    'Vertices', v, ...
    'Faces', f, ...
    'FaceColor', [0.7, 0.7, 0.7], ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 0.1, ...
    'HandleVisibility', 'off', ...   % <--- prevent legend entry
    'DisplayName', '');              % <--- just in case

hold(ax, 'on');

% Hemisphere flipping setup
flipToRight = strcmp(flipDirection, 'Right');
flipToLeft = strcmp(flipDirection, 'Left');
midline = mean([min(brain_data.brain.v(:,2)) max(brain_data.brain.v(:,2))]);

% Determine which column to use
switch lower(colorcellsby)
    case 'channel', categoryCol = 'Channel';
    case 'med/lat classifier', categoryCol = 'classifier';
    case 'hemisphere', categoryCol = 'Hemisphere';
    case 'distribution on z (a/p)', categoryCol = 'Zperc';
    case 'distance to midline', categoryCol = 'PercToMidline';
    case 'brain structure', categoryCol = 'Brainstruct';
    case 'brain structure (parent)', categoryCol = 'short_brainstruct';
    otherwise, categoryCol = '';
end

if strcmp(colorcellsby, 'Animal')
    ccf_summary.Animal = repmat({'Animal'}, height(ccf_summary), 1);
    categoryCol = 'Animal';
end


% --- Plot points ---
if ~isempty(categoryCol) && ismember(categoryCol, ccf_summary.Properties.VariableNames)

    data = ccf_summary;

    % Apply hemisphere flipping if needed
    if flipToRight
        flip_idx = data.Y < midline;
        data.Y(flip_idx) = 2 * midline - data.Y(flip_idx);
    elseif flipToLeft
        flip_idx = data.Y > midline;
        data.Y(flip_idx) = 2 * midline - data.Y(flip_idx);
    end

    % Gradient coloring (numeric column)
    if isnumeric(data.(categoryCol))
        scatter3(ax, data.Z, data.Y, data.X, ...
            handles.cellsize, data.(categoryCol), 'filled', ...
            'MarkerFaceAlpha', handles.alpha);
        colormap(ax, 'jet');
        colorbar(ax);
    else
        palette = getCurrentPalette(handles.baseDir);
        categories = unique(data.(categoryCol));

        % Limit palette length or expand if needed
        if size(palette,1) < numel(categories)
            palette = repmat(palette, ceil(numel(categories)/size(palette,1)), 1);
        end

        % Create mapping
        colorMap = containers.Map(categories, num2cell(palette(1:numel(categories),:), 2));

        for i = 1:length(categories)
            label = categories{i};
            rows = strcmp(data.(categoryCol), label);
            color = colorMap(label);

            scatter3(ax, data.Z(rows), data.Y(rows), data.X(rows), ...
                handles.cellsize, 'filled', ...
                'MarkerFaceColor', color, ...
                'MarkerFaceAlpha', handles.alpha, ...
                'DisplayName', label);
        end
    end
else
    scatter3(ax, ccf_summary.Z, ccf_summary.Y, ccf_summary.X, ...
        handles.cellsize, 'k', 'filled', 'MarkerFaceAlpha', handles.alpha);
end

if ~isnumeric(data.(categoryCol))

    lgd = legend(ax, 'Location', 'southoutside');
    lgd.Box = 'off';
    lgd.FontSize = 6;
    % Adjust number of columns based on number of entries
    numItems = numel(categories);
    if numItems >= 12
        lgd.NumColumns = ceil(numItems / 10); % compact, more columns
        lgd.FontSize = 5;  % reduce font for space
        lgd.ItemTokenSize = [10, 8];  % shrink marker
    elseif numItems >= 6
        lgd.NumColumns = 4;  % show 2 rows
        lgd.ItemTokenSize = [10, 8];  % shrink marker
    else
        lgd.NumColumns = numItems;
    end
end

% Final styling
axis(ax, 'equal');
axis(ax, 'off');
set(ax, 'ZDir', 'reverse');
hold(ax, 'off');
end

function saveCurrentPlot(handles)
% Prompt user to choose where to save
[file, path] = uiputfile({'*.png'; '*.fig'}, 'Save Plot As', fullfile(handles.baseDir, 'CCF_plot.png'));
if isequal(file, 0)
    return;  % User canceled
end

% Get full file path and strip extension
[~, name, ~] = fileparts(file);
pngPath = fullfile(path, [name, '.png']);
figPath = fullfile(path, [name, '.fig']);

% Save .png with good resolution
exportgraphics(handles.ax, pngPath, 'Resolution', 300);

% Save .fig for future edits
f = figure();
copyobj(handles.ax, f);
savefig(f, figPath);
close(f);

% Optional feedback
handles.msgLabel.Text = sprintf('Plot saved as:\n%s\n%s', pngPath, figPath);
handles.msgLabel.FontColor = handles.colors.successColor;
end



%% helper functions that run in the background

function handles = updateColorDropdown(handles)
% Check if we have valid coordinate data
if ~isfield(handles, 'ccf_summary') || isempty(handles.ccf_summary) || ...
        ~istable(handles.ccf_summary)
    handles.colorDropdown.Items = {'Animal'};
    handles.colorDropdown.Value = 'Animal';
    handles.colorDropdown.Enable = 'off';
    return;
end

% Get available columns, excluding coordinate columns
excludedVars = {'X', 'Y', 'Z'};
availableColumns = setdiff(handles.ccf_summary.Properties.VariableNames, excludedVars);

% Create pretty labels and mapping
prettyLabels = cellfun(@(x) makeLabel(x), availableColumns, 'UniformOutput', false);
if ~isempty(prettyLabels)
    labelMap = containers.Map(prettyLabels, availableColumns);
    handles.colorDropdown.Items = ['Animal', prettyLabels];
    handles.colorDropdown.Value = 'Animal';
    handles.colorDropdownMap = labelMap;
    handles.colorDropdown.Enable = 'on';
else
    handles.colorDropdown.Items = {'Animal'};
    handles.colorDropdown.Value = 'Animal';
    handles.colorDropdown.Enable = 'off';
end

end


function label = makeLabel(varName)
% Create a prettier label for dropdowns
switch lower(varName)
    case 'zperc'
        label = 'Distribution on Z (a/p)';
    case 'perctomidline'
        label = 'Distance to Midline';
    case 'classifier'
        label = 'Med/Lat Classifier';
    case 'brainstruct'
        label = 'Brain Structure';
    case 'short_brainstruct'
        label = 'Brain Structure (parent)';
    otherwise
        % Capitalize first letter and keep varName in parentheses
        label = [upper(varName(1)), lower(varName(2:end))];
end
end


function channels = getSelectedChannels(handles)
channelNames = {'C1', 'C2', 'C3', 'C4'};
selectedIdx = arrayfun(@(cb) cb.Value, handles.channelCheckboxes);
channels = channelNames(selectedIdx);
end

function [atlas_files, atlas_base_dir, brain_data] = getAtlasFilesForType(atlasType)
% getAtlasFilesForType - Load atlas files, base dir, and brain hull (with midline) for a given atlasType

% Locate AP_histology path
ap_histology_path = which('AP_histology');
if isempty(ap_histology_path)
    error('AP_histology.m not found in MATLAB path.');
end
ap_histology_dir = fileparts(ap_histology_path);

% Load atlas templates
atlas_settings_path = fullfile(ap_histology_dir, 'atlas_paths.mat');
if ~exist(atlas_settings_path, 'file')
    error('atlas_paths.mat not found. Run save_atlas_paths.m first.');
end
load(atlas_settings_path, 'templates');

% Validate atlasType
if ~isfield(templates, atlasType)
    error('Atlas type "%s" not found. Available: %s', ...
        atlasType, strjoin(fieldnames(templates), ', '));
end
atlas_files = templates.(atlasType);

% Determine atlas base directory
if strcmp(atlasType, 'adult')
    atlas_base_dir = fullfile(ap_histology_dir, 'allenAtlas');
else
    atlas_base_dir = fullfile(ap_histology_dir, 'devAtlas');
end

% Load brain hull .mat (includes .v, .f, and .midline)
brain_path = fullfile(atlas_base_dir, atlas_files.brain);
if ~exist(brain_path, 'file')
    error('Brain hull file not found: %s', brain_path);
end
brain_data = load(brain_path);  % should include fields like brain.v, brain.f, brain.midline
end

function [tv, av, st] = load_atlas_files(atlasType)

% Default to 'adult' if atlasType is empty
if isempty(atlasType)
    atlasType = 'adult';
end

% Get the directory where AP_histology.m is located
ap_histology_path = which('AP_histology'); % Find the function file
if isempty(ap_histology_path)
    error('AP_histology.m not found in the MATLAB path. Ensure it is accessible.');
end
ap_histology_dir = fileparts(ap_histology_path);

% Define the path for the atlas settings file
atlas_settings_path = fullfile(ap_histology_dir, 'atlas_paths.mat');

% Check if the atlas paths file exists
if exist(atlas_settings_path, 'file')
    load(atlas_settings_path, 'templates');
else
    error('Atlas settings file not found! Run `save_atlas_paths.m` to generate it.');
end

% Validate the atlas type
if ~isfield(templates, atlasType)
    error('Atlas type "%s" not found. Available options: %s', atlasType, strjoin(fieldnames(templates), ', '));
end

% Get the paths for the selected atlas
atlas_files = templates.(atlasType);

% Determine the correct base directory for atlas files
if strcmp(atlasType, 'adult')
    atlas_base_dir = fullfile(ap_histology_dir, 'allenAtlas');
else
    atlas_base_dir = fullfile(ap_histology_dir, 'devAtlas');
end

% Build full paths for each atlas file
template_path = fullfile(atlas_base_dir, atlas_files.template);
annotation_path = fullfile(atlas_base_dir, atlas_files.annotation);
structure_tree_path = fullfile(atlas_base_dir, atlas_files.structure_tree);

% Debug: Print the full paths of the files being loaded
fprintf('Loading template from: %s\n', template_path);
fprintf('Loading annotation from: %s\n', annotation_path);
fprintf('Loading structure tree from: %s\n', structure_tree_path);

% Load atlas files
tv = readNPY(template_path);
av = readNPY(annotation_path);
st = loadStructureTree(structure_tree_path);
% Display confirmation message
fprintf('Atlas files for "%s" loaded successfully.\n', atlasType);
end

function palette = getCurrentPalette(baseDir)
% Check for custom palette file
paletteFile = fullfile(baseDir, 'OUT', 'customPalette.mat');

if exist(paletteFile, 'file')
    % Load custom palette
    load(paletteFile, 'palette');
else
    % Use default palette (linspecer or any other default)
    palette = linspecer(8); % Default to 8 colors
end
end

function openPaletteEditor(handles)
fig = uifigure('Name', 'Color Palette Editor', 'Position', [100 100 600 200]);
outDir = fullfile(handles.baseDir, 'OUT');
if ~exist(outDir, 'dir'), mkdir(outDir); end

% Load or initialize palette
paletteFile = fullfile(handles.baseDir, 'OUT', 'customPalette.mat');
if exist(paletteFile, 'file')
    load(paletteFile, 'palette');
else
    palette = linspecer(6); % Default to 6 colors
end

% Main grid layout
mainGrid = uigridlayout(fig, [2 1]);
mainGrid.RowHeight = {120, 40};
mainGrid.Padding = [20 20 20 20];

swatchGrid = uigridlayout(mainGrid, [1 size(palette,1)]);
swatchGrid.Layout.Row = 1;
swatchGrid.ColumnWidth = repmat({'1x'}, 1, size(palette,1));

colorButtons = gobjects(size(palette,1), 1);
for i = 1:size(palette,1)
    colorButtons(i) = uibutton(swatchGrid);
    colorButtons(i).BackgroundColor = palette(i,:);
    colorButtons(i).Text = '';
    colorButtons(i).ButtonPushedFcn = @(src,evt) changeColor(i);
end

controlGrid = uigridlayout(mainGrid, [1 4]);
controlGrid.Layout.Row = 2;

btnAdd = uibutton(controlGrid, 'Text', '＋ Add Color', 'ButtonPushedFcn', @addColor);
btnRemove = uibutton(controlGrid, 'Text', '－ Remove Color', 'ButtonPushedFcn', @removeColor);
btnReset = uibutton(controlGrid, 'Text', '↻ Reset to Default', 'ButtonPushedFcn', @resetDefault);
btnSave = uibutton(controlGrid, 'Text', '💾 Save for Usage', 'ButtonPushedFcn', @savePalette);

    function changeColor(idx)
        newColor = uisetcolor(palette(idx,:));
        if ~isequal(newColor, 0)
            palette(idx,:) = newColor;
            colorButtons(idx).BackgroundColor = newColor;
        end
    end

    function addColor(~,~)
        palette = [palette; rand(1,3)];
        updateSwatches();
    end

    function removeColor(~,~)
        if size(palette,1) > 1
            palette(end,:) = [];
            updateSwatches();
        end
    end

    function resetDefault(~,~)
        palette = linspecer(6);
        updateSwatches();
    end

    function savePalette(~,~)
        save(paletteFile, 'palette');
        uialert(fig, 'Palette saved successfully!', 'Success', 'Icon', 'success');
    end

    function updateSwatches()
        delete(swatchGrid.Children);
        swatchGrid = uigridlayout(mainGrid, [1 size(palette,1)]);
        swatchGrid.Layout.Row = 1;
        swatchGrid.ColumnWidth = repmat({'1x'}, 1, size(palette,1));
        colorButtons = gobjects(size(palette,1), 1);
        for i = 1:size(palette,1)
            colorButtons(i) = uibutton(swatchGrid);
            colorButtons(i).BackgroundColor = palette(i,:);
            colorButtons(i).Text = '';
            colorButtons(i).ButtonPushedFcn = @(src,evt) changeColor(i);
        end
    end
end


%% background checks
function allPresent = checkDependencies()
% checkDependencies - Verifies required toolboxes and functions are present
% If missing, shows message with instructions to install via Add-On Manager.

allPresent = true;
missing = {};

% Required Functions (custom or File Exchange)
requiredFunctions = {'linspecer', 'numSubplots', 'tight_subplot'};

% Required Toolboxes
requiredToolboxes = {'Curve Fitting Toolbox', 'Image Processing Toolbox'};

% Check functions
for i = 1:numel(requiredFunctions)
    if isempty(which(requiredFunctions{i}))
        warning('Missing required function: %s', requiredFunctions{i});
        missing{end+1} = sprintf('Function: %s', requiredFunctions{i});
    end
end

% Check toolboxes
v = ver;  % list of installed toolboxes
installedToolboxes = {v.Name};

for i = 1:numel(requiredToolboxes)
    if ~any(strcmp(requiredToolboxes{i}, installedToolboxes))
        warning('Missing required toolbox: %s', requiredToolboxes{i});
        missing{end+1} = sprintf('Toolbox: %s', requiredToolboxes{i});
    end
end

% Show error dialog if anything missing
if ~isempty(missing)
    allPresent = false;
    msg = sprintf(['The following required components are missing:\n\n' ...
                   '- %s\n\nYou can install them via the Add-On Manager.'], ...
                   strjoin(missing, '\n- '));
    errordlg(msg, 'Missing Dependencies');
end

end


function openHelpDialog()
% Create a uifigure for the help dialog
helpFig = uifigure('Name', 'CELL3D Step 1 - Help', 'Position', [100 100 700 660]);
helpFig.Resize = 'off';
helpFig.Color = [0.96 0.96 0.96]; % Match GUI's lightBg color

% Create a panel that will contain the text control
helpPanel = uipanel(helpFig, 'Position', [10 10 680 640], 'BorderType', 'none');
helpPanel.BackgroundColor = [1 1 1]; % White background
helpPanel.HighlightColor = [0.24 0.48 0.54]; % Cerulean border

% Define help text sections
header = '<html><body style="font-family:Arial; font-size:12px; color:#16262E; line-height:1.6;">';

section1 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Step Overview</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
    '<p>This GUI performs initial preprocessing of cell coordinates from TIFF files and transforms them into common coordinate framework (CCF) space.</p>'...
    '<p>Follow these steps in order to create the final outputs.</p>'...
    '<ul style="margin-top:10px; line-height:1.5;">'...
    '<li>✅ <b>FIJI Coordinates (done in Fiji):</b> After running FIJI pipeline, checks for CSVs from cell detection (e.g. C1_*.csv) in <code>CSV/</code></li>'...
    '<li>✅ <b>AP Histology (button):</b> Requires TIFFs and must be run before 3D coordinate transformation</li>'...
    '<li>✅ <b>Med/Lat Classification (button, optional):</b> Sahni Lab specific: Adds cingulate/medial/lateral info if COORD CSV files are present</li>'...
    '<li>✅ <b>Cell3D Transformation (button):</b> Converts cell locations into CCF coordinates using aligned slices</li>'...
    '</ul>'...
    '</div>'];

section2 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">User Input and Progress Bar</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
    '<ul>'...
    '<li><b>📁 Change Folder:</b> Use this to switch to a different TIFF/CSV folder</li>'...
    '<li><b>🎯 Channel Selection:</b> Select available channels for analysis </li>'...
    '<li><b>📌 Group Input:</b> Optional label for grouping animals (saved to .mat)</li>'...
    '<li><b>🧠 Atlas Type:</b> Select desired developmental or adult atlas before transformation</li>'...
    '<li><b>📊 Status Panel:</b> Shows status for each step (color-coded)</li>'...
    '<li><b>💬 Message Box:</b> Displays real-time updates, warnings, and errors as you interact with the GUI</li>'...
    '</ul>'...
    '</div>'];

section3 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Visualization</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
    '<ul>'...
    '<li><b>🧭 Preset Views:</b> Use Top / Side / Frontal buttons to change 3D perspective</li>'...
    '<li><b>🎨 Color By:</b> Dropdown allows coloring by Channel, Hemisphere, Z-distribution, etc.</li>'...
    '<li><b>🧠 Brain Structure:</b> Colors each point by the annotated brain structure in the selected atlas.</li>'...
    '<li><b>🧬 Brain Structure (Parent):</b> Strips away layer-specific details (e.g., layer 5 vs. layer 6) and assigns colors based on the parent region (e.g., MOp).</li>'...
    '<li><b>↔️ Flip to Hemisphere:</b> Mirroring option to overlay left/right hemisphere data for comparison</li>'...
    '<li><b>🔄 Update Plot:</b> Refreshes the 3D view using the latest parameters (e.g., flip, color).</li>'...
    '<li><b>📁 Define Palette:</b> Customize categorical color mappings</li>'...
    '</ul>'...
    '<p style="color:#CC3333;"><b>Note:</b> View angle is preserved when saving plots.</p>'...
    '</div>'];

section4 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Saving / Automatic Outputs</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px;">'...
    '<p><b>User-triggered (manual actions via buttons):</b></p>'...
    '<ul>'...
    '<li><b>[💾] Save Plot:</b> Exports current 3D view as PNG and FIG</li>'...
    '<li><b>[📂] Save to Additional Folder:</b> Lets you choose a folder to export the final CCF .mat and .csv file</li>'...
    '</ul>'...
    '<p><b>Automatically generated (upon classification / transformation):</b></p>'...
    '<ul>'...
    '<li><b>[📊] Med/Lat Classification Plots:</b> For each image and channel, a PNG is created showing cortical subdivisions (Lateral, Medial, Cingulate)</li>'...
    '<li><b>[🧠] Output Folder:</b> All results are stored in <code>OUT/CCF/</code> under the selected base folder</li>'...
    '<li><b>[📁] Output Files:</b> After transformation, the GUI creates a `.mat`, `.csv`, and summary `.csv` with cell counts per brain region. Layer-stripped counts (`*_noLayer.csv`) are included for simplified summaries</li>'...
    '</ul>'...
    '</div>'...
    '</body></html>'];

section5 = [...
    '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Advanced Notes</h2>'...
    '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px;">'...
    '<p>This GUI is designed to work seamlessly with the <code>AP_histology</code> pipeline and the <code>devAtlas</code> system. For best performance:</p>'...
    '<ul>'...
    '<li>Ensure consistent file naming for TIFF and CSV files</li>'...
    '<li>Use <code>save_atlas_paths.m</code> to configure custom developmental atlases</li>'...
    '</ul>'...
    '<li>Check that <code>atlas2histology_tform.mat</code> is generated before CCF transformation</li>'...
    '<p>Resources:</p>'...
    '<ul>'...
    '<li><a href="https://github.com/cortex-lab/AP_histology" target="_blank">📦 AP_histology GitHub Repository</a></li>'...
    '<li><a href="https://kimlab.io/dev-atlas/" target="_blank">🧭 Kim Lab DevAtlas Website</a></li>'...
    '</ul>'...
    '</div>'];

helpText = [header section1 section2 section3 section4 section5];

% Create a HTML-enabled text control
helpTextControl = uihtml(helpPanel, 'Position', [10 10 660 620]);
helpTextControl.HTMLSource = helpText;
end


%% future ideas

% maybe add a button that shows 2D tif with coordinates to interact and delete specific
% cells?