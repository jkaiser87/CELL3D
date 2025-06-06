% only after doing the 3D structure part in setup: add button to preview pane to add structures to display (pop up with
% checkboxes [and 1 NONE] and apply_

%add change folder

% does not load GUI when loaded in folder that does not have coord files,
% after adding change folder button back in, lets change to just show
% errormessage!!

% add button where flip hemisphere is to subset cells to a certain brain
% structure (pop up with check boxes [and 1 "ALL"] and a "apply" button)

function CELL3D_Step2_GUI_v2(baseDir)

if ~checkDependencies()
        return; % Exit if dependencies are missing
end

% Handle optional input
if nargin < 1 || isempty(baseDir)
    baseDir = pwd; % Default to current directory if no input provided
end

% Verify the folder exists
if ~isfolder(baseDir)
    error('Specified folder does not exist: %s', baseDir);
end

files = dir(fullfile(baseDir, '**', '*_CCF_coords*.mat'));

if isempty(files)
    uialert(uifigure, 'No coordinate files found.', 'Error');
    return;
end

% Predefined variables
btnSaveBatch = [];
btnUpdatePlot = [];

% Define color scheme (RGB 0-1)
handles.colors.lightBg = [0.96 0.96 0.96];    % #F5F5F5
handles.colors.thistle = [244 237 234]/255;    % #DBC2CF
handles.colors.coolGray = [0.62 0.64 0.70];   % #9FA2B2
handles.colors.cerulean = [0.24 0.48 0.54];   % #3C7A89
handles.colors.charcoal = [0.18 0.28 0.34];   % #2E4756
handles.colors.gunmetal = [0.09 0.15 0.18];   % #16262E
handles.colors.white = [1 1 1];               % #FFFFFF
handles.colors.errorRed = [0.8 0.2 0.2];      % For error messages

data = {};
groupColorMapping = containers.Map;
defaultColors = {'red', 'green', 'blue', 'cyan', 'magenta', 'yellow', 'black','other...'};
channelColorMapping = containers.Map({'C1','C2','C3','C4'}, {'red','green','blue','cyan'});

% Step 1: Build data from available coordinate files
data = {};
identityKeys = {};  % for checking metadata match later

for i = 1:length(files)
    file = files(i);
    try
        S = load(fullfile(file.folder, file.name));
        animalName = extractBefore(file.name, '_CCF');

        % Handle atlasType - default to 'adult' if not found
        atlasTypeVal = 'adult'; % Default value
        if isfield(S, 'atlasType') && ~isempty(S.atlasType)
            atlasTypeVal = S.atlasType;
        end

        % Handle Group - empty if not found
        groupVal = ''; % Default empty string
        if isfield(S, 'Group') && ~isempty(S.Group)
            groupVal = S.Group;
        end

        channels = unique(string(S.ccf_summary.Channel));
        for j = 1:length(channels)
            chan = char(channels(j));
            data(end+1,:) = {file.name, animalName, atlasTypeVal, groupVal, chan, '', false, ''};
            identityKeys{end+1,1} = [file.name '_' chan];  % store unique ID
        end
    catch
        warning('Failed to load file: %s', file.name);
    end
end

% Step 2: Try loading metadata
metaPath = fullfile(baseDir, 'OUT', 'metadata.mat');
if exist(metaPath, 'file')
    try
        loaded = load(metaPath);
        if isfield(loaded, 'data') && ...
                size(loaded.data,1) == size(data,1)
            % Build ID keys from loaded metadata
            loadedKeys = strcat(loaded.data(:,1), "_", loaded.data(:,5));
            if isequal(loadedKeys, identityKeys)
                data = loaded.data;  % Apply full metadata
            end
        end
    catch
        disp('Could not load metadata.');
    end
end

fig = uifigure('Name', 'Cell3D Group Manager', 'Position', [100 100 1400 700]);
fig.Color = handles.colors.lightBg;

mainLayout = uigridlayout(fig, [1, 2]);
mainLayout.RowHeight = {'1x'};
mainLayout.ColumnWidth = {'3x', '2x'};
mainLayout.Padding = [0 0 0 0];         % Remove any padding that might affect sizing

% LEFT SIDE UI
uiLeft = uigridlayout(mainLayout, [6, 1]);
uiLeft.Layout.Row = 1;
uiLeft.Layout.Column = 1;

% Store original row heights (with last row for batch options)
uiLeft.UserData.originalRowHeights = {40, '1x', 50, 60, 60, 'fit'};

% Start with batch options hidden by setting last row height to 0
uiLeft.RowHeight = {uiLeft.UserData.originalRowHeights{1:5}, 0};
uiLeft.Padding = [5 5 5 5];uiLeft.Padding = [5 5 5 5];                 % Consistent padding

%----- Header
headerPanel = uipanel(uiLeft, 'Title', '', ...
    'BorderType', 'none', ...  % Changed from 'line' to 'none' for cleaner look
    'BackgroundColor', handles.colors.charcoal, ...
    'HighlightColor', handles.colors.cerulean, ...  % Border highlight color when needed
    'ForegroundColor', handles.colors.white);  % Changed from 'white' to handles.colors.white for consistency

headerLayout = uigridlayout(headerPanel, [1 2]);
headerLayout.ColumnWidth = {'1x', 80};
headerLayout.Padding = [10 5 10 5];
headerLayout.BackgroundColor = handles.colors.charcoal; % Ensure full coverage


uilabel(headerLayout, 'Text', 'CELL3D - Group and Color Assignment', ...
    'FontSize', 18, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'FontColor', handles.colors.white, ...  % Explicitly set font color
    'BackgroundColor', handles.colors.charcoal); % Match panel background

% Help Button

btnHelp = uibutton(headerLayout, 'Text', 'Help', 'ButtonPushedFcn', @(btn,event) openHelpDialog());
btnHelp.Layout.Column = 2;
btnHelp.Layout.Row = 1;
btnHelp.FontColor = [1 1 1];  % White text
btnHelp.BackgroundColor = handles.colors.gunmetal;  % Grey background to stand out

%----- Table
t = uitable(uiLeft, 'Data', data, ...
    'ColumnName', {'File Label', 'Animal', 'Atlas Type', 'Group', 'Channel', 'PlotColor', 'Exclude', 'ColorSource'}, ...
    'ColumnEditable', [false false false true false true true false], ...
    'ColumnFormat', {[],[],[],[],[],defaultColors,'logical',[]});

t.Data(:,7) = {false};
t.ColumnWidth = {'auto', 'auto', 'auto', 'auto', 'auto', 100, 80, 0};


for r = 1:size(t.Data,1)
    color = t.Data{r,6};
    if ischar(color) || isstring(color)
        try
            s = uistyle('BackgroundColor', color);
            addStyle(t, s, 'cell', [r, 6]);
        catch, end
    end
end

%----- Message Label
% Adjust grid layout for the message panel and button
msgAndButtonLayout = uigridlayout(uiLeft, [1, 2]); % One row, two columns
msgAndButtonLayout.ColumnWidth = {'1x', 'fit'}; % Message takes most space, button takes minimum necessary
msgAndButtonLayout.Layout.Row = 3;
msgAndButtonLayout.Padding = [0 0 0 0]; % No padding

% Create the message panel within the first column of the new grid layout
msgPanel = uipanel(msgAndButtonLayout, 'Title', '', ...
    'BorderType', 'line', ...
    'HighlightColor', handles.colors.charcoal,  ...
    'BackgroundColor', handles.colors.white);          % #3C7A89 (Cerulean)
msgPanel.Layout.Column = 1;

% Create message label within the message panel
% Using uigridlayout for automatic sizing within msgPanel
msgLayout = uigridlayout(msgPanel, [1, 1]); % One cell grid layout
msgLayout.RowHeight = {'1x'};
msgLayout.ColumnWidth = {'1x'};
msgLayout.Padding = [0 0 0 0];  % No padding

msgLabel = uilabel(msgLayout, ...
    'Text', 'No errors in the setup', ...
    'FontWeight', 'bold', ...
    'FontSize', 13, ...
    'HorizontalAlignment', 'center', ...  % Center horizontally
    'VerticalAlignment', 'center', ...  % Center vertically
    'FontColor', handles.colors.charcoal, ...
    'BackgroundColor', handles.colors.white, ...
    'WordWrap', 'on');

% Position metadata save button outside and to the right of the message box
btnSaveMetadata = uibutton(msgAndButtonLayout, 'Text', 'Save Metadata');
btnSaveMetadata.Layout.Column = 2;
btnSaveMetadata.Layout.Row = 1;


%----- Color Buttons Row
colorGrid = uigridlayout(uiLeft, [1, 5]);
colorGrid.Layout.Row = 4;
colorGrid.RowHeight = {40};
colorGrid.ColumnWidth = {'1x','1x', 80, 'fit','fit'};
colorGrid.Padding = [0 0 0 0];  % No padding

% Replace the existing color button callbacks with:
btnColorByGroup = uibutton(colorGrid, 'Text', 'Set plotColor by Group', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontColor', [1 1 1], ...
    'FontWeight', 'bold', ...
    'FontSize', 12);

btnColorByChannel = uibutton(colorGrid, 'Text', 'Set plotColor by Channel', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontColor', [1 1 1], ...
    'FontWeight', 'bold', ...
    'FontSize', 12);

% Color by
uilabel(colorGrid, 'Text', 'Color by:', 'HorizontalAlignment', 'right');
columnDropdown = uidropdown(colorGrid, ...
    'Items', {'plotColor','Animal','Group','Channel','Hemisphere','classifier','Brainstruct','Zperc','PercToMidline'}, ...
    'Value', 'plotColor', ...
    'BackgroundColor', handles.colors.gunmetal, ...
    'FontColor', handles.colors.white);

btnCustomPalette = uibutton(colorGrid, 'Text', 'Define Palette');

%----- Plot Options Controls
plotOptionsRow = uigridlayout(uiLeft, [1, 4]);
plotOptionsRow.Layout.Row = 5;
plotOptionsRow.ColumnWidth = {120, '1x', '1x',200};  % Adjust as needed for balance
plotOptionsRow.Padding = [5 5 5 5];

% Flip
uilabel(plotOptionsRow, 'Text', 'Flip to hemisphere:', 'HorizontalAlignment', 'right');
flipDropdown = uidropdown(plotOptionsRow, ...
    'Items', {'none','left','right'}, ...
    'Value', 'none');

% Create checkbox first (without callback)
saveCheckbox = uicheckbox(plotOptionsRow, ...
    'Text', 'Show Batch Save Options', ...
    'Value', false, ... % Starts unchecked
    'FontWeight', 'bold');
saveCheckbox.Layout.Column = 4;



% ----- Bottom Controls (Save Button Row) -----
OptionalSaveBatch = uigridlayout(uiLeft, [2, 4]); % 2 rows, 3 columns
OptionalSaveBatch.Layout.Row = 6;
OptionalSaveBatch.ColumnWidth = {'fit', '1x', 'fit','fit'}; % Label | Options | Buttons 2x
OptionalSaveBatch.RowHeight = {'fit', 'fit'};
OptionalSaveBatch.Visible = 'off'; % Start hidden

% Now safely connect the callback
saveCheckbox.ValueChangedFcn = @(src,event) toggleBatchOptions(src.Value, OptionalSaveBatch, uiLeft);

% ---- Column 1: Labels ----
% Split By Label
splitByLabel = uilabel(OptionalSaveBatch, 'Text', 'Split By:', 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
splitByLabel.Layout.Row = 1;
splitByLabel.Layout.Column = 1;

% Color By Label
colorByLabel = uilabel(OptionalSaveBatch, 'Text', 'Color By:', 'FontWeight', 'bold', 'HorizontalAlignment', 'right');
colorByLabel.Layout.Row = 2;
colorByLabel.Layout.Column = 1;

% ---- Column 2: Options ----
% Split By Options (Row 1)
optionsBox = uipanel(OptionalSaveBatch, 'BorderType', 'line', ...
    'HighlightColor', [0.5 0.5 0.5], 'BackgroundColor', [1 1 1]);
optionsBox.Layout.Row = 1;
optionsBox.Layout.Column = 2;

% Split By Checkboxes (inside box)
splitByGrid = uigridlayout(optionsBox, [1, 4], 'Padding', [5 5 5 5]); % Add padding
uicheckbox(splitByGrid, 'Text', 'None', 'Tag', 'none');
uicheckbox(splitByGrid, 'Text', 'Group', 'Tag', 'group');
uicheckbox(splitByGrid, 'Text', 'Channel', 'Tag', 'channel');
uicheckbox(splitByGrid, 'Text', 'Animal', 'Tag', 'animal');

% Color By Options (Row 2)
colorByBox  = uipanel(OptionalSaveBatch, 'BorderType', 'line', ...
    'HighlightColor', [0.5 0.5 0.5], 'BackgroundColor', [1 1 1]);
colorByBox .Layout.Row = 2;
colorByBox .Layout.Column = 2;

colorByGrid = uigridlayout(colorByBox , [2, 3], 'Padding', [5 5 5 5]);

% Row 1
cb1 = uicheckbox(colorByGrid, 'Text', 'plotColor', 'Tag', 'plotColor', 'Value', true);
cb1.Layout.Row = 1;
cb1.Layout.Column = 1;

cb2 = uicheckbox(colorByGrid, 'Text', 'Animal', 'Tag', 'Animal');
cb2.Layout.Row = 1;
cb2.Layout.Column = 2;

cb3 = uicheckbox(colorByGrid, 'Text', 'Group', 'Tag', 'Group');
cb3.Layout.Row = 1;
cb3.Layout.Column = 3;

cb4 = uicheckbox(colorByGrid, 'Text', 'Channel', 'Tag', 'Channel');
cb4.Layout.Row = 1;
cb4.Layout.Column = 4;

% Row 2

cb5 = uicheckbox(colorByGrid, 'Text', 'Hemisphere', 'Tag', 'classifier');
cb5.Layout.Row = 2;
cb5.Layout.Column = 1;

% ---- Column 3: Prefix & Button ----
% Prefix (Row 1)
prefixGrid = uigridlayout(OptionalSaveBatch, [2, 2]);
prefixGrid.Layout.Row = [1, 2];
prefixGrid.Layout.Column = 3;
prefixGrid.ColumnWidth = {'fit','fit'};
prefixGrid.RowHeight = {'fit', '1x'};

prefixLabel = uilabel(prefixGrid, 'Text', 'Prefix:', 'HorizontalAlignment', 'right');
prefixLabel.Layout.Row = 1;
prefixLabel.Layout.Column = 1;

prefixField = uieditfield(prefixGrid, 'text');
prefixField.Layout.Row = 1;
prefixField.Layout.Column = 2;

% ---- Column 2: Save Metadata Button ----
btnCalcCells  = uibutton(prefixGrid, ...
    'Text', 'Calculate Cells/Structure', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', handles.colors.coolGray, ...
    'FontColor', handles.colors.gunmetal);

btnCalcCells.Layout.Row = 2;
btnCalcCells.Layout.Column = 1;


% ---- Column 3: Save Batch Button ----
btnSaveBatch = uibutton(prefixGrid, ...
    'Text', 'Save Batch', ...
    'FontWeight', 'bold', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontColor', handles.colors.white, ...
    'ButtonPushedFcn', @(btn,event) saveBatchCallback(t, flipDropdown, prefixField, splitByGrid, colorByGrid, baseDir, msgLabel));

btnSaveBatch.Layout.Row = 2;
btnSaveBatch.Layout.Column = 2;

% RIGHT SIDE AXES FOR PLOTTING
rightPanel = uipanel(mainLayout, ...
    'BorderType','none', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'ForegroundColor', handles.colors.white);

rightPanel.Layout.Row = 1;
rightPanel.Layout.Column = 2;
% Use grid layout inside panel for better control
rightLayout = uigridlayout(rightPanel, [4, 1]);
rightLayout.RowHeight = {40, 50,'1x', 50};          % Plot area and button
rightLayout.Padding = [5 5 5 5];

%----- Header
%----- Row 1: Right Header (renamed from headerPanel to rightHeader)
rightHeader = uipanel(rightLayout, 'Title', '', ...
    'BorderType', 'none', ...
    'BackgroundColor', handles.colors.charcoal, ...
    'ForegroundColor', handles.colors.white);

rightHeader.Layout.Row = 1;  % Assign to first row of rightLayout

rightHeaderLayout = uigridlayout(rightHeader, [1, 1]);
rightHeaderLayout.Padding = [10 5 10 5];
rightHeaderLayout.BackgroundColor = handles.colors.charcoal;

uilabel(rightHeaderLayout, 'Text', 'Preview Plot', ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', ...
    'FontColor', handles.colors.white, ...
    'BackgroundColor', handles.colors.charcoal);
% ---- Row 2 View Buttons

% Assuming 'rightLayout' is your grid layout for plotting area
viewControlGrid = uigridlayout(rightLayout, [1, 3]); % One row, three columns for buttons
viewControlPanel.Layout.Row = 2;  % Assign to second row
% Define buttons

btnSideView = uibutton(viewControlGrid, 'Text', 'Side View');
btnTopView = uibutton(viewControlGrid, 'Text', 'Top View');
btnFrontView = uibutton(viewControlGrid, 'Text', 'Frontal View');

% Distribute buttons equally
btnSideView.Layout.Column = 1;
btnTopView.Layout.Column = 2;
btnFrontView.Layout.Column = 3;

%----- Row 3: Axes (plot area)
ax = uiaxes(rightLayout);
ax.Layout.Row = 3; 
ax.XColor = handles.colors.charcoal;  % Axis text/lines
ax.YColor = handles.colors.charcoal;
ax.ZColor = handles.colors.charcoal;

xlabel(ax, 'X (ML)');
ylabel(ax, 'Y (DV)');
zlabel(ax, 'Z (AP)');

view(ax, 90, 90); %default: set to top view
%----- Row 3: Button
%----- Row 3: Button and Dropdown Container
bottomControlGrid = uigridlayout(rightLayout, [1, 2]);
bottomControlGrid.Layout.Row = 4;
bottomControlGrid.ColumnWidth = {'1x', '1x'};
bottomControlGrid.Padding = [0 0 0 0];  % no padding for tight fit

% Update button
btnUpdatePlot = uibutton(bottomControlGrid, 'Text', 'Update Preview Plot', ...
    'BackgroundColor', handles.colors.coolGray, ...
    'FontColor', handles.colors.gunmetal, ...
    'FontWeight', 'bold');
btnUpdatePlot.Layout.Row = 1;
btnUpdatePlot.Layout.Column = 1;

% Save current view
btnSavePreview = uibutton(bottomControlGrid, ...
    'Text', 'Save Preview Plot', ...
    'BackgroundColor', handles.colors.cerulean, ...
    'FontColor', handles.colors.white, ...
    'FontWeight', 'bold', ...
    'FontSize', 12, ...
    'ButtonPushedFcn', @(btn,event) savePreviewPlot(ax,msgLabel));
btnSavePreview.Layout.Row = 1;
btnSavePreview.Layout.Column = 2;

% Store all handles
handles = struct();
handles.t = t;
handles.msgLabel = msgLabel;
handles.btnSaveBatch = btnSaveBatch;
handles.btnUpdatePlot = btnUpdatePlot;
handles.fig = fig;
handles.ax = ax;
handles.flipDropdown = flipDropdown;
handles.columnDropdown = columnDropdown;
handles.prefixField = prefixField;
handles.splitByGrid = splitByGrid;
handles.colorByGrid = colorByGrid;
handles.baseDir = baseDir; % Add this line

% Update callbacks to use handles
t.CellEditCallback = @(src, event) cellEditCallback(src, event, handles);
btnUpdatePlot.ButtonPushedFcn = @(btn,event) plotDataToAxes(handles, handles.flipDropdown.Value, handles.columnDropdown.Value);
btnSavePreview.ButtonPushedFcn = @(btn,event) savePreviewPlot(handles);
btnSaveMetadata.ButtonPushedFcn = @(btn,event) saveMetadata(handles);
btnCalcCells .ButtonPushedFcn = @(btn,event) calculateCellsPerStructure(handles);
btnSaveBatch.ButtonPushedFcn = @(btn,event) saveBatchCallback(handles);
btnColorByGroup.ButtonPushedFcn = @(btn,event) colorByGroup(handles);
btnColorByChannel.ButtonPushedFcn = @(btn,event) colorByChannel(handles);
columnDropdown.ValueChangedFcn = @(dd, event) updateMessage(handles, dd.Value);
btnSideView.ButtonPushedFcn = @(btn,event) setDynamicView(handles.fig, 0, 0);
btnTopView.ButtonPushedFcn = @(btn,event) setDynamicView(handles.fig, 90, 90);
btnFrontView.ButtonPushedFcn = @(btn,event) setDynamicView(handles.fig, -90, 0);
btnCustomPalette.ButtonPushedFcn = @(src,evt) openPaletteEditor(handles);

% Store color mappings and handles in figure
fig.UserData.channelColorMapping = channelColorMapping;
fig.UserData.groupColorMapping = groupColorMapping;
fig.UserData.handles = handles;

% Set initial button states and message
updateMessage(handles, handles.columnDropdown.Value);
end


%% Error handling and GUI stuff
function updateMessage(handles, colorby)
if ~isfield(handles, 'btnSaveBatch') || ~isvalid(handles.btnSaveBatch)
    error('Invalid button handle');
end

% Set default handles.colors
normalColor = [0.09 0.15 0.18];       % gunmetal
warningColor = [1.0 0.8 0.4];           % pastel amber, hex #FFCC66
errorColor = [0.8 0.2 0.2];           % Complementary red for errors

% Access components from handles
msgLabel = handles.msgLabel;
t = handles.t;
btnSaveBatch = handles.btnSaveBatch;
btnUpdatePlot = handles.btnUpdatePlot;

% Initialize with no errors
issues = {};
msgColor = normalColor;
btnState = 'on'; % Default to enabled

% Check if table has data
if isempty(t.Data)
    issues{end+1} = 'No files found in the selected folder.';
    msgColor = errorColor;
    btnState = 'off';
else
    data = t.Data;

    % Check excluded rows
    excluded = false(size(data,1),1);
    for i = 1:size(data,1)
        excluded(i) = isequal(data{i,7}, true);
    end
    included = ~excluded;

if ~any(included)
        issues{end+1} = 'No files included. All are marked as excluded.';
        msgColor = errorColor;
        btnState = 'off';
    else
        % Check for missing Group information
        groups = data(included, 4);
        if any(cellfun(@isempty, groups))
            issues{end+1} = 'Warning: Some included entries are missing Group information.';
            msgColor = warningColor;
        end
        
        % Check for missing Channel information
        channels = data(included, 5);
        if any(cellfun(@isempty, channels))
            issues{end+1} = 'Warning: Some files are missing Channel information.';
            msgColor = warningColor;
        end

        % Check atlas type consistency
        atlasTypes = data(included, 3);
        if numel(unique(atlasTypes)) > 1
            issues{end+1} = 'Not all included files share the same atlasType.';
            msgColor = errorColor;
            btnState = 'off';
        end


        % Check plot colors if needed
        if strcmpi(colorby, 'plotColor')
            plotColors = data(included, 6);
            if all(cellfun(@isempty, plotColors))
                issues{end+1} = 'No colors assigned.';
                msgColor = errorColor;
                btnState = 'off';
            elseif any(cellfun(@isempty, plotColors))
                issues{end+1} = 'Some PlotColors missing, these will not be plotted!';
                msgColor = warningColor;
            end
        end
    end
end

% Update message display
if isempty(issues)
    msgLabel.Text = 'No errors in the setup';
    msgLabel.FontColor = normalColor;
else
    msgLabel.Text = strjoin(issues, newline);
    msgLabel.FontColor = msgColor;
end

% Update button states
btnSaveBatch.Enable = btnState;
btnUpdatePlot.Enable = btnState;

drawnow;
end



function toggleBatchOptions(show, OptionalSaveBatch, uiLeft)
if show
    OptionalSaveBatch.Visible = 'on';
    % Restore original row heights to show the row
    uiLeft.RowHeight = uiLeft.UserData.originalRowHeights;
else
    OptionalSaveBatch.Visible = 'off';
    % Collapse the row by setting height to 0
    newHeights = uiLeft.UserData.originalRowHeights;
    newHeights{end} = 0;
    uiLeft.RowHeight = newHeights;
end
drawnow; % More efficient than full drawnow
end


function colorByGroup(handles)
    % Get components from handles
    t = handles.t;
    msgLabel = handles.msgLabel;

    % Get current palette (custom or default)
    palette = getCurrentPalette(handles.baseDir);

    % Get groups from table data
    groups = unique(handles.t.Data(:,4));
    groups(cellfun(@isempty, groups)) = [];

    groupColorMapping = containers.Map();

    % Get table data
    data = t.Data;
    
    % Temporarily disable cell edit callback if it exists
    if isprop(t, 'CellEditCallback')
        originalCallback = t.CellEditCallback;
        t.CellEditCallback = [];
    else
        originalCallback = [];
    end

    % Get unique groups (excluding empty)
    groups = unique(data(:,4));
    groups(cellfun(@isempty, groups)) = [];
    
    if isempty(groups)
        warning('No groups found in the data');
        return;
    end

% Update mapping using custom palette with cycling
for i = 1:length(groups)
    group = groups{i};
    if ~isKey(groupColorMapping, group)
        % Cycle through palette handles.colors if more groups than handles.colors
        colorIdx = mod(i-1, size(palette,1)) + 1;
        groupColorMapping(group) = palette(colorIdx,:);
    end
end


% Apply handles.colors to table
for r = 1:size(data,1)
    grp = data{r,4};
    if ~isempty(grp) && isKey(groupColorMapping, grp)
        rgb = groupColorMapping(grp);
        data{r,6} = sprintf('#%02X%02X%02X', round(rgb*255));;
        data{r,8} = 'Group';
        try
            s = uistyle('BackgroundColor', rgb);
            addStyle(t, s, 'cell', [r,6]);
        catch ME
            warning('Failed to add style to row %d: %s', r, ME.message);
        end
    end
end

% Update table data
t.Data = data;

% Update the mapping in UserData
handles.t.Parent.UserData.groupColorMapping = groupColorMapping;

% Restore original callback if it existed
if ~isempty(originalCallback)
    t.CellEditCallback = originalCallback;
end

% Update message display
updateMessage(handles, handles.columnDropdown.Value);
end

function colorByChannel(handles)
% Get components from handles
t = handles.t;
msgLabel = handles.msgLabel;

% Get current palette (custom or default)
palette = getCurrentPalette(handles.baseDir);
channelColorMapping = containers.Map();

% Get table data and unique channels (excluding empty)
data = t.Data;
channels = unique(data(:,5));
channels(cellfun(@isempty, channels)) = [];

if isempty(channels)
    warning('No channels found in the data');
    return;
end

% Temporarily disable cell edit callback if it exists
if isprop(t, 'CellEditCallback')
    originalCallback = t.CellEditCallback;
    t.CellEditCallback = [];
else
    originalCallback = [];
end

% Ensure all channels have a color assignment
for i = 1:length(channels)
    ch = channels{i};
    if ~isKey(channelColorMapping, ch)
        % Assign a default color if channel not in mapping
        colorIdx = mod(i-1, size(palette,1)) + 1;
        channelColorMapping(ch) = palette(colorIdx,:);
    end
end

% Apply handles.colors to table
for r = 1:size(data,1)
    ch = data{r,5};
    if ~isempty(ch) && isKey(channelColorMapping, ch)
        color = channelColorMapping(ch);
        data{r,6} = sprintf('#%02X%02X%02X', round(color*255));;
        data{r,8} = 'Channel';
        try
            s = uistyle('BackgroundColor', color);
            addStyle(t, s, 'cell', [r,6]);
        catch ME
            warning('Failed to add style to row %d: %s', r, ME.message);
        end
    end
end

% Update table data and store mapping
t.Data = data;
handles.t.Parent.UserData.channelColorMapping = channelColorMapping;

% Restore original callback if it existed
if ~isempty(originalCallback)
    t.CellEditCallback = originalCallback;
end

% Update message display
updateMessage(handles, handles.columnDropdown.Value);
end


function cellEditCallback(src, event, handles)
% Get components from handles
t = handles.t;
msgLabel = handles.msgLabel;

data = t.Data;
row = event.Indices(1);
col = event.Indices(2);

% If user edited plotColor column (col 6)
if col == 6
    newColor = data{row,6};

    if ischar(newColor) && strcmp(newColor, 'other...')
        chosenColor = uisetcolor();
       
        if ~isequal(chosenColor, 0) % User didn't cancel
            hexColor = sprintf('#%02X%02X%02X', round(chosenColor*255));
            data{row,6} = hexColor;
            data{row,8} = 'manual';  % mark source
            try
                s = uistyle('BackgroundColor', chosenColor);
                addStyle(t, s, 'cell', [row, 6]);
            catch, end
        else
            data{row,6} = '';  % reset if user cancels
        end
    else
        try
            if isempty(newColor)
                removeStyle(t, 'cell', [row, 6]);
            else
            s = uistyle('BackgroundColor', newColor);
            addStyle(t, s, 'cell', [row, 6]);
            data{row,8} = 'manual';
             end
        catch
            data{row,6} = '';
            data{row,8} = '';
        end
    end
end


% Reapply styles and update
for r = 1:size(data,1)
    color = data{r,6};
    if ischar(color) || isstring(color)
        try
            s = uistyle('BackgroundColor', color);
            addStyle(src, s, 'cell', [r, 6]);
        catch, end
    end
end

t.Data = data;
updateMessage(handles, handles.columnDropdown.Value);
end

function hex = rgb2hex(rgb)
rgb = round(rgb * 255);
hex = sprintf('#%02X%02X%02X', rgb(1), rgb(2), rgb(3));
end

function ccf_coordinates = getCoordinatesFromTable(t, baseDir)
% Handle both UI table and raw cell array input
if isa(t, 'matlab.ui.control.Table')
    rawData = t.Data;
else
    rawData = t;
end

% Convert to table with proper column names
ccf_coordinates = cell2table(rawData, ...
    'VariableNames', {'FileLabel', 'Animal', 'atlasType', 'Group', 'Channel', 'plotColor', 'Exclude','ColorSource'});

% Rest of your existing processing...
coordStructs = cell(height(ccf_coordinates), 1);

for i = 1:height(ccf_coordinates)
    try
        fileName = ccf_coordinates.FileLabel{i};
        channel = ccf_coordinates.Channel{i};
        fullPath = fullfile(baseDir, fileName);

        S = load(fullPath, 'ccf_summary');
        ccf_summary = S.ccf_summary;

        if istable(ccf_summary) && any(strcmp(ccf_summary.Properties.VariableNames, 'Channel'))
            subset = ccf_summary(strcmp(ccf_summary.Channel, channel), :);
            coordStructs{i} = struct('X', subset.X, 'Y', subset.Y, 'Z', subset.Z);
        else
            coordStructs{i} = struct('X', [], 'Y', [], 'Z', []);
        end
    catch ME
        warning('Failed to process file: %s\nError: %s', fileName, ME.message);
        coordStructs{i} = struct('X', [], 'Y', [], 'Z', []);
    end
end

ccf_coordinates.Coordinates = coordStructs;
end



%% Plotting functions


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


function [legendHandles, legendLabels] = plotDataToAxes(handles, flipDirection, colorby)
ax = handles.ax;
[az, el] = view(ax);

if isfield(handles, 'fullData') && ~isempty(handles.fullData)
    fullData = handles.fullData;
else
    fullData = getCoordinatesFromTable(handles.t, handles.baseDir);
end


% Get current data (to plot this subset)
if isa(handles.t, 'matlab.ui.control.Table')
    tData = handles.t.Data;
else
    tData = handles.t;
end

% Get flip direction safely
if isfield(handles, 'flipDropdown') && isvalid(handles.flipDropdown)
    flipDirection = handles.flipDropdown.Value;
elseif isfield(handles, 'flipDirection')
    flipDirection = handles.flipDirection;
else
    flipDirection = 'none';
end


ax = handles.ax;
baseDir = handles.baseDir;

% Get coordinates and continue as before
ccf_coordinates = getCoordinatesFromTable(tData, baseDir);
cla(ax);
legend(ax, 'off');
colorbar(ax, 'off');

% Find included rows (non-excluded)
includedRows = find(~ccf_coordinates.Exclude);

if isempty(includedRows)
    title(ax, 'No included data to plot');
    return;
end

% Load brain surface from first atlas type
firstAtlasType = ccf_coordinates.atlasType{includedRows(1)};
[~, ~, brain_data] = getAtlasFilesForType(firstAtlasType);

% Plot brain surface
patch(ax, 'Vertices', brain_data.brain.v, ...
    'Faces', brain_data.brain.f, ...
    'FaceColor', [0.7, 0.7, 0.7], ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 0.1);

hold(ax, 'on');

% Hemisphere flipping setup
flipToRight = strcmp(flipDirection, 'right');
flipToLeft = strcmp(flipDirection, 'left');
midline = mean([min(brain_data.brain.v(:,2)) max(brain_data.brain.v(:,2))]);

% Initialize variables for legend handling
legendHandles = gobjects(0);
legendLabels = {};

% PRECOMPUTE consistent category mapping from fullData (not just this subset)
if ismember(colorby, {'Animal', 'Group', 'Channel'})
    allCategories = fullData.(colorby);
    [uniqueCats, ~, catIdx_all] = unique(allCategories);
    cmap = linspecer(numel(uniqueCats));

    % Create a mapping from category → colormap row
    categoryMap = containers.Map(uniqueCats, num2cell(1:numel(uniqueCats)));
end

% Determine legend label source when using plotColor
if strcmp(colorby, 'plotColor')
    % Check if all ColorSource values in fullData match 'Group'
    if all(strcmp(fullData.ColorSource, 'Group'))
        legendLabelField = 'Group';
    % Check if all ColorSource values in fullData match 'Channel'
    elseif all(strcmp(fullData.ColorSource, 'Channel'))
        legendLabelField = 'Channel';
    else
        % Fallback to Animal if mixed or manual
        legendLabelField = 'Animal';
    end
end


% Main plotting loop
for i = 1:numel(includedRows)
    rowIdx = includedRows(i);
rowKey = [ccf_coordinates.FileLabel{rowIdx} '_' ccf_coordinates.Channel{rowIdx}];
allKeys = strcat(fullData.FileLabel, "_", fullData.Channel);
fullIdx = find(strcmp(allKeys, rowKey), 1);
if isempty(fullIdx), continue; end

% Load ccf_summary for the current row
fileData = load(fullfile(baseDir, fullData.FileLabel{fullIdx}), 'ccf_summary');
ccf_summary = fileData.ccf_summary;

if isempty(ccf_summary.Y)
    continue;
end

% Get subset for current channel
currentChannel = fullData.Channel{fullIdx};
ccf_summary = ccf_summary(strcmp(ccf_summary.Channel, currentChannel), :);

    if isempty(ccf_summary.Y)
        continue;
    end

    % Get subset for current channel
    currentChannel = ccf_coordinates.Channel{rowIdx};
    ccf_summary = ccf_summary(strcmp(ccf_summary.Channel, currentChannel), :);

    % check if any points have manual coloring
    anyManual = any(strcmp(ccf_coordinates.ColorSource(includedRows), 'manual'));


    % Apply hemisphere flipping if needed
    if flipToRight
        flip_idx = ccf_summary.Y < midline;
        ccf_summary.Y(flip_idx) = 2 * midline - ccf_summary.Y(flip_idx);
    elseif flipToLeft
        flip_idx = ccf_summary.Y > midline;
        ccf_summary.Y(flip_idx) = 2 * midline - ccf_summary.Y(flip_idx);
    end


    % Handle coloring based on colorby using switch statement
    switch colorby
        case 'plotColor'
            % Handle manual plot handles.colors
            colorEntry = ccf_coordinates.plotColor{rowIdx};
            if isempty(colorEntry)
                warning('Skipping row %d due to missing PlotColor.', rowIdx);
                continue;
            end
            color = getRGBColor(colorEntry);

                % Check if fullData is a table and has the column
            label = fullData.(legendLabelField){fullIdx}; % or fullData{fullIdx, legendLabelField}
   
            % Plot with this color and label
            h = scatter3(ax, ccf_summary.Z, ccf_summary.Y, ccf_summary.X, 36, ...
                color, 'filled', 'MarkerFaceAlpha', 0.3, 'MarkerEdgeColor', 'none');
            set(h, 'Clipping', 'off');
            % Add to legend if this label hasn't been added yet
            if ~any(strcmp(legendLabels, label))
                legendHandles(end+1) = h;
                legendLabels{end+1} = label;
                set(h, 'DisplayName', label);
            end

        case {'Animal', 'Group', 'Channel'}
            % Handle table metadata columns
            category = ccf_coordinates.(colorby){rowIdx};
            catIdx = categoryMap(category);

            % Plot with color based on category index
            h = scatter3(ax, ccf_summary.Z, ccf_summary.Y, ccf_summary.X, 36, ...
                cmap(catIdx,:), 'filled', 'MarkerFaceAlpha', 0.3, 'MarkerEdgeColor', 'none');

            % Add to legend if this category hasn't been added yet
            if ~any(strcmp(legendLabels, category))
                legendHandles(end+1) = h;
                legendLabels{end+1} = category;
                set(h, 'DisplayName', category);
            end

        case {'Hemisphere', 'classifier', 'Brainstruct'}
            % Handle per-point categorical data from ccf_summary
            categories = ccf_summary.(colorby);
            uniqueCats = unique(categories);
            cmap = linspecer(numel(uniqueCats));

            % Preallocate arrays for each category
            catPoints = struct();
            for k = 1:numel(uniqueCats)
                catPoints(k).X = [];
                catPoints(k).Y = [];
                catPoints(k).Z = [];
                catPoints(k).name = uniqueCats{k};
                catPoints(k).plotted = false; % Track if we've plotted this category
            end

            % Group points by category
            for k = 1:height(ccf_summary)
                catIdx = find(strcmp(categories{k}, uniqueCats));
                catPoints(catIdx).X(end+1) = ccf_summary.X(k);
                catPoints(catIdx).Y(end+1) = ccf_summary.Y(k);
                catPoints(catIdx).Z(end+1) = ccf_summary.Z(k);
            end

            % Plot all points for each category in one scatter call
            for k = 1:numel(catPoints)
                if ~isempty(catPoints(k).X)
                    h = scatter3(ax, catPoints(k).Z, catPoints(k).Y, catPoints(k).X, 36, ...
                        cmap(k,:), 'filled', 'MarkerFaceAlpha', 0.3);

                    % Only add to legend if this category hasn't been added yet
                    if ~any(strcmp(legendLabels, catPoints(k).name))
                        legendHandles(end+1) = h;
                        legendLabels{end+1} = catPoints(k).name;
                        set(h, 'DisplayName', catPoints(k).name);
                    end
                end
            end

        case {'Zperc', 'PercToMidline'}
            % Handle numerical data with gradient coloring - OPTIMIZED VERSION
            numData = ccf_summary.(colorby);

            % Convert cell array to numeric if needed
            if iscell(numData)
                numData = cellfun(@double, numData);
            end

            % Use perceptually uniform colormap (better than jet)
            cmap = jet(256);

            % DIRECT MAPPING APPROACH (values map exactly to colorbar)
            % Scale data to colormap indices (1-256) while preserving actual percentages
            normData = round(numData * 2.56 + 1);  % Convert 0-100 → 1-256
            normData(normData < 1) = 1;        % Clamp <0% to first color
            normData(normData > 256) = 256;    % Clamp >100% to last color
            normData(isnan(normData)) = 1;     % Handle NaNs

            % Get handles.colors for all points
            pointColors = cmap(normData, :);

            % Plot all points
            scatter3(ax, ccf_summary.Z, ccf_summary.Y, ccf_summary.X, 36, ...
                pointColors, 'filled', 'MarkerFaceAlpha', 0.3);

            % Set up colorbar with exact percentage mapping
            colormap(ax, cmap);
            cbar = colorbar(ax);
            caxis(ax, [0 100]);  % Fixed percentage range
            cbar.Label.String = colorby;
            cbar.Ticks = 0:20:100;

        otherwise
            error('Unsupported colorby selection: %s', colorby);
    end
end

% Configure legend if we have items to show
if ~isempty(legendHandles)
    legend(ax, legendHandles, legendLabels, 'Location', 'southeast', 'NumColumns', 2);
end

% Final axis setup
set(ax, 'ZDir', 'reverse');
set(ax, 'Color', 'w');
axis(ax, 'vis3d', 'equal');
axis(ax, 'off');
view(ax, az, el);
hold(ax, 'off');
end

% Helper function to dynamically find and set the view of the axes
function setDynamicView(fig, az, el)
ax = findobj(fig, 'Type', 'Axes');  % Find axes in the figure
    if isempty(ax)
        disp('No axes found in the figure.');
        return;
    end    
view(ax, az, el); % Set the view
    % Store the current view settings in the figure's UserData
    fig.UserData.currentView = [az, el];
end

%% saving functions
function saveMetadata(handles)
msgLabel = handles.msgLabel;
t = handles.t;
baseDir = handles.baseDir;

outDir = fullfile(baseDir, 'OUT');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

data = t.Data;
save(fullfile(outDir, 'metadata.mat'), 'data');

msgLabel.Text = sprintf('Metadata saved.');
msgLabel.FontColor = [0.35 0.75 0.45];  % success green #59BF73

end

function savePreviewPlot(handles)
msgLabel = handles.msgLabel;
ax = handles.ax;  % Access the axes from the handles
    
    % Capture the current view angles
    currentView = get(ax, 'View');  % This returns [azimuth, elevation]

[file, path] = uiputfile({'*.png','Image (*.png)'}, 'Save Preview As');
if isequal(file, 0), return; end
[~, name] = fileparts(file);

% Create new figure + axes
f = figure('Visible', 'off', 'Color', 'w', 'Units', 'normalized');
f.Position = [0.1 0.1 0.8 0.8];
axNew  = axes('Parent', f);

% Create minimal handles struct for plotting
tempHandles = struct();
tempHandles.t = handles.t;
tempHandles.ax = axNew ;
tempHandles.baseDir = handles.baseDir;
tempHandles.flipDirection = handles.flipDropdown.Value;
tempHandles.colorby = handles.columnDropdown.Value;

% Plot to this new axis
plotDataToAxes(tempHandles, tempHandles.flipDirection, tempHandles.colorby);
view(axNew , currentView); % Set the view to stored angles

% Use unified save function
savePlot(f, path, name, '', '');

% Clean up and update message
close(f);

msgLabel.Text = sprintf('Preview Plot saved.');
msgLabel.FontColor = [0.35 0.75 0.45];  % success green #59BF73

end


function savePlot(figHandle, outputDir, baseName, splitBy, colorBy)
% Ensure output directory exists
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Set up export
ax = findobj(figHandle, 'Type', 'Axes', '-not', 'Tag', 'legend');

% Set common axis styles
for i = 1:length(ax)
    set(ax(i), 'Color', 'w');
    axis(ax(i), 'vis3d', 'equal', 'off');
    set(ax(i), 'ZDir', 'reverse');
end

set(figHandle, 'visible', 'on'); 

% Export as PNG
outFile = fullfile(outputDir, [baseName, '.png']);
exportgraphics(figHandle, outFile, 'Resolution', 300, 'BackgroundColor', 'white');
saveas(figHandle, fullfile(outputDir, [baseName, '.fig']));
% could include PDF but takes VERY long to save
end


function saveBatchCallback(handles)
% Get components from handles
t = handles.t;
flipDropdown = handles.flipDropdown;
prefixField = handles.prefixField;
splitByGrid = handles.splitByGrid;
colorByGrid = handles.colorByGrid;
baseDir = handles.baseDir;
msgLabel = handles.msgLabel;
mainAx = handles.ax;

% Get the current view from the preview plot
currentView = [get(mainAx, 'View')];

% Initialize output
outDir = fullfile(baseDir, 'OUT');
if ~exist(outDir, 'dir'), mkdir(outDir); end
prefix = prefixField.Value;
if isempty(prefix), prefix = 'CELL3D'; end

% Find selected checkboxes
splitByChecks = findobj(splitByGrid, 'Type', 'uicheckbox', 'Value', true);
colorByChecks = findobj(colorByGrid, 'Type', 'uicheckbox', 'Value', true);

if isempty(splitByChecks) || ~all(arrayfun(@(x) isprop(x, 'Tag'), splitByChecks))
    splitByTags = {};
else
    splitByTags = {splitByChecks.Tag};
end

if isempty(colorByChecks) || ~all(arrayfun(@(x) isprop(x, 'Tag'), colorByChecks))
    colorBy = {};
else
    colorBy = {colorByChecks.Tag};
end

% Validate
if isempty(splitByTags) || isempty(colorBy)
    msgLabel.Text = 'Select at least one Split By and Color By option';
    msgLabel.FontColor = [0.8 0.2 0.2]; % errorRed
    return;
end

% Get coordinates
ccf_coordinates = getCoordinatesFromTable(t, baseDir);
includedRows = find(~ccf_coordinates.Exclude);

% Process each COLORING option first (outer loop)
for iColor = 1:length(colorBy)
    currentColor = colorBy{iColor};

    % Then process each SPLITTING option (inner loop)
    for iSplit = 1:length(splitByTags)
        currentSplit = splitByTags{iSplit};

        f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1200 800]);

        if strcmp(currentSplit, 'none')
            % CASE 1: All data in one panel with current coloring
            set(f, 'Position', [100 100 1200 800]);
            ax = axes('Parent', f, 'Position', [0.1 0.1 0.8 0.8]);

            tempHandles = struct();
            tempHandles.t = table2cell(ccf_coordinates(includedRows, {'FileLabel', 'Animal', 'atlasType', 'Group', ...
                'Channel', 'plotColor', 'Exclude','ColorSource'}));
            tempHandles.ax = ax;
            tempHandles.flipDirection = flipDropdown.Value;
            tempHandles.baseDir = baseDir;
            tempHandles.fullData = ccf_coordinates(includedRows,:);

            [hScatter, labels] = plotDataToAxes(tempHandles, flipDropdown.Value, currentColor);
%             title(ax, ['All Data - Colored by ' currentColor], 'FontSize', 12);

            if ~isempty(hScatter)
                legend(ax, hScatter, labels, 'Location', 'southoutside');
            end
                        
            set(ax, 'View', currentView);
            filename = sprintf('%s_All_coloredby-%s', prefix, currentColor);
            savePlot(f, outDir, filename, currentSplit, currentColor);

        else
            % CASE 2: Split by current category with current coloring
            switch currentSplit
                case 'group'
                    splitValues = unique(ccf_coordinates.Group(includedRows));
                    splitVar = ccf_coordinates.Group;
                    splitName = 'Group';
                case 'animal'
                    splitValues = unique(ccf_coordinates.Animal(includedRows));
                    splitVar = ccf_coordinates.Animal;
                    splitName = 'Animal';
                case 'channel'
                    splitValues = unique(ccf_coordinates.Channel(includedRows));
                    splitVar = ccf_coordinates.Channel;
                    splitName = 'Channel';
            end
            splitValues(cellfun(@isempty, splitValues)) = [];
            nGroups = length(splitValues);

            if nGroups == 0
                close(f);
                continue;
            end

            % Create subplot grid
            [nRows, nCols] = numSubplots(nGroups);
            if nGroups <= 3
                nRows = 1; nCols = nGroups; % Horizontal layout
            end

            % Collect legend entries across all panels
            allScatters = [];
            allLabels = {};

            % Create tight subplots
            gap = [0.01 0.01];       % [vertical horizontal] gap between plots
            marg_h = [0.1 0.4];    % [bottom top] margins
            marg_w = [0.01 0.01];    % [left right] margins
            axArray = tight_subplot(nRows, nCols, gap, marg_h, marg_w);

            for iGroup = 1:nGroups
                % Manual subplot positioning
                ax = axArray(iGroup);
                title(ax, splitValues{iGroup}, 'FontWeight', 'bold', 'FontSize', 12, 'Interpreter', 'none');

                % Filter data for this group only
                groupMask = strcmp(splitVar, splitValues{iGroup}) & ~ccf_coordinates.Exclude;

                tempHandles = struct();
                tempHandles.t = table2cell(ccf_coordinates(groupMask, {'FileLabel', 'Animal', 'atlasType', 'Group', ...
                    'Channel', 'plotColor', 'Exclude','ColorSource'}));

                tempHandles.ax = ax;
                tempHandles.flipDirection = flipDropdown.Value;
                tempHandles.baseDir = baseDir;
                tempHandles.fullData = ccf_coordinates(includedRows,:);

                % Plot with current color scheme
                % Suppress local legend during subplot plotting
                [tempScatter, tempLabels] = plotDataToAxes(tempHandles, flipDropdown.Value, currentColor);
                legend(ax, 'off');  % Force disable panel legend
                set(ax, 'View', currentView);

                % Collect unique legend entries
                if ~isempty(tempScatter)
                    for k = 1:length(tempScatter)
                        thisLabel = tempLabels{k};
                        if ~any(strcmp(thisLabel, allLabels))
                            allScatters(end+1) = tempScatter(k);
                            allLabels{end+1} = thisLabel;
                        end
                    end
                end
            end

            if ~isempty(allScatters)
                validIdx = isgraphics(allScatters);
                if any(validIdx)
                    % Create a new axes at the bottom for the legend
                    legendAx = axes('Parent', f, ...
                        'Position', [0 0 1 0.05], ... % Full width, short height
                        'Visible', 'off');

                    % Create dummy plot in that axes to host the legend
                    axes(legendAx); %#ok<LAXES> % set current axes to legendAx
                    lgd = legend(allScatters(validIdx), allLabels(validIdx), ...
                        'Orientation', 'horizontal', ...
                        'Location', 'southoutside');
                    lgd.Units = 'normalized';
                    lgd.Position = [0.5 - lgd.Position(3)/2, 0, lgd.Position(3), lgd.Position(4)];
                end
            end

            filename = sprintf('%s_splitby-%s_coloredby-%s', prefix, currentSplit, currentColor);
            savePlot(f, outDir, filename, currentSplit, currentColor);
        end

        close(f);
    end
end

msgLabel.Text = sprintf('Done! Saved %d figure sets', length(splitByTags)*length(colorBy));
msgLabel.FontColor = [0.35 0.75 0.45];  % success green #59BF73
end

%% Structure calculations

function calculateCellsPerStructure(handles)
    msgLabel = handles.msgLabel;
    ccf_coordinates = getCoordinatesFromTable(handles.t, handles.baseDir);
    includedRows = ~ccf_coordinates.Exclude;
    ccf_coordinates = ccf_coordinates(includedRows, :);

    % Initialize tables for both versions
    resultsFullNames = table();
    resultsAbbreviated = table();
    resultsClassifier = table();

    outDir = fullfile(handles.baseDir, 'OUT');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    prefix = handles.prefixField.Value;
    if isempty(prefix), prefix = 'CELL3D'; end

    uniqueCombos = unique(ccf_coordinates(:, {'FileLabel', 'Channel'}), 'rows');

for i = 1:height(uniqueCombos)
    % Find representative row
    rowIdx = find(strcmp(ccf_coordinates.FileLabel, uniqueCombos.FileLabel{i}) & ...
                  strcmp(ccf_coordinates.Channel, uniqueCombos.Channel{i}), 1);
    if isempty(rowIdx), continue; end

    fileData = load(fullfile(handles.baseDir, uniqueCombos.FileLabel{i}), 'ccf_summary');
    ccf_summary_all = fileData.ccf_summary;
    thisChannel = uniqueCombos.Channel{i};
    ccf_summary = ccf_summary_all(strcmp(ccf_summary_all.Channel, thisChannel), :);

    atlasType = ccf_coordinates.atlasType{rowIdx};
    group     = ccf_coordinates.Group{rowIdx};
    animal    = ccf_coordinates.Animal{rowIdx};


  % === Full Brainstructs ===
    uniqueBrainstructs = unique(ccf_summary.Brainstruct);
    for j = 1:numel(uniqueBrainstructs)
    fullName = uniqueBrainstructs{j};
            categoryFilter = strcmp(ccf_summary.Brainstruct, fullName);
            
            leftCount = sum(categoryFilter & strcmp(ccf_summary.Hemisphere, 'L'));
            rightCount = sum(categoryFilter & strcmp(ccf_summary.Hemisphere, 'R'));

            resultsFullNames = [resultsFullNames; {group, atlasType, ...
                animal, thisChannel, fullName, sum(categoryFilter), leftCount, rightCount}];
    end

  % === Abbreviated Brainstructs ===
    hasArea = contains(ccf_summary.Brainstruct, 'area');
    if any(hasArea)

            % Get unique abbreviated names
            fullNames = ccf_summary.Brainstruct(hasArea);
            abbrevNames = cell(size(fullNames));
            
            % Create abbreviated versions (keep up to and including "area")
            for n = 1:numel(fullNames)
                areaPos = strfind(fullNames{n}, 'area');
                if ~isempty(areaPos)
                    % Keep everything up to end of "area"
                    endPos = min(areaPos+4, length(fullNames{n})); % "area"
                    abbrevNames{n} = strtrim(fullNames{n}(1:endPos));
                else
                    abbrevNames{n} = fullNames{n};
                end
            end
            
            % Count with abbreviated names
            uniqueAbbrev = unique(abbrevNames);
            for j = 1:numel(uniqueAbbrev)
                abbrevName = uniqueAbbrev{j};
                categoryFilter = strcmp(abbrevNames, abbrevName);
                
                leftCount = sum(categoryFilter & strcmp(ccf_summary.Hemisphere(hasArea), 'L'));
                rightCount = sum(categoryFilter & strcmp(ccf_summary.Hemisphere(hasArea), 'R'));

                resultsAbbreviated = [resultsAbbreviated; {group, atlasType, ...
                animal, thisChannel, abbrevName, sum(categoryFilter), leftCount, rightCount}];
            end
        end
    
        % === Classifier ===
   if ismember('classifier', ccf_summary.Properties.VariableNames)
        uniqueClassifiers = unique(ccf_summary.classifier);
        for j = 1:numel(uniqueClassifiers)
            categoryName = uniqueClassifiers{j};
            categoryFilter = strcmp(ccf_summary.classifier, categoryName);

            % Count for each hemisphere
            leftCount = sum(categoryFilter & strcmp(ccf_summary.Hemisphere, 'L'));
            rightCount = sum(categoryFilter & strcmp(ccf_summary.Hemisphere, 'R'));

            % Append to the results table
            resultsClassifier = [resultsClassifier; {group, atlasType, ...
                animal, thisChannel, categoryName, sum(categoryFilter), leftCount, rightCount
            }];
        end
    end
end

    % Save full names count
    if ~isempty(resultsFullNames)
        resultsFullNames.Properties.VariableNames = {'Group','AtlasType','Animal','Channel','Brainstruct','Total','Left','Right'};
        writetable(resultsFullNames, fullfile(outDir, [prefix '_Counts_Brainstruct_wLayers.csv']));
    end

    % Save abbreviated count (only if we found area-containing structures)
    if ~isempty(resultsAbbreviated)
        resultsAbbreviated.Properties.VariableNames = {'Group','AtlasType','Animal','Channel','Brainstruct','Total','Left','Right'};
        writetable(resultsAbbreviated, fullfile(outDir, [prefix '_Counts_Brainstruct_woLayers.csv']));
    end

  
         % Write results to CSV for Classifier
    if ~isempty(resultsClassifier)
        resultsClassifier.Properties.VariableNames = {'Group', 'AtlasType', 'Animal', 'Channel', 'Classifier', 'Total', 'Left Hemisphere', 'Right Hemisphere'};
        classifierFile = fullfile(outDir, [prefix '_Counts_classifier.csv']);
        writetable(resultsClassifier, classifierFile);
        msgLabel.Text = sprintf('Brain structure counts and classifier counts have been saved to %s', outDir);
        msgLabel.FontColor = [0.35 0.75 0.45];  % success green #59BF73
    else
        msgLabel.Text = sprintf('Saved Counts per Brain Structure to %s', outDir);
    msgLabel.FontColor = [0.35 0.75 0.45];
    end

        % --- Save master CCF summary ---
    allCells = table();  % Initialize

    for i = 1:height(uniqueCombos)
        % Match metadata
        rowIdx = find(strcmp(ccf_coordinates.FileLabel, uniqueCombos.FileLabel{i}) & ...
                      strcmp(ccf_coordinates.Channel, uniqueCombos.Channel{i}), 1);
        if isempty(rowIdx), continue; end

        fileData = load(fullfile(handles.baseDir, uniqueCombos.FileLabel{i}), 'ccf_summary');
        ccf_summary_all = fileData.ccf_summary;
        thisChannel = uniqueCombos.Channel{i};
        ccf_summary = ccf_summary_all(strcmp(ccf_summary_all.Channel, thisChannel), :);

        % Append metadata as new columns
        ccf_summary.Group = repmat(ccf_coordinates.Group(rowIdx), height(ccf_summary), 1);
        ccf_summary.Animal = repmat(ccf_coordinates.Animal(rowIdx), height(ccf_summary), 1);
        ccf_summary.Channel = repmat(thisChannel, height(ccf_summary), 1);
        ccf_summary.AtlasType = repmat(ccf_coordinates.atlasType(rowIdx), height(ccf_summary), 1);

        % Combine into master table
        allCells = [allCells; ccf_summary];
    end

    % Save as CSV and MAT
    writetable(allCells, fullfile(outDir, [prefix '_Master_CCF_summary.csv']));
    save(fullfile(outDir, [prefix '_Master_CCF_summary.mat']), 'allCells');

end
    
%% Functions to download for this to work and help description
function allPresent = checkDependencies()
    % Define required functions with their download URLs
    requiredFunctions = {
        struct('name', 'linspecer', ...
               'url', 'https://www.mathworks.com/matlabcentral/fileexchange/42673-beautiful-and-distinguishable-line-handles.colors-colormap', ...
               'purpose', 'Color generation for distinguishable plot handles.colors'), 
        struct('name', 'numSubplots', ...
               'url', 'https://www.mathworks.com/matlabcentral/fileexchange/26310-numsubplots', ...
               'purpose', 'Optimal subplot arrangement calculation'), 
        struct('name', 'tight_subplot', ...
               'url', 'https://www.mathworks.com/matlabcentral/fileexchange/27991-tight_subplot-nh-nw-gap-marg_h-marg_w', ...
               'purpose', 'Better subplot spacing control')
    };
    
    % Check which functions are missing
    missingIdx = ~cellfun(@(x) exist(x.name, 'file'), requiredFunctions);
    
    if any(missingIdx)
        % Prepare HTML-formatted error message
        htmlMsg = ['<html><b>Missing required dependencies:</b><br><br>' ...
                   'The following MATLAB functions are required but not found:<br><br>'];
        
        % Add each missing function with its link and purpose
        for i = find(missingIdx)'
            htmlMsg = [htmlMsg sprintf(...
                ['• <a href="%s"><font color="#0066CC">%s</font></a>' ...
                 '<br><i>%s</i><br><br>'], ...
                requiredFunctions{i}.url, ...
                requiredFunctions{i}.name, ...
                requiredFunctions{i}.purpose)];
        end
        
        htmlMsg = [htmlMsg 'Please download these from MATLAB File Exchange before proceeding.</html>'];
        
        % Create error dialog
        fig = uifigure('Position', [100 100 500 200+60*sum(missingIdx)], ...
                      'Name', 'Dependency Check');
        uialert(fig, htmlMsg, 'Missing Dependencies', ...
               'Icon', 'error', ...
               'Interpreter', 'html');
        
        allPresent = false;
        return;
    end
    
    allPresent = true;
end

function openHelpDialog()
    % Create a uifigure for the help dialog
    helpFig = uifigure('Name', 'CELL3D Plot Manager - Help', 'Position', [100 100 650 650]);
    helpFig.Resize = 'off';
    helpFig.Color = [0.96 0.96 0.96]; % Match GUI's lightBg color

    % Create a panel that will contain the text control
    helpPanel = uipanel(helpFig, 'Position', [10 10 630 630], 'BorderType', 'none');
    helpPanel.BackgroundColor = [1 1 1]; % White background
    helpPanel.HighlightColor = [0.24 0.48 0.54]; % Cerulean border

    % Define help text sections as separate variables
    header = '<html><body style="font-family:Arial; font-size:12px; color:#16262E; line-height:1.6;">';
    
    section1 = [...
        '<h2 style="color:#2E4756; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Getting Started</h2>'...
        '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
        '<p><b>Before plotting or saving, verify these requirements:</b></p>'...
        '<ul style="margin-top:10px; line-height:1.5;">'...
        '<li style="margin-bottom:8px;">✅ <b>Files loaded correctly:</b> '...
        'All coordinate files from Step 1 (<span style="color:#3C7A89; font-family:monospace;">*_CCF_coords*.mat</span>) appear as rows</li>'...
        '<li style="margin-bottom:8px;">✅ <b>Animal names:</b> '...
        'Automatically extracted from filenames during Step 1 processing</li>'...
        '<li style="margin-bottom:8px;">✅ <b>Group assignments:</b> '...
        'Edit in <span style="background-color:#F5F5F5; color:#3C7A89; padding:1px 4px; border-radius:3px;">Group column</span> if needed for your analysis</li>'...
        '<li style="margin-bottom:8px;">✅ <b>Color settings:</b> '...
        'Choose method: '...
        '<span style="background-color:#3C7A89; color:white; padding:2px 6px; border-radius:4px; margin:0 3px;">By Group</span> '...
        '<span style="background-color:#3C7A89; color:white; padding:2px 6px; border-radius:4px; margin:0 3px;">By Channel</span> '...
        'or set manually in dropdown</li>'...
        '<li style="margin-bottom:8px;">✅ <b>Exclusions:</b> '...
        'Check <span style="color:#3C7A89;">Exclude boxes</span> for any datasets to omit from analysis</li>'...
        '<li style="margin-bottom:8px; color:#CC3333;">❗ <b>Atlas consistency:</b> '...
        'All included files <u>must</u> use the same atlas type</li>'...
        '</ul>'...
         '<p style="color:#3C7A89; font-style:italic; margin-top:10px;">Note: when running for the first time, you may need to download helper functions (see popup if shown)</p>'...
        '</div>'];
    
    section2 = [...
        '<h2 style="color:#2E4756; margin-top:20px; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Data Management</h2>'...
        '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
        '<p><b>Editable Columns:</b></p>'...
        '<ul>'...
        '<li><span style="background-color:#F5F5F5; color:#3C7A89;">Group</span>: Define experimental groups (text input)</li>'...
        '<li><span style="background-color:#F5F5F5; color:#3C7A89;">PlotColor</span>: Set using buttons or use dropdown for pre-defined handles.colors or "other..." for custom</li>'...
        '<li><span style="background-color:#F5F5F5; color:#3C7A89;">Exclude</span>: Checkbox to remove this entry from analysis</li>'...
        '</ul>'...
        '<p><b>Metadata Saving:</b></p>'...
        '<ul>'...
        '<li>Click <span style="background-color:#9FA2B2; color:white; padding:2px 4px; border-radius:3px;">Save Metadata</span> [hidden in "show batch save options"] to save settings from table (handles.colors, groups etc)</li>'...
        '<li>Saves to <span style="color:#3C7A89;">OUT/metadata.mat</span> and will be loaded on start-up in future sessions</li>'...
        '</ul>'...
        '<p><b>Non-Editable Columns (retrieved from files):</b></p>'...
        '<ul>'...
        '<li>File Label, Animal, Atlas Type, Channel</li>'...
        '</ul>'...
        '</div>'];
    
    section3 = [...
        '<h2 style="color:#2E4756; margin-top:20px; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Visualization</h2>'...
        '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px; margin-bottom:15px;">'...
        '<p><b>View Controls:</b></p>'...
        '<ul>'...
        '<li><span style="background-color:#3C7A89; color:white; padding:2px 4px; border-radius:3px;">Preset Views</span>: Side (sagittal), Top (horizontal), Front (coronal)</li>'...
        '<li><span style="background-color:#3C7A89; color:white; padding:2px 4px; border-radius:3px;">Rotate</span>: Click cube icon in toolbar (hover to find), then click+drag</li>'...
        '<li><span style="background-color:#3C7A89; color:white; padding:2px 4px; border-radius:3px;">Zoom</span>: Click magnifying glass (hover to find), then click on plot</li>'...
        '<li><span style="background-color:#3C7A89; color:white; padding:2px 4px; border-radius:3px;">Pan</span>: Click hand icon (hover to find), then click+drag</li>'...
        '</ul>'...
        '<p style="color:#CC3333; font-style:italic; margin-top:10px;">❗ <b>Current view angle is preserved when saving (both in batch and preview).</b></p>'...
        '</div>'];
    
    section4 = [...
        '<h2 style="color:#2E4756; margin-top:20px; margin-bottom:10px; border-bottom:2px solid #3C7A89;">Saving Options</h2>'...
        '<div style="background-color:#F5F5F5; padding:10px; border-radius:5px;">'...
        '<p><b>Preview Plot:</b></p>'...
        '<ul>'...
        '<li>Click <span style="background-color:#3C7A89; color:white; padding:2px 4px; border-radius:3px;">Save Preview Plot</span> to save current view</li>'...
        '<li>Saves as PNG/FIG with current orientation</li>'...
        '</ul>'...
        '<p><b>Batch Processing:</b></p>'...
        '<ul>'...
        '<li>Enable <span style="color:#3C7A89;">☑ Show Batch Save Options</span> to show menu options </li>'...
        '<li><span style="color:#3C7A89;">Split By</span>: Select any combination of: None (1 Panel)/Group/Channel/Animal</li>'...
        '<li><span style="color:#3C7A89;">Color By</span>: Select any combination of available coloring options</li>'...
        '<li><span style="color:#3C7A89;">Prefix</span>: Add a prefix to figure names</li>'...
        '<li>Click <span style="background-color:#3C7A89; color:white; padding:2px 4px; border-radius:3px;">Save Batch</span> to generate all plots <br>(each split by and color by combination will be saved as seperate figure)</li>'...
        '</ul>'...
        '</div>'...
        '</body></html>'];

    % Combine all sections
    helpText = [header section1 section2 section3 section4];

    % Create a HTML-enabled text control
    helpTextControl = uihtml(helpPanel, 'Position', [10 10 610 610]);
    helpTextControl.HTMLSource = helpText;
end

%% Color palette

function openPaletteEditor(handles)
    fig = uifigure('Name', 'Color Palette Editor', 'Position', [100 100 600 200]);
    outDir = fullfile(handles.baseDir, 'OUT');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    % Load or initialize palette
    paletteFile = fullfile(handles.baseDir, 'OUT', 'customPalette.mat');
    if exist(paletteFile, 'file')
        load(paletteFile, 'palette');
    else
        palette = linspecer(6); % Default to 6 handles.colors
    end
    
    % Main grid layout
    mainGrid = uigridlayout(fig, [2 1]);
    mainGrid.RowHeight = {120, 40}; % Color swatches row, controls row
    mainGrid.RowSpacing = 10;
    mainGrid.Padding = [20 20 20 20];
    
    % Color swatches grid (horizontal layout)
    swatchGrid = uigridlayout(mainGrid, [1 size(palette,1)]);
    swatchGrid.Layout.Row = 1;
    swatchGrid.ColumnWidth = repmat({'1x'}, 1, size(palette,1));
    swatchGrid.RowHeight = {'1x'};
    swatchGrid.Padding = [0 0 0 0];
    
    % Create color buttons (swatches)
    colorButtons = gobjects(size(palette,1), 1);
    for i = 1:size(palette,1)
        colorButtons(i) = uibutton(swatchGrid);
        colorButtons(i).BackgroundColor = palette(i,:);
        colorButtons(i).Text = '';
        colorButtons(i).ButtonPushedFcn = @(src,evt) changeColor(i);
        colorButtons(i).Tooltip = sprintf('RGB: %.2f, %.2f, %.2f', palette(i,1), palette(i,2), palette(i,3));
    end
    
    % Control buttons
    controlGrid = uigridlayout(mainGrid, [1 4]);
    controlGrid.Layout.Row = 2;
    controlGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
    
    btnAdd = uibutton(controlGrid, 'Text', '＋ Add', ...
        'ButtonPushedFcn', @addColor);
    
    btnRemove = uibutton(controlGrid, 'Text', '－ Remove', ...
        'ButtonPushedFcn', @removeColor);
    
    btnReset = uibutton(controlGrid, 'Text', '↻ Reset', ...
        'ButtonPushedFcn', @resetDefault);
    
    btnSave = uibutton(controlGrid, 'Text', '💾 Save', ...
        'ButtonPushedFcn', @savePalette);
    
    % Callback functions
    function changeColor(idx)
        newColor = uisetcolor(palette(idx,:));
        if ~isequal(newColor, 0)
            palette(idx,:) = newColor;
            colorButtons(idx).BackgroundColor = newColor;
            colorButtons(idx).Tooltip = sprintf('RGB: %.2f, %.2f, %.2f', newColor(1), newColor(2), newColor(3));
        end
    end
    
    function addColor(~,~)
        palette = [palette; rand(1,3)]; % Add random color
        updateSwatches();
    end
    
    function removeColor(~,~)
        if size(palette,1) > 1
            palette(end,:) = []; % Remove last color
            updateSwatches();
        else
            uialert(fig, 'You must keep at least one color', 'Warning');
        end
    end
    
    function resetDefault(~,~)
        palette = linspecer(6); % Reset to default
        updateSwatches();
    end
    
    function savePalette(~,~)
        save(paletteFile, 'palette');
        uialert(fig, 'Palette saved successfully!', 'Success', 'Icon', 'success');
    end
    
    function updateSwatches()
        % Delete old grid
        delete(swatchGrid.Children);
        
        % Create new grid with updated dimensions
        swatchGrid = uigridlayout(mainGrid, [1 size(palette,1)]);
        swatchGrid.Layout.Row = 1;
        swatchGrid.ColumnWidth = repmat({'1x'}, 1, size(palette,1));
        swatchGrid.RowHeight = {'1x'};
        
        % Recreate color buttons
        colorButtons = gobjects(size(palette,1), 1);
        for i = 1:size(palette,1)
            colorButtons(i) = uibutton(swatchGrid);
            colorButtons(i).BackgroundColor = palette(i,:);
            colorButtons(i).Text = '';
            colorButtons(i).ButtonPushedFcn = @(src,evt) changeColor(i);
            colorButtons(i).Tooltip = sprintf('RGB: %.2f, %.2f, %.2f', palette(i,1), palette(i,2), palette(i,3));
        end
    end
end

function palette = getCurrentPalette(baseDir)
    % Check for custom palette file
    paletteFile = fullfile(baseDir, 'OUT', 'customPalette.mat');
    
    if exist(paletteFile, 'file')
        % Load custom palette
        load(paletteFile, 'palette');
    else
        % Use default palette (linspecer or any other default)
        palette = linspecer(8); % Default to 8 handles.colors
    end
end


function rgbOutput = getRGBColor(inputColor)
    % getRGBColor - Convert a color name, hex code, or RGB triplet to an RGB triplet.
    % If inputColor is an RGB triplet, it returns the same triplet.
    % If inputColor is a recognized color name or hex code, it converts it to an RGB triplet.
    % Otherwise, it throws an error.

    if isnumeric(inputColor) && numel(inputColor) == 3 && all(inputColor >= 0 & inputColor <= 1)
        % Input is already an RGB triplet
        rgbOutput = inputColor;
    elseif ischar(inputColor) || isstring(inputColor)
        % Convert color name or hex code to RGB triplet
        inputColor = char(inputColor); % Ensure it's a character array for comparison
        if startsWith(inputColor, '#')
            % Convert hex code to RGB triplet
            rgbOutput = hex2rgb(inputColor);
        else
            % Convert named color to RGB triplet
            switch lower(inputColor)
                case 'red'
                    rgbOutput = [1, 0, 0];
                case 'green'
                    rgbOutput = [0, 1, 0];
                case 'blue'
                    rgbOutput = [0, 0, 1];
                case 'yellow'
                    rgbOutput = [1, 1, 0];
                case 'cyan'
                    rgbOutput = [0, 1, 1];
                case 'magenta'
                    rgbOutput = [1, 0, 1];
                case 'black'
                    rgbOutput = [0, 0, 0];
                case 'white'
                    rgbOutput = [1, 1, 1];
                % Add more color names as needed
                otherwise
                    error('Invalid color input. Provide either a valid RGB triplet, hex code, or a recognized color name.');
            end
        end
    else
        error('Invalid color input. Provide either a valid RGB triplet, hex code, or a recognized color name.');
    end
end


function rgb = hex2rgb(hex)
    % Convert hex color code to RGB triplet
    if hex(1) == '#'
        hex = hex(2:end);
    end
    if numel(hex) ~= 6
        error('Invalid hex color code. Provide a 6-character hex code.');
    end
    rgb = reshape(sscanf(hex, '%2x') / 255, 1, 3);
end

%save button should save and close