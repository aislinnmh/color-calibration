# color-calibration
Color calibration software for the Image Science Associates ColorGauge target, which includes 18 GretagMacbeth ColorChecker squares and 12 gray squares.

Step 1: Take image(s) of the calibration target and background (optional).

At a minimum, you need one image of the calibration target and zero background images. Best practice is to take several images of the target and average them to improve SNR, and a few averaged background images to remove DC. Be sure to:
- Take image(s) of the target in the same lighting you will be using during imaging.
- Take background image(s) with no target or lighting (optional).
- Orient image(s) such that target appears horizontal (5 squares high by 6 wide) with the dark brown square in the top right corner. The target being slightly angled (<45 degrees) is fine.
- Save images into the color-calibration folder with the default name formatting:
    - Single image - "target.png"
    - Multiple images - "targetX.png", where X=1-N
    - Background image - "background.png"
    - Multiple bakcground images - "backgroundX.png", X=1-N

Step 2: Run preprocess.m if you are using multiple target or background images.

This will save a single target.png and background.png automatically. It will run with any number of target and background images, as long as the naming conventions are followed.

Step 3: Run color_calibration.m
- Select the four corners of the target in the image. The squares are then automatically detected and assigned to their true color.
- Wait for the color correction matrix (CCM) to be calculated and saved to CCM.csv.
- Check that the color calibration looks as expected in the corrected_v_original.png and corrected_v_truth.png images that were saved to the color-calibration folder. If there are issues, check your target orientation to make sure colors were mapped in the correct order and check detected_rois.png to see if your chosen corners resulted in good square detections.

Step 4: Input the CCM values into SpinView.
- Open the Processing tab.
- Check ISP Enable and Color Transformation Enable.
- Select Custom from the RGB Transform Light Source list.
- Select a gain (e.g. Gain 00) from the Color Transformation Value Selector list and enter the corresponding CCM value in Color Transformation Value.
    - Repeat for all 9 Gain values in the format below:

Gain00   Gain01   Gain02 

Gain10   Gain11   Gain12

Gain20   Gain21   Gain22

- Save the new CCM to the User Set 0 in SpinView so that it loads automatically when you use the camera.
