macro "Mark CSN Action Tool - icon:neuron.png"{

 var input = call("ij.Prefs.get", "input.x",0);
 //input += "Slices/"; //slice files in subfolder, adding trailing / 
 
 Dialog.create("Setup");
 Dialog.addMessage("Select the Channel to count cells: \nC1 (red), C2 (green), C3 (blue), C4 (farred)");
 items = newArray("C1", "C2", "C3","C4");
 Dialog.addRadioButtonGroup("", items, 1, 4, "C1");
 Dialog.addNumber("Initial threshold for cell detection (0-255):", 150);
 Dialog.addNumber("Initial particle size for cell detection:", 50);
 Dialog.show;
 
 var channelc = Dialog.getRadioButton();
 var channelno = parseFloat(replace(channelc, "C","")); //extracts number of channel for later
 var thresh = Dialog.getNumber();
 var parsize = Dialog.getNumber();
 
 call("ij.Prefs.set", "thresh.x",thresh);//save thresh to defaults to access in other scripts
 call("ij.Prefs.set", "channelno.x",channelno);//save channelno to defaults to access in other scripts

print("\nMarking neurons semi-automatically \n -- Processing folder "+input+"\n -- Processing Channel "+channelc);
print("--- Threshold set to "+thresh+" (corresponds to 8bit, may be converted)");

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
showMessage("Done", "All slices processed for Channel "+channelc+".\nIf you want to process another channel, rerun this part and select another channel.");


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
	
if(File.exists(zipPath+File.separator+channelc+"_"+replace(file,".tif",".zip"))) {		
	print(" !! "+file+ " previously processed, skipping. \n --- Delete this file to re-do: "+zipPath+File.separator+channelc+"_"+replace(file,".tif",".zip"));
} else {

ROIs = roiManager("count");
if (ROIs >0) {
roiManager("Deselect");
roiManager("Delete");
}
run("Clear Results");

print(" -- Processing file "+file);
open(input+file);  
rename(file);

run("Hide Overlay");
run("Brightness/Contrast...");
run("ROI Manager...");

roiManager("Show All");

//make composite
run("Make Composite", "display=Composite");
Stack.setDisplayMode("color");
Stack.setChannel(channelno);
run("Grays");

//try automated way of detecting neurons

run("Set Measurements...", "centroid limit display redirect=None decimal=3");
print(" --- Duplicating channel "+channelc);
run("Duplicate...", "duplicate channels="+channelno);
setAutoThreshold("Default dark");

//if 16bit convert to 8bit
bit = bitDepth();
if(bit == 16) {
	run("8-bit");
}

print(" --- Thresholding at "+thresh);

setThreshold(thresh, 255, "raw");
run("Convert to Mask");
run("Watershed");
run("Fill Holes");

//remove scale otherwise particle analysis returns in inches
run("Set Scale...", "distance=0 known=0 unit=pixel");

print("-- Particle analysis: ["+parsize+"-infinity pixel, measure]");

run("Analyze Particles...", "size="+parsize+"-Infinity pixel show=Outlines display clear");

// if particle analysis is NOT empty
if(nResults!=0) {
	
xpoints = newArray(nResults);
ypoints = newArray(nResults);

for(p=0; p<nResults; p++) {
	xpoints[p]+ = getResult("X",p);
	ypoints[p]+ = getResult("Y",p);
}

selectWindow(file);
close("\\Others");
run("Set Scale...", "distance=0 known=0 unit=pixel");

ROIs = roiManager("count");
if (ROIs >0) {
roiManager("Deselect");
roiManager("Delete");
}

run("Select None");
print(" --- Particle analysis successful, adding points as selection.");
makeSelection("Point", xpoints, ypoints);
roiManager("add");
roiManager("Select",0);
setTool("multipoint");
run("Properties... ", "stroke=red point=Hybrid size=Large");
waitForUser("Action required", "Adapt the ROI selection as necessary: \n -- Delete with Shift + Click, \n -- Add by clicking, \n -- press [ok] here when done. \n\n if no cells present, delete selection+ROI using the pen button in toolset");

} else { // if thresholding didnt give any results and particle analysis empty

print(" !! Particle Analysis empty, manual selection necessary.");
selectWindow(file);
close("\\Others");

run("Select None");
setTool("multipoint");
run("Point Tool...", "type=Cross color=Red size=[Extra Large] label show counter=0");
waitForUser("Action required", "Manually add selection. If no cells present, click ok");
}

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


//either way, semi automatic or manual, we should now have a selection of cells (or 1,1 point if no cells present) - now saving

// add sanity check that ROI is not empty?
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

var csvPath =  savepath + "CSV";
saveAs("Measurements", csvPath+File.separator+channelc+"_"+replace(file,".tif",".csv")); 
print(" --- CSV saved as "+csvPath+File.separator+channelc+"_"+replace(file,".tif",".csv"));	
	  
run("Clear Results");
run("Close All");



} else {
showMessage("Something went wrong. ROI not added. HELP.");
}


run("Clear Results");
run("Close All");



/*
// Old way to save as csv
ROIs = roiManager("count");

//converts full selection into single points to save as cvs
array=newArray();
for(f=0;f<ROIs;f++){
array[f]=f;
}

roiManager("select", array);
roiManager("Measure");

if(nResults != 0) { 
		saveAs("Measurements", output_csv+File.separator+replace(file,".tif",".csv")); 
//	saveAs("Measurements", output_csv+File.separator+channelc+"_"+replace(file,".tif",".csv")); 
	print("-- "+channelc+" - "+replace(file,".tif",".csv")+ " saved in folder "+output_csv);
} else {
	saveAs("Measurements", output_csv+File.separator+replace(file,".tif",".csv")); 
	//saveAs("Measurements", output_csv+File.separator+channelc+"_"+replace(file,".tif",".csv")); 
	print("-- "+channelc+" - "+file+ " did not have a selection, CVS saved with 1 point at [1,1]");	
}
*/
run("Clear Results");


}
}

/// functions

function createDirectories(subFolderPath) {
    var subfolders = newArray("VOL", "VOL" + File.separator + "CSV","VOL" + File.separator + "ZIP");
	for (ff = 0; ff < subfolders.length; ff++) {
			subsub = subFolderPath + File.separator + subfolders[ff];
			File.makeDirectory(subsub);
 			if (!File.exists(subsub))
 			 exit("Unable to create directory "+subsub);
		}
}