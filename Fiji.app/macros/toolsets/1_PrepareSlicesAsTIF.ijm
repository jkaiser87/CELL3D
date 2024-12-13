// FIJI Toolset for Single-Slice Multiple-Channel TIF Processing
// Author: Julia Kaiser, 2024
// - First version: 09/25/2024
// more information on Github: https://github.com/jkaiser87/

// Description: 
// This toolset is designed to streamline the creation of single-slice, multiple-channel TIF files from whole slide 
// scans or individual channel TIF files. It enables users to split channels, crop specific slices, and organize 
// results by animal or experimental conditions. The steps and functionality are outlined below.

// Step 1: Set Folder Containing All TIF Files
// The user specifies a folder that contains TIF images for processing. These images can belong to several animals, 
// with the animal identifier placed at the beginning of the filename (e.g., "EXP1-A2_10x_filename_Ch01.tif"). 
// Filenames should use "_" as a delimiter to separate key elements such as experiment IDs and channels.

// Step 2: Split Channels for All TIF Files in the Folder
// This step splits all multi-channel TIF images into individual channels. We implemented this to allow users to 
// exclude specific channels (if needed) and to adjust the histograms of the channels in external software like Photoshop.
// This can help reduce background noise or enhance specific features before further processing. 

// Step 3: Crop Slices from Whole Slide Images
// This step enables users to crop specific regions or slices from the whole slide images. The channels need to be 
// separated before running this step to ensure proper cropping and consistency between channels. 

// Step 4: Separate Channel Image Handling
// If the folder contains separate-channel images (indicated by a filename ending such as "_Ch01.tif" or "_DAPI.tif"), 
// the script will automatically process each channel individually. This ensures compatibility with both multi-channel 
// and single-channel datasets and provides flexibility depending on how the images were captured.

// Final Output:
// After processing, the output will be a folder with single-slice multiple-channel TIF files. If the folder contains 
// images from multiple animals (as determined by the filenames), each animal’s images will be placed in its own 
// subfolder for better organization and ease of analysis.



macro "Unused Tool-1 - " {}  // leave empty slot

macro "Flip image [F]"{
	run("Flip Horizontally");
    print ("--- Selection flipped.");
}

macro "Setup Folder to process Action Tool - icon:folder.png" {
  
  var defaultPath = call("ij.Prefs.get", "input.x",0); //retrieve last input?
  
  Dialog.create("Setup");
  Dialog.addMessage("Choose folder to process \n"
+"(folder in which the TIF files are)\n");
  Dialog.addDirectory("\n", defaultPath)
  Dialog.show;
  
  var input = Dialog.getString();
  if (!endsWith(input, File.separator)) {
      input += File.separator;
	}
    
print("! Input folder: "+input);
	   
call("ij.Prefs.set", "input.x", input); //finally sets input as global variable

}

macro "Split Channels of TIF Action Tool - icon:resize.png"{
print(" --- Neurolucida export: Converting Composite tif to split channel tifs.");

input = call("ij.Prefs.get", "input.x",0); //retrieve input

list = getFileList(input);	
suffix = ".tif";
subfolderPath = input + "TIF/";
File.makeDirectory(subfolderPath);
 if (!File.exists(subfolderPath))
  exit("Unable to create directory");
  
run("Bio-Formats Macro Extensions"); 
setBatchMode("hide");

for (i = 0; i < list.length; i++) {
showProgress(i,list.length);

if(endsWith(list[i], suffix)) {
	run("Bio-Formats Importer", "open=[" + input + list[i] +"] split_channels view=Hyperstack stack_order=XYCZT");	
	titles = getList("image.titles");
	titles = Array.sort(titles);
	for (t = 0; t < titles.length; t++) {
	
	selectWindow(titles[t]);
	
	newname = replace(list[i],".tif","")+"_Ch0"+(t+1);
	rename(newname);
	saveAs("TIF",subfolderPath+newname);
	close;
	
	}
}
}

var input = subfolderPath; //adds this new tif folder to the input
call("ij.Prefs.set", "input.x", input); // sets new tif folder input as global variable
print(" --- Neurolucida export: Input folder set to "+input);	

showMessage("All tif files have been split into seperate channels. \nIf necessary, go to photoshop to adapt histograms before continuing to next step.");	
}

macro "Crop Slices from Slide Action Tool - icon:crop.png"{
 runMacro(getDirectory("macros")+"//toolsets//scripts//M2_CropSlices_FromSepChannels.ijm");
}


macro "Merge Seperate TIF into Single Channel Action Tool - icon:merge.png"{
 runMacro(getDirectory("macros")+"//toolsets//scripts//MergeChannels_ByChannelname_JK.ijm");
}