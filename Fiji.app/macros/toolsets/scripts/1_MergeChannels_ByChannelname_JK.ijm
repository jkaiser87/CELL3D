macro "Merge Seperate Channels into 1" {

// written by Julia Kaiser, September 2024
// ----  takes a folder of tif files ending in _AF488, AF555, AF647, DAPI (eg from Axioscan) and
// ----  merges them into a 4 channel tif. Also allows to exclude channels to save as RGB etc.

// Prompt the user to select the folder containing the TIF files
dir = getDirectory("Select the folder containing the TIF files");

//dir = "Z:\\Research\\Sahni Lab\\Data\\_Team_ABC\\_STARQ\\P35NpyCartpt\\Axioscan\\P35CartptCre-A7_Bst_GFPif-flTdTif-fNissl_10x\\";

// Get the list of all files in the folder
list = getFileList(dir);


// Create the channels array dynamically by finding unique endings after the last underscore
channels = getUniqueChannels(list);

// --- setup
// Ask which channels to exclude
Dialog.create("Exclude Channels");
for (i = 0; i < channels.length; i++) {
    Dialog.addCheckbox("Exclude " + channels[i], false);
}
Dialog.show();

// Get the user's input on which channels to include
includeChannels = newArray();
folderName = "";
for (i = 0; i < channels.length; i++) {
	result = Dialog.getCheckbox();
	if (result == 0) {
    includeChannels = Array.concat(includeChannels, channels[i]);
    folderName += channels[i] + "-";    
}}

// Allow the user to map each channel to a channel slot (c1 to c8)
slots = newArray("c1", "c2", "c3", "c4", "c5", "c6", "c7");

Dialog.create("Channel Mapping");

// Create a dialog to assign channels to slots
Dialog.create("Assign Channels to Slots");
Dialog.addMessage("Assign channels to colors");
Dialog.addMessage("c1 (red), c2 (green), c3 (blue), c4 (grey),\nc5 (cyan), c6 (magenta), c7 (yellow)");
assignedSlots = newArray();
for (i = 0; i < includeChannels.length; i++) {
    Dialog.addChoice(includeChannels[i], slots, slots[i]);
}
Dialog.show();


// Store the user's mapping of channels to slots
for (i = 0; i < includeChannels.length; i++) {
    assignedSlots = Array.concat(assignedSlots, Dialog.getChoice());
}


// Create a new folder for the merged images with the name of the included channels

if (endsWith(folderName, "-")) { // Remove the last hyphen if the folder name isn't empty
    folderName = substring(folderName, 0, lengthOf(folderName) - 1);
}
outputDir = dir + folderName + "/";
File.makeDirectory(outputDir);

// Build the folder name based on the user-specified channel-slot mapping
colorMapping = newArray("R", "G", "B", "G", "C", "M", "Y"); // c1 -> R, c2 -> G, c3 -> B, etc.
colfolderName = "";

// Iterate through the colorMapping array to ensure the correct color order (RGB, etc.)
for (i = 0; i < colorMapping.length; i++) {
    // Check if any of the assignedSlots match the current color mapping (c1 to c8)
    for (j = 0; j < assignedSlots.length; j++) {
        // Get the index of the assigned slot (e.g., "c1" -> 0, "c2" -> 1, etc.)
        slotIndex = parseInt(assignedSlots[j].substring(1)) - 1;
        
        // If the slot index matches the current position in colorMapping, add that color
        if (slotIndex == i) {
            colfolderName += colorMapping[i]; // Add R, G, B, etc. in the correct order
            break; // Stop once we find the matching slot for this color
        }
    }
}
// Create a new subfolder based on the assigned slots
colorDir = outputDir + colfolderName + "/";
File.makeDirectory(colorDir);

setBatchMode("hide");
// Process each unique file name
uniqueNames = newArray();

for (i=0; i<list.length; i++) {
	
	if (endsWith(list[i], ".tif")) {
    // Extract the base name (before the channel suffix)
    underscoreIndex = lastIndexOf(list[i], "_");
    baseName = substring(list[i], 0, underscoreIndex);
    // Check if this base name has been processed already
   if (!arrayContains(uniqueNames, baseName)) {
        uniqueNames = Array.concat(uniqueNames, baseName);
                
        // Open the corresponding images for each non-excluded channel
		images = newArray();
        for (j = 0; j < channels.length; j++) {
        	if (arrayContains(includeChannels, channels[j])) {
                 fileName = dir + baseName + "_" + channels[j] + ".tif";
                        if (File.exists(fileName)) {
                            open(fileName);
                             // Check the image type
            				imageType = bitDepth();
                           
                           
                            // Convert RGB or 8-bit images to 16-bit
            				if (imageType >= 16) {
                			run("16-bit");
            				}
                           
                            images = Array.concat(images, getTitle());
                        }
                    }
                }
        
	  // Build the merge command based on user-specified channel mappings
            mergeCommand = "";
            for (j = 0; j < images.length; j++) {
                mergeCommand += assignedSlots[j] + "=" + images[j] + " ";
            }
            
		// Finalize the merge command
		mergeCommand += "create";


        // Run the merge command
		run("Merge Channels...", mergeCommand);
        
        // Save the merged image
        saveAs("Tiff", outputDir + baseName + ".tif");

  		run("Stack to RGB");
        
		// Save the RGB version of the image in the RGB subfolder
		saveAs("Tiff", colorDir + baseName + "_" + colfolderName + ".tif");

        // Close everything
        close();
    }
}
}
}

// Function to check if an array contains a value
function arrayContains(array, value) {
    for (i = 0; i < array.length; i++) {
        if (array[i] == value) {
            return true;
        }
    }
    return false;
}

// Function to extract unique channel names from the files in the folder
function getUniqueChannels(fileList) {
    uniqueChannels = newArray();
    for (i = 0; i < fileList.length; i++) {
        if (endsWith(fileList[i], ".tif")) {
            underscoreIndex = lastIndexOf(fileList[i], "_");
            dotIndex = lastIndexOf(fileList[i], ".");
            if (underscoreIndex != -1 && dotIndex != -1 && dotIndex > underscoreIndex) {
                channelName = substring(fileList[i], underscoreIndex + 1, dotIndex); // Extract the channel name
                if (!arrayContains(uniqueChannels, channelName)) {
                    uniqueChannels = Array.concat(uniqueChannels, channelName); // Add to unique channels
                }
            }
        }
    }
    return uniqueChannels;
}