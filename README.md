# color-calibration
Color calibration software for the Image Science Associates ColorGauge target, which includes 18 GretagMacbeth ColorChecker squares and 12 gray squares.

Step 1: Take image(s) of the calibration target and background (optional).

You need minimum one image of the calibration target. Best practice is to take several images of the target and average them to improve SNR, and a few averaged background images to remove DC. Be sure to:
- Take image(s) in the same lighting you will be using during imaging
- Orient image(s) such that target appears horizontal (5 squares high by 6 wide) with the dark brown square in the top right corner. The target being slightly angled (<45 degrees) is fine.
- Save images into the color-calibration folder with the names correctly formatted:
    - Single image - target.png
    - Multiple images - targetX.png, X=1-N
    - Background image - background.png
    - Multiple bakcground images - backgroundX.png, X=1-N

Step 2: Run preprocess.m if you are using multiple target or background images

This will save a single target.png and background.png automatically. It will run with any number of target and background images, as long as the naming conventions are followed.

Step 3: Run color_calibration.m
- Select the four corner of the target in the image. The squares are then automatically detected and assigned to their true color.
- Wait for the color correction matrix (CCM) to be calculated and saved to CCM.csv
- Check that the color calibration looks as expected in the corrected_v_original.png and corrected_v_truth.png images that were saved to the color-calibration folder

Step 4: Input the CCM values into SpinView.
- Open the Processing tab
- Check ISP Enable and Color Transformation Enable
- Select Custom from the RGB Transform Light Source list
- Select a gain (e.g. Gain 00) from the Color Transformation Value Selector list and enter the CCM value in Color Transformation Value, repeating for all 9 Gain values in the format below:

Gain00   Gain01   Gain02 

Gain10   Gain11   Gain12

Gain20   Gain21   Gain22

- Save the new CCM to the User Set 0 in SpinView so that it loads automatically when you use the camera
