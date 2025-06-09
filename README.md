# CELL3D: Quantitative Mapping of Labeled Cells in 3D Brain Space


![image](https://github.com/jkaiser87/CELL3D/blob/main/wiki/CELL3D_white.png)


**CELL3D** is a MATLAB-based pipeline for analyzing and visualizing retrogradely labeled neurons in 3D, aligned to the Allen Brain Atlas. It supports batch processing of histological data, automatic coordinate transformation, and customizable plotting by anatomical features, genetic labels, or experimental conditions.

![image](https://github.com/jkaiser87/CELL3D/blob/main/wiki/CELL3D_showcase.png)


--- 

## Dependencies and Setup

### FIJI.app
- **Download FIJI** from the official <a href="https://fiji.sc/">website</a> and place it e.g. into your C: drive.
- Download the **Fiji folder** from this repository and paste it into your `FIJI.app` folder. Make sure that it lands in the right subfolder (Fiji.app/macro/toolsets)
    
### MATLAB (tested on 2023a)

This pipeline builds on AP_histology, a powerful toolkit for aligning histological images to the Allen Brain Atlas. We recommend following their excellent documentation for installation and usage. Special thanks to the AP_histology team for making this invaluable resource freely available to the community.

#### AP_histology

    [AP_histology](https://github.com/petersaj/AP_histology):
    Follow the installation instructions on the original AP_histology GitHub repository.

OR

    [devAP_histology](https://github.com/jkaiser87/devAP_histology) (forked for developmental atlas support):
    Supports both adult and developmental mouse brain atlases.
    You can find it on GitHub here: jkaiser87/devAP_histology

    MATLAB Toolboxes and Add-ons:

        Ensure that the Curve Fitting Toolbox is installed.

        Download and install the natsortfile add-on (Natural-Order Filename Sort, Version 3.4.5 by Stephen23).

    MATLAB Scripts Folder:

        Download the MATLAB folder from this toolbox.

    Add to MATLAB Path:

        Make sure that AP_histology or devAP_histology was added to the Path as described in their installation guide.


---

## File preparation

## Data Format

- **Requirement**: Folder containing single-slice TIF files of one coronal brain, sorted from rostral to caudal (additional pipeline provided that can help with cropping slide images and merging split-channel images).
- **Important: Naming of the Files.** The pipeline **relies heavily on filenames** for correct processing and sorting. The correct syntax for the filenames is `EXP1-A2_filename_s001.tif` where:
  - The part **before the first underscore** (e.g., `EXP1-A2`) is used to **identify the animal** (and should be unique). This can include both the experiment and animal name, separated by a hyphen `-` if necessary.
  - `_s001` is the slice number (slice numbers must be padded to avoid incorrect sorting, e.g., `_s001`, `_s002`).
  - **Optional:** `_Ch01` represents the channel (e.g., `_Ch01`, `_DAPI`), if using separate-channel images.

**Ensure that filenames always start with the animal name** (or a combination of experiment and animal name, ***unique!***). Anything before the first underscore will be treated as the animal identifier. This is critical for correct organization and grouping of data.

**Example filenames that work for the pipeline:**

``` bash
EXP1-A2_10x-Cortex_RFP-GFP-NeuN_s001.tif
EXP1-A3_retroAAV-GFP_DAPI_fNissl_10x_s002_Ch01.tif
EXP1-A3_retroAAV-GFP_DAPI_fNissl_10x_s002_Ch02.tif
EXP2-B5_thistext-really-doesnt-matter-as-long-as-the-rest_fits_s005_DAPI.tif
EXP2-B5_thistext-really-doesnt-matter-as-long-as-the-rest_fits_s005_Alexa488.tif
```        

--- 

## Running the Pipeline
### FIJI - get coordinates of volume in 2D slices
#### 1. Pre-processing of images 
(Optional, creates folder containing single-slice TIF files of one coronal brain, sorted from rostral to caudal)
![image](https://github.com/user-attachments/assets/03f29abe-bd51-4ad2-b448-e559ca6c82ed)

- Open FIJI and navigate to the toolbox by selecting `>>` `1_PrepareSlicesAsTif`. *(If you cannot find it, the files have not been copied into the right spot)*
- ![folder](https://github.com/user-attachments/assets/48cd6811-b670-4e04-af52-b52ba09f3ff7)
Select the appropriate folder: Choose the folder that contains either whole-slide overview TIF files or single-slice separate-channel TIF files. If the correct filename convention is followed, the folder can contain multiple animals' data within the same folder.

![image](https://github.com/user-attachments/assets/3fb3d8cd-442c-4e24-aedb-67101f3efc77)
- **If you are working with whole-slide imaging:**
  - ![image](https://github.com/user-attachments/assets/c781c3c7-77ef-432e-8b27-0ca4efac2c04) Split the channels.
  - Then, if needed, make any adjustments to the split channel images (such as reducing background noise) in Photoshop.
  - ![image](https://github.com/user-attachments/assets/1c4609b5-9eee-4bf0-b8ea-09ae165468b6) Crop the whole-slide images by drawing rectangles around each slice you want to export.
  - At the end, the script will save each slice as a separate file in the subfolder "Slices/ANIMALNAME".
- ![image](https://github.com/user-attachments/assets/db138804-912a-4c5f-8562-f8fe5b60610c) **If you are working with separate-channel images:** This script will allow you to provide a folder of split-channel images. You will be prompted to select which channels to include and to specify the color for each channel in the final multichannel TIF file.
- ![image](https://github.com/user-attachments/assets/db138804-912a-4c5f-8562-f8fe5b60610c) **If you are working with multi-channel images and want to exclude channels:**  This script also allows to remove channels from the image that you do not want and re-arrange the colors.

**OUTPUT:** The result will be a folder with one multichannel TIF file per section (i.e., per slice).  
If multiple animals provided, there will be subfolders in the folder "Slices" according to the animal name.

#### 2. CELL3D pipeline (semi-automatic detection of cells)
![image](https://github.com/user-attachments/assets/0837537b-ea83-4e07-bb54-6a5238af1de2)

- Open FIJI and navigate to the toolbox by selecting `>>` `2_CELL3D_CellCoords`. 
- ![image](https://github.com/user-attachments/assets/7f85864d-4866-470c-bfa6-9bd9f3986a01) Set the folder to a folder containing sections (multichannel) of 1 or more animals (this can be the folder "Slices" created in the previous step or directly a folder containing TIF files of 1 animal. Make sure that no other tif files are in this or a subfolder).
- ![image](https://github.com/user-attachments/assets/2d716049-19c7-4aeb-a8cf-f3071fd66221) Preprocess slices: Rotate and flip slices as necessary
  - If necessary, flip the section using Ctrl + F.
  - Rotate the slices by drawing a line at the midline (from top to bottom).
  - To skip a particular slice, just press OK directly without placing a line.
-  The script will ask 3 times to click a certain location: Press ok after clicking on that point in the image (a cross will be placed there). Far left corner of the slice (left most point), Midline, Far right corner of the slice (right most point). This will be used later to assess location to cingulate, medial or lateral cortex according to distance to midline
- ![neuron](https://github.com/user-attachments/assets/55e247ec-46ad-49fa-8657-ee8f351391b4) Cell labeling:
  - Choose channel you want to process (C1 (red), C2 (green), C3 (blue), C4 (farred)).
  - Provide a particle size threshold and a binary threshold value if available (this may need some testing, but starting with the default can work, 150 threshold + 50 particle size for cortical neurons)
  - The script will isolate the channel of interest and automatically select neurons if possible.
    - If successful, you will see a selection in your image and a message will pop up to say that you can now fine tune your selection by clicking more cells (mouse click) or deleting wrongly detected cells (Ctrl + click on marker). Go through before clicking OK!
    - If unsuccessful, a message will pop up saying that you should do a manual selection. Click on each cell you want to label.
    - If you are unhappy with the semi-automatic labeling, try these steps:
      - to re-try thresholding with a different threshold, use button ![threshold](https://github.com/user-attachments/assets/a53341eb-6e7f-4103-b8c0-796e9c166650) and click into the image. It will ask you for a new threshold, higher number means less cells to be detected. You can do this as often as you want to try to get a better number, but it can only do so much if there is a lot of background or high labeling outside the cortex.
      - to delete the current selection, press ![pen](https://github.com/user-attachments/assets/226d6316-d3ac-42d1-899e-0937f31e706a). You may e.g. want to do this if a) too many wrong ones are selected and you want to do it manually or b) if there are no cells to be selected but the script placed some markers
  - When all cells are selected, press ok, and the script will automatically save the coordinates of selected cells as ZIP and CSV file in a subfolder and loop to the next image.
  - Once a ZIP file has been created, the image will be skipped when restarting the script (meaning you can take a break any time and restart in between images). If you want to re-do a file, rename or delete this ZIP file!
- ![clean](https://github.com/user-attachments/assets/869bd898-af9d-4201-99c8-34bc5afb73f7) Cleaning mode:
  - This script allows you to clean up some of the selected cells. This will open each file with the corresponding cell selection and gives you the opportunity to delete or add more cells. It will loop through the whole folder.
- **Output**: Subfolders of CSV and ZIP files for each slice in which cells were detected
  
### MATLAB - transform coordinates into CCFv3 space
#### 1. Animal-specific transformation
- Open `CELL3D_Step1_Animal_GUI.m` in MATLAB. 
- Set Current folder to the folder containing the tif files of a single animal (eg 'Slices/EXP1-A1/')
- Run the script (if asked, "add to path")
- a GUI will pop up:

![image](https://github.com/jkaiser87/CELL3D/blob/main/wiki/CELL3D_Step1_GUI.PNG)

- Check that all tif files are found and listed on the left
- Choose channel(s) and assign an optional group.
- Select the appropriate Atlas Type (e.g. adult or developmental) to enable AP_histology.
- Run AP_histology (alignment to CCF). After running through all steps (up to manual alignment), close the GUI and re-start CELL3D to refresh. 
- (Optional) Med/Lat classification  as defined in Sahni Lab, can be skipped.
- Run Coordinate → CCF transformation to visualize in 3D space.
- This will display the cells within CCF space in a plot on the right.
- You can also choose to mirror cells onto left/right hemisphere, choose what to colorby and explore the Batch saving options

You're now ready to view and save 3D plots of labeled cells of this animal! Refer to the Help to find out more about the functions available.

- To prepare for step 2 (summarizing several animals in one brain), use the button "save to additional folder" and choose a folder where the `_*coord.mat` file will be stored. Add all additional animals after processing them to this same folder.

#### 2. Plotting Multiple Animals into 1 figure

- Open `CELL3D_Step1_Animal_GUI.m` in MATLAB. 
- Set Current folder to the folder containing the tif files of the first animal (eg 'Slices/EXP1-A1/')

![image](https://github.com/jkaiser87/CELL3D/blob/main/wiki/CELL3D_Step2_GUI.PNG)



## Future updates
- [ ] Remove med/lat/cing assessment for public 
