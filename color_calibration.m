%% Color camera calibration using ISA ColorGauge Nano target
% Aislinn Hurley, Duke University, 2/16/26

%% Load a .png image of the test target 
% Taken in same lighting as imaging session will have
% Prior to loading, make sure target appears horizontal (5 high by 6 wide)
% and dark brown is int he top right corner
load_name = 'target_test';
img = imread([load_name '.png']);

% Load and average 10 images

    % Load background image

% Background subtraction



%% Colorchecker

init_name = 'matlab_test';
init = imread([init_name '.png']);
chart = colorChecker(init);

%%
figure(1)
imshow(img)
title('Select the four corners of the color calibration target.')
[xi,yi] = getpts;

[ylen, xlen, ~] = size(img);


%% Sort corners
% Left v right 
l = (xi < xlen/2);
r = (xi > xlen/2);
% Top v bottom
t = (yi < ylen/2);
b = (yi > ylen/2);
% Assign 
x_tl = xi(t&l);
x_tr = xi(t&r);
x_bl = xi(b&l);
x_br = xi(b&r);
y_tl = yi(t&l);
y_tr = yi(t&r);
y_bl = yi(b&l);
y_br = yi(b&r);


%% Find grid positions

% Width of chart, bl to br
w = sqrt((x_br-x_bl)^2+(y_br-y_bl)^2);

% Height of chart, tl to bl
h = sqrt((x_tl-x_bl)^2+(y_tl-y_bl)^2);

% Create 5x6 grid
w_sq = w/6;
h_sq = h/5;
% Calculate the grid positions for the color checker squares
gridPos = zeros(5, 6, 2); % Initialize grid positions array
for row = 1:5
    for col = 1:6
        gridPos(row, col, 1) = (col - 0.5) * w_sq; % X coordinate
        gridPos(row, col, 2) = (row - 0.5) * h_sq; % Y coordinate
    end
end

gridPosTemp = reshape(gridPos, 30,2);

% Angle tilt of chart
theta = atan((y_br-y_bl)/(x_br-x_bl)) % radians
R = [cos(theta) -sin(theta); sin(theta) cos(theta)]

% Transform/rotate grid positions
gridPos2 = (R*gridPosTemp');
gridPos2 = gridPos2 + repmat([x_tl; y_tl],1,30);


% Set ROI size

roi_size = 20;
hw = roi_size/2;



%%
gridPos = reshape(gridPos2,2,5,6);

%%
% Draw ROI
figure(2)
imshow(img)
hold on
scatter(gridPos2(1,:), gridPos2(2,:),"square",'y','LineWidth',2)
% scatter(squeeze(gridPos(1,1,:)), squeeze(gridPos(2,1,:)),"square",'y','LineWidth',2)
% scatter(squeeze(gridPos(1,:,1)), squeeze(gridPos(2,:,1)),"square",'y','LineWidth',2
hold off
title('Detected square locations, ROI size approximate')


%% Assign colors
% Start at dark brown in top right, go CCW around outside
ROIs_color = zeros(18,4);
xind = 6;
yind = 1;
side = 'top';
for i = 1:18
    cenx = int16(gridPos(1,yind,xind));
    ceny = int16(gridPos(2,yind,xind));
    ROIs_color(i, :) = [cenx - hw, ceny - hw, roi_size-1, roi_size-1];

    % Determine side
    if side == "top" & xind == 1
        side = "left"; % Change direction to left for the next ROI
    elseif side == "left" && yind == 5
        side = "bottom"; % Change direction to bottom
    elseif side == "bottom" && xind == 6
        side = "right"; % Change direction to right
    elseif side == "right" && yind == 1
        side = "top"; % Change direction back to top
    end

    % Move
    if side == "top"
        xind = xind - 1;
    elseif side == "left"
        yind = yind + 1;
    elseif side == "bottom"
        xind = xind + 1;
    elseif side == "right"
        yind = yind -1;
    end
end


%% Assign grayscale
% Start at white in top right, go left to right, top to bottom

ROIs_gray = zeros(12,4);
xind = 5;
yind = 2;
n_row = 1;
for i = 1:12
    cenx = int16(gridPos(1,yind,xind));
    ceny = int16(gridPos(2,yind,xind));
    ROIs_gray(i, :) = [cenx - hw , ceny - hw, roi_size-1, roi_size-1];

    % Move
    if xind ~= 2
        xind = xind - 1;
    else
        xind = 5;
        yind = yind + 1;
    end
end

%% Find RGB values

RGB_colors = zeros(18, 3); % Initialize array for color values
ROI_I_colors = zeros(18, roi_size, roi_size, 3); % Initialize array for color values
for i = 1:18
    roi = imcrop(img, ROIs_color(i, :)); % Crop the image to the ROI
    ROI_I_colors(i, :, :, :) = roi;
    RGB_colors(i, :) = mean(reshape(roi, [], 3), 1); % Calculate mean RGB values
end

RGB_grays = zeros(12, 3); % Initialize array for color values
ROI_I_grays = zeros(12, roi_size, roi_size, 3); % Initialize array for color values
for i = 1:12
    roi = imcrop(img, ROIs_gray(i, :)); % Crop the image to the ROI
    ROI_I_grays(i, :, :, :) = roi;
    RGB_grays(i, :) = mean(reshape(roi, [], 3), 1); % Calculate mean RGB values
end

%%
% chart.ColorROIs.ROI(1) = ROIs_color(1);

%%
% chart.RegistrationPoints = [[x_br y_br],[x_bl y_bl],[x_tl y_tl],[x_tr y_tr]];

% chart.ColorROIs.ROI = [15,17,17,17]
% %%
% [colorValues,colorCorrectionMatrix] = measureColor(chart)