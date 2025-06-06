macro "Merge Separate Channels into 1" {

// written by Julia Kaiser, September 2024
// ---- takes a folder of tif files ending in _AF488, AF555, AF647, DAPI (e.g., from Axioscan) and
// ---- merges them into a 4-channel tif. 
// ---- If folder of multichannel images supplied, 
// Prompt the user to select the folder containing the TIF files

var dir = call("ij.Prefs.get", "input.x", 0);
var LUT = 0; // to add LUTs and save as subfolders instead of RGB, hidden function (aka will not be asked in dialog)

setBatchMode("hide");
list = getTiffFilesInDir(dir);
run("Close All"); 

isComposite = checkImageType(list);

if (isComposite) {
    open(dir + list[0]);
    getDimensions(width, height, channelsInImage, slices, frames);
    close();
    channels = newArray();
    for (i = 1; i <= channelsInImage; i++) {
        channels = Array.concat(channels, "c" + i);
    }
} else {
    channels = getUniqueChannels(list);
}

includeChannels = excludeChannelsDialog(channels);

// Assign colors to channels and get combined data
// Split combined data back into assignedColors and assignedSlots
assignedColors = newArray();
assignedSlots = newArray();

if (assignedColors.length == 0) {
    var combinedData = assignColorsToChannels(includeChannels);
	var assignedColors = Array.slice(combinedData, 0, combinedData.length / 2);
	var assignedSlots = Array.slice(combinedData, combinedData.length / 2, combinedData.length);
}


print("Assigned Channel - Colors: ");
 for (i = 0; i < assignedColors.length; i++) {
 	print("Channel " + includeChannels[i] + ": " +  assignedColors[i]);
 }


if (isComposite) {
    processCompositeImages(list, assignedColors, assignedSlots);
} else {
    processNonCompositeImages(list, assignedColors, assignedSlots);
}

print("Images merged and saved in subfolders");
waitForUser("Done!");
}

// Function to check whether the images are composite or not
function checkImageType(fileList) {
    for (i = 0; i < fileList.length; i++) {
        if (endsWith(fileList[i], ".tif")) {
            open(dir + fileList[i]);
            getDimensions(width, height, channels, slices, frames);
            close();
            if (channels > 1) {
                print("Composite image detected: " + channels + " channels.");
                return true;
            } else {
                print("Single channel images detected: Merge by suffix.");
                return false;
            }
        }
    }
    return false;
}

// Function to process composite images
function processCompositeImages(fileList, assignedColors, assignedSlots) {
    for (i = 0; i < fileList.length; i++) {
        if (endsWith(fileList[i], ".tif")) {
            open(dir + fileList[i]);
            run("Split Channels");

            imageTitles = getList("image.titles");
            images = newArray();

            for (j = 0; j < imageTitles.length; j++) {
                selectWindow(imageTitles[j]);
                convertTo16Bit(); 
                title = imageTitles[j];

                for (c = 1; c <= channelsInImage; c++) {
                    channelLabel = "c" + c; 
                    if (startsWith(title, "C" + c) && arrayContains(includeChannels, channelLabel)) {
                        images = Array.concat(images, title); 
                        break; 
                    }
                }

                // If the title doesn't match any included channels, close the window
                if (!arrayContains(images, title)) {
                    selectWindow(title);
                    close();
                }
            }

            // Proceed to merge only if there are images to process
            if (images.length > 0) { 
                mergeImages(images, assignedColors, assignedSlots);
            }
        }
    }
}

// Function to process non-composite images
function processNonCompositeImages(fileList, assignedColors, assignedSlots) {
    uniqueNames = newArray();
    for (i = 0; i < fileList.length; i++) {
        if (endsWith(fileList[i], ".tif")) {
            baseName = getBaseName(fileList[i]);
            if (!arrayContains(uniqueNames, baseName)) {
                uniqueNames = Array.concat(uniqueNames, baseName);
                // Open the corresponding images for each non-excluded channel
                images = newArray();
		        for (j = 0; j < channels.length; j++) {
		        	if (arrayContains(includeChannels, channels[j])) {
		                 fileName = dir + baseName + "_" + channels[j] + ".tif";
		                        if (File.exists(fileName)) {
		                            open(fileName);
		                            convertTo16Bit(); 
		                            images = Array.concat(images, getTitle());
		                        }
		                    }
		                }
		               
		                if (images.length > 0) { 
		                    mergeImages(images, assignedColors, assignedSlots);
		                }
		                
		            }
		        }
    }
}

// Function to allow the user to exclude channels
function excludeChannelsDialog(channels) {
    Dialog.create("Exclude Channels");
    for (i = 0; i < channels.length; i++) {
        Dialog.addCheckbox("Exclude " + channels[i], false);
    }
    Dialog.show();
    
    includeChannels = newArray();
    for (i = 0; i < channels.length; i++) {
        result = Dialog.getCheckbox();
        if (result == 0) {
            includeChannels = Array.concat(includeChannels, channels[i]); 
        } else {
        	print("Excluding Channel " + channels[i]);
        }
    }
    return includeChannels;
}

// Function to assign colors to channels
function assignColorsToChannels(includeChannels) {
    var assignedColors = newArray(); 
    var assignedSlots = newArray(); 

    Dialog.create("Assign channels to colors");
    Dialog.addMessage("Assign channels to colors");
    Dialog.addMessage("R (red), G (green), B (blue), Gr (grey), C (cyan), M (magenta), Y (yellow)");
    var colorMapping = newArray("R", "G", "B", "Gr", "C", "M", "Y"); 
    var colorSlotMapping = newArray("c1", "c2", "c3", "c4", "c5", "c6", "c7"); 

    // Populate the dialog with the color options for each image
for (i = 0; i < includeChannels.length; i++) {
    colorIndex = i;  // Ensure we're cycling through colorMapping
    if (colorIndex >= colorMapping.length) {
        colorIndex = colorIndex - colorMapping.length; // Cycle back to the start of the colorMapping array
    }
    Dialog.addChoice(includeChannels[i], colorMapping, colorMapping[colorIndex]); // Assign default color cycling through RGB
}

    Dialog.show();

    for (var i = 0; i < includeChannels.length; i++) {
        var selectedColor = Dialog.getChoice(); 
        assignedColors = Array.concat(assignedColors, selectedColor); // Store color selection

        for (var j = 0; j < colorMapping.length; j++) {
            if (selectedColor == colorMapping[j]) {
                assignedSlots = Array.concat(assignedSlots, colorSlotMapping[j]); // Assign correct slot
                break; 
            }
        }
    }
    
    // Combine the two arrays into one
    var combinedData = Array.concat(assignedColors, assignedSlots);
    return combinedData; // Return the combined array
}


// Function to merge images after collecting channels
function mergeImages(images, assignedColors, assignedSlots) {
    if (assignedSlots.length == 0 || assignedColors.length == 0) {
        print("No images to merge. Exiting function.");
        return; 
    }

	// make foldername by color choices. could also use includedChannels
   	slotFolderName = "";
    for (i = 0; i < assignedColors.length; i++) {
        slotFolderName += assignedColors[i]; 
    }
 	outputDir = dir + slotFolderName + "/";
    File.makeDirectory(outputDir);

    mergeCommand = "";
    for (i = 0; i < images.length; i++) {
        mergeCommand += assignedSlots[i] + "=" + images[i] + " ";  
    }
    mergeCommand += "create";

    run("Merge Channels...", mergeCommand);
    filename = getBaseName(images[1]);
    saveAs("Tiff", outputDir + filename + ".tif");
    
    getDimensions(width, height, channels, slices, frames);
    if(channels > 1) { 
    	colorDir = outputDir + "RGB" + "/";
    	File.makeDirectory(colorDir);
    	run("Stack to RGB"); 
    	saveAs("Tiff", colorDir + filename + ".tif");
    run("Close All");
    } else {
    	if(LUT==1) {
    	
    	run("Invert"); // this inverts colors
    	
    	name = getTitle();
    	saveimg = replace(substring(name,3,lengthOf(name)),".tif","");
    	
//    	//save as grey
//    	colorDir = outputDir + "Invert" + "/";
//    	File.makeDirectory(colorDir);
//    	
//    	run("Duplicate...", " ");
//    	run("RGB Color");
//    	saveAs("Tiff", colorDir + saveimg + ".tif");
//    	close;
//    	
//    	//save as 16 color LUT
//    	colorDir = outputDir + "thallium" + "/";
//    	File.makeDirectory(colorDir);
//    	
//    	run("Duplicate...", " ");
//    	run("thallium");
//    	run("RGB Color");
//    	saveAs("Tiff", colorDir + saveimg + ".tif");
//    	close;
//    	    	
    	//save as 16 color LUT
    	run("Duplicate...", " ");
    	//setMinAndMax(0, 41727); // just for M1, this should reduce the background
    	
    	run("16 colors");
    	run("RGB Color");
    	
    	colorDir = outputDir + "16col" + "/";
    	File.makeDirectory(colorDir);
    	
    	saveAs("Tiff", colorDir + saveimg + ".tif");
    	
    	run("Close All");
    	} else {
    	name = getTitle();
    	saveimg = replace(substring(name,3,lengthOf(name)),".tif","");
    	
    	//save as grey
    	colorDir = outputDir + "RGB" + "/";
    	File.makeDirectory(colorDir);
    	run("RGB Color");
    	saveAs("Tiff", colorDir + saveimg + ".tif");
    	close;
    	}
    	

    }

}

// Function to extract unique channel names from the files in the folder
function getUniqueChannels(fileList) {
    uniqueChannels = newArray();
    
    for (i = 0; i < fileList.length; i++) {
        if (endsWith(fileList[i], ".tif")) {
            underscoreIndex = lastIndexOf(fileList[i], "_");
            dotIndex = lastIndexOf(fileList[i], ".");
            if (underscoreIndex != -1 && dotIndex != -1 && dotIndex > underscoreIndex) {
                channelName = substring(fileList[i], underscoreIndex + 1, dotIndex); 
                if (!arrayContains(uniqueChannels, channelName)) {
                    uniqueChannels = Array.concat(uniqueChannels, channelName); 
                }
            }
        }
    }
    return uniqueChannels;
}

// Helper function to check if an array contains a value
function arrayContains(array, value) {
    for (i = 0; i < array.length; i++) {
        if (array[i] == value) {
            return true;
        }
    }
    return false;
}

// Helper function to get base name from a filename
function getBaseName(filename) {
    underscoreIndex = lastIndexOf(filename, "_");
    return substring(filename, 0, underscoreIndex);
}

// Function to check the image type and convert to 16-bit if necessary
function convertTo16Bit() {
     // Convert to 16bit (if 8bit, or if RGB = 24 bit)
    if (bitDepth() != 16) {
        run("16-bit");
    }
    
    // Apply the grayscale lookup table for proper display.
    run("Grays");

}

// Function to get all .tif files directly in the selected folder (exclude subfolders)
function getTiffFilesInDir(dir) {
    fileList = getFileList(dir);  

    filteredFiles = newArray();
    for (i = 0; i < fileList.length; i++) {
        if (!File.isDirectory(dir + fileList[i]) && endsWith(fileList[i], ".tif")) {
            filteredFiles = Array.concat(filteredFiles, fileList[i]); 
        }
    }
    return filteredFiles;  
}
