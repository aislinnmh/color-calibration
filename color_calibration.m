%% Color camera calibration using ISA ColorGauge Nano target
% Aislinn Hurley, Duke University, 2/16/26

%% Load a .png image of the test target 

load_name = 'target';
img = imread([load_name '.png']);

% Perform background subtraction, if background image available
load_bgd_name = 'background';
try
    bgd = imread([load_bgd_name '.png']);
    img = img - bgd;
catch
end

%% Select target corners for automatic ROI detection

f1 = figure(1);
imshow(img)
title('Select the four corners of the color calibration target.')
[xi,yi] = getpts;

%% Sort corners

[ylen, xlen, ~] = size(img);

% Left v right 
l = (xi < xlen/2);
r = (xi > xlen/2);
% Top v bottom
t = (yi < ylen/2);
b = (yi > ylen/2);
% Assign corners to top left, top right, bottom left, or bottom right.
x_tl = xi(t&l);
x_tr = xi(t&r);
x_bl = xi(b&l);
x_br = xi(b&r);
y_tl = yi(t&l);
y_tr = yi(t&r);
y_bl = yi(b&l);
y_br = yi(b&r);


%% Find grid positions of each square to determine ROIs

% Width of chart, bl to br
w = sqrt((x_br-x_bl)^2+(y_br-y_bl)^2);

% Height of chart, tl to bl
h = sqrt((x_tl-x_bl)^2+(y_tl-y_bl)^2);

% Calculate angle of tilt of target in image
theta = atan((y_br-y_bl)/(x_br-x_bl)); % radians

% Create a 5x6 grid
w_sq = w/6;
h_sq = h/5;

% Calculate evenly spaced grid positions, where the top left corner is 0,0
gridPos = zeros(5, 6, 2); % Initialize grid positions array
for row = 1:5
    for col = 1:6
        gridPos(row, col, 1) = (col - 0.5) * w_sq; % X coordinate
        gridPos(row, col, 2) = (row - 0.5) * h_sq; % Y coordinate
    end
end

% Rotate grid positions to match chart's angle
R = [cos(theta) -sin(theta); sin(theta) cos(theta)]; % Build rotation matrix
gridPosTemp = reshape(gridPos, 30, 2); % Grid --> Column for matrix math
gridPos2 = (R*gridPosTemp'); % Apply rotation
gridPos2 = gridPos2 + repmat([x_tl; y_tl],1,30); % Line up positions in image with top left corner
gridPos = reshape(gridPos2,2,5,6); % Grid <-- Column

% Set ROI size
roi_size = 20;
hw = roi_size/2;  % ROI half-width

%% Draw ROIs
f2 = figure(2);
imshow(img)
hold on
scatter(gridPos2(1,:), gridPos2(2,:),"square",'y','LineWidth',2)
hold off
title('Detected square locations, ROI size approximate')

%% Assign colors to ROIs in correct order

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


%% Assign grays to ROIs in correct order

% Start at white in top right, go left to right and top to bottom
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

%% Find RGB values in each ROI

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

RGB = [RGB_colors; RGB_grays];

%% Load true RGB values corresponding to each ROI

% True sRGB at D50 
true_RGB = csvread('trueRGB.csv');

%% Solve for CCM
% RGB * CCM = truergb

CCM = RGB \ true_RGB;

%% Display corrected target 

img_col = double(reshape(img,xlen*ylen,3));
img_col_corr = img_col*CCM;
img_corr = reshape(img_col_corr,ylen,xlen,3);

f3 = figure(3);
subplot(1,2,1)
imshow(img_corr/255)
title('Color Corrected Image')
subplot(1,2,2)
imshow(img)
title('Original Image')


%% Display generated ColorGauge

gt_img = uint8(zeros(ylen,xlen,3));

% Fill in colored squares in order
xind = 6;
yind = 1;
side = 'top';
sz = 50;
for i = 1:18
    cenx = int16(gridPos(1,yind,xind));
    ceny = int16(gridPos(2,yind,xind));
    gt_img(ceny-sz:ceny+sz, cenx-sz:cenx+sz, 1) = uint8(true_RGB(i,1));
    gt_img(ceny-sz:ceny+sz, cenx-sz:cenx+sz, 2) = uint8(true_RGB(i,2));
    gt_img(ceny-sz:ceny+sz, cenx-sz:cenx+sz, 3) = uint8(true_RGB(i,3));

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

% Fill in gray squares in order
xind = 5;
yind = 2;
n_row = 1;
for i = 19:30
    cenx = int16(gridPos(1,yind,xind));
    ceny = int16(gridPos(2,yind,xind));
    gt_img(ceny-sz:ceny+sz, cenx-sz:cenx+sz, 1) = uint8(true_RGB(i,1));
    gt_img(ceny-sz:ceny+sz, cenx-sz:cenx+sz, 2) = uint8(true_RGB(i,2));
    gt_img(ceny-sz:ceny+sz, cenx-sz:cenx+sz, 3) = uint8(true_RGB(i,3));
    % Move
    if xind ~= 2
        xind = xind - 1;
    else
        xind = 5;
        yind = yind + 1;
    end
end

f4 = figure(4);
subplot(1,2,1)
imshow(img_corr/255)
title('Color Corrected Image')
subplot(1,2,2)
imshow(gt_img)
title('Simulated Ground Truth')


%% Save CCM

% Save CCM in a csv file
csvwrite("CCM.csv",CCM);


%% Save figures
saveas(f2,'detected_rois.png')
saveas(f3,'corrected_v_original.png')
saveas(f4,'corrected_v_truth.png')

