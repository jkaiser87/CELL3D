// Cell Count Analysis tools

macro "Unused Tool-1 - " {}  // leave empty slot

macro "Flip image [F]"{
	run("Flip Horizontally");
    print ("--- Selection flipped.");
}

macro "Setup Folder to process Action Tool - icon:folder.png" {
  
  var defaultPath = call("ij.Prefs.get", "input.x",0); //retrieve last input?
  
  Dialog.create("Setup");
  Dialog.addMessage("Choose folder 'Slices' from M2 CropSlide pipeline");
  Dialog.addDirectory("\n", defaultPath)
  Dialog.show;
  
  var input = Dialog.getString();
  if (!endsWith(input, File.separator)) {
      input += File.separator;
	}
  
print("\nPipeline to obtain cell coordinates from single coordinates. \n! Input folder: \n"+input);
call("ij.Prefs.set", "input.x", input); //finally sets input as global variable

}

macro "Preprocess Slices Action Tool - icon:imageproc.png"{
 runMacro(getDirectory("macros")+"//toolsets//scripts//CELL3D_SetupSlices.ijm");
}

macro "Mark CSN Action Tool - icon:neuron.png"{
 runMacro(getDirectory("macros")+"//toolsets//scripts//CELL3D_CountCells_channeldep.ijm");
}

macro "Delete All (ROI and Selection) Tool - icon:DeleteAll.png" {
roiManager("deselect");
roiManager("delete");
run("Select None");	
run("Set Scale...", "distance=0 known=0 unit=pixel");
setTool("multipoint");
run("Point Tool...", "type=Hybrid color=Red size=[Large] label show counter=0");
print("--- ROI and selection deleted. \n Use selection tool to add cells if necessary");
}


macro "Set new threshold for cell selection Tool - icon:Rethreshold.png" {

run("Select None");	
ROIs = roiManager("count");
if (ROIs >0) {
roiManager("Deselect");
roiManager("Delete");
}

file = getTitle();
var thresh = call("ij.Prefs.get", "thresh.x", 150); //get saved thresh
var channelno = call("ij.Prefs.get", "channelno.x", 1); //get saved thresh

print(" --- !! Manually re-thresholding "+file);

run("Set Measurements...", "centroid limit display redirect=None decimal=3");
run("Threshold...");
run("Duplicate...", "duplicate channels="+channelno);
setAutoThreshold("Default dark");

bit = bitDepth();
if(bit == 16) {
	run("8-bit");
} 

setThreshold(thresh, 255, "raw");
Threshold = getNumber("Re-threshold to... (higher number = less detected)", thresh);

setThreshold(Threshold, 255, "raw");
run("Convert to Mask");
run("Watershed");
run("Fill Holes");

//remove scale otherwise particle analysis returns in inches
run("Set Scale...", "distance=0 known=0 unit=pixel");
// this already measures the centroids of what it recognizes

print(" --- re-running Particle analysis");
run("Analyze Particles...", "size=50-Infinity pixel show=Outlines display clear");

//add selection to an array
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
setTool("multipoint");
run("Point Tool...", "type=Cross color=Red size=[Extra Large] label show counter=0");
makeSelection("Point", xpoints, ypoints);
run("Properties... ", "stroke=red point=Hybrid size=Large");
roiManager("add");
roiManager("Select",0);

resetThreshold();

}

macro "Delete in Selection Area Action Tool - icon:DeleteInsideSelection.png"{
	// to check coordinates again run this
 runMacro(getDirectory("macros")+"//toolsets//scripts//CELL3D_DeteleInSelectionArea.ijm");
}


macro "Delete Outside Selection Area Action Tool - icon:DeleteOutsideSelection.png"{
	// to check coordinates again run this
 runMacro(getDirectory("macros")+"//toolsets//scripts//CELL3D_DeteleOutsideSelectionArea.ijm");
}


macro "Cleanup on Aisle Neuron Action Tool - icon:clean.png"{
	// to check coordinates again run this
 runMacro(getDirectory("macros")+"//toolsets//scripts//CELL3D_updateCellCoords_ByAnimal.ijm");
}


/*
 * 
 macro "Abort Macro or Plugin (or press Esc key) Action Tool - CbooP51b1f5fbbf5f1b15510T5c10X" {
      setKeyDown("Esc");
}
*/

