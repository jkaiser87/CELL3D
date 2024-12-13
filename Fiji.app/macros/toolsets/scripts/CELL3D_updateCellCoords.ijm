macro "redo cell coordinates" {
	
//run this script if you want to adjust the coordinates again

var input = call("ij.Prefs.get", "input.x",0);
//input = input + "Slices" + File.separator; 

 Dialog.create("Setup");
 Dialog.addMessage("Select the Channel to count cells: \nC1 (red), C2 (green), C3 (blue), C4 (farred)");
 items = newArray("C1", "C2", "C3","C4");
 Dialog.addRadioButtonGroup("", items, 1, 4, "C1");
 Dialog.show;
 
 var channelc = Dialog.getRadioButton();
 var channelno = parseFloat(replace(channelc, "C","")); //extracts number of channel for later


print("\nFine-tuning coordinates of selected cells \n --- Processing folder "+input+"\n --- Processing channel "+channelc);

list = getFileList(input);
suffix = ".tif";

//opens all tools
run("Channels Tool...");
run("Brightness/Contrast...");
run("ROI Manager...");


// Process each subfolder under the input directory
    var animalFolders = getFileList(input);
    
    for (var i = 0; i < animalFolders.length; i++) {
        var subFolderPath = input + animalFolders[i] + File.separator;
                
        if (File.isDirectory(subFolderPath)) {
            print("Processing folder: " + subFolderPath);
            //createDirectories(subFolderPath);
            processFolder(subFolderPath);
        }
    }
    
    
run("Close All");

showMessage("Done", "Coordinates adjusted for "+channelc+".\nIf you want to process another channel, rerun this part and select another channel.");
}


function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix))
			processFile(input, list[i]);
	}
}

function processFile(input, file) {
	
var savepath = input + File.separator;
var zipPath =  savepath + "ZIP";	
var csvPath =  savepath + "CSV";

print(" -- Processing file "+file);
open(input+file);
rename(file);

run("Remove Overlay");
run("Select None");

ROIs = roiManager("count");
if (ROIs >0) {
roiManager("Deselect");
roiManager("Delete");
}

//remove scale otherwise particle analysis returns in inches
run("Set Scale...", "distance=0 known=0 unit=pixel");

if(!File.exists(zipPath+File.separator+channelc+"_"+replace(file,".tif",".zip"))) {	
	print("--- No coordinates exist, re-run cell detection first on file "+file);
	close();
} else {
roiManager("Open", zipPath+File.separator+channelc+"_"+replace(file,".tif",".zip"));
run("Point Tool...", "type=Cross color=Red size=[Extra Large] label show counter=0");
setTool("multipoint");
roiManager("Select",0);

waitForUser("Action required", "Adapt the ROI selection as necessary: \n -- Delete with Shift + Click, \n -- Add by clicking, \n -- press [ok] here when done. \n\n if no cells present, delete selection+ROI using the pen button in toolset");
type = selectionType();

// add selection to ROI manager if available.
ROIs = roiManager("count");
if (ROIs >0) {
roiManager("Deselect");
roiManager("Delete");
}


if (type ==-1) {
	//if selection empty bc no cells, we still want there to be a ZIP file bc we want the script to know that we looked at this file already. 
	//saving random cell at 1,1. will delete this later in MATLAB
	makePoint(1,1);	
	roiManager("add");
} else if (type==10) {
	  roiManager("Add");  
} else {
      print("Wrong selection. Re-run script and only add cell selection using multipoint tool.");
}

ROIs = roiManager("count");
if (ROIs>0) {
roiManager("save", zipPath+File.separator+channelc+"_"+replace(file,".tif",".zip")); //at the moment i dont want to save it as seperate channels, just one
print(" --- ZIP saved as "+zipPath+File.separator+channelc+"_"+replace(file,".tif",".zip"));	
	  
//saving as csv
	  	  
roiManager("select", 0);
getSelectionCoordinates(xpoints, ypoints);
run("Clear Results");
for (f=0; f<xpoints.length; f++) {
	setResult("Label", f, file);
    setResult("X", f, xpoints[f]);
    setResult("Y", f, ypoints[f]);
}
updateResults();

saveAs("Measurements", csvPath+File.separator+channelc+"_"+replace(file,".tif",".csv")); 
print(" --- CSV saved as "+csvPath+File.separator+channelc+"_"+replace(file,".tif",".csv"));	
	  
run("Clear Results");
run("Close All");

} else {
showMessage("Something went wrong. ROI not added. HELP.");
}


}}