macro "redo coordinates" {

// this script runs through all coordinates (left/mid/right) again to make sure its in pixel not inches

var input = call("ij.Prefs.get", "input.x",0);
var channelc = call("ij.Prefs.get", "channelchoice.x",0);
var channelno = call("ij.Prefs.get", "channelno.x",0);
var filesort = call("ij.Prefs.set", "filesort.x", filesort);

if(filesort=="no") input = input + File.separator + "/Slices/";

print("Redo Coordinates of Images \n--- Processing folder "+input+"\nProcessing channel "+channelc);
run("Set Measurements...", "centroid limit display redirect=None decimal=3");

list = getFileList(input);
suffix = ".tif";

//opens all tools
run("Channels Tool...");
run("Brightness/Contrast...");
run("ROI Manager...");

//save coordinates as roi
output1 = input+"ZIP"+File.separator;
File.makeDirectory(output1);
 if (!File.exists(output1))
  exit("Unable to create directory");

output2 = output1+"COORD"+File.separator;
File.makeDirectory(output2);
 if (!File.exists(output2))
  exit("Unable to create directory");

//also save directly as CSV
output_csv = input + File.separator + "CSV";
File.makeDirectory(output_csv);
if (!File.exists(output_csv))
  exit("Ooops");

output_csv2 = output_csv + File.separator + "COORD";
File.makeDirectory(output_csv2);
if (!File.exists(output_csv2))
  exit("Ooops");

run("Close All");

processFolder(input);

showMessage("Done", "Coordinates re-counted. To redo certain files, delete the coord csv files (NOT the zip!).");

}


function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(endsWith(list[i], suffix))
			processFile(input, output1, list[i]);
	}
}

function processFile(input, output, file) {
if(!File.exists(output_csv2+File.separator+replace(file,".tif",".csv"))) {		
setBatchMode("hide");
print("Processing file "+file);
open(input+file);

// get coordinates for midline and outside left and right
ROIs = roiManager("count");
if (ROIs >0) {
roiManager("Deselect");
roiManager("Delete");
}

//remove scale otherwise particle analysis returns in inches
run("Set Scale...", "distance=0 known=0 unit=pixel");

if(File.exists(output2+File.separator+replace(file,".tif",".zip"))) {	
	roiManager("Open", output2+File.separator+replace(file,".tif",".zip"));

} else {
setBatchMode("show");
//set and rename points
setTool("point");
waitForUser("Action required", "Select the left-most point of the left cortex");
roiManager("Add");
last = roiManager("count");
roiManager("select", last-1);
roiManager("Rename", "LEFT CTX");
waitForUser("Action required", "Select the Midline right where the tissue meets on the top");
roiManager("Add");
last = roiManager("count");
roiManager("select", last-1);
roiManager("Rename", "MIDLINE");
waitForUser("Action required", "Select the right-most point of the right cortex");
roiManager("Add");
last = roiManager("count");
roiManager("select", last-1);
roiManager("Rename", "RIGHT CTX");

//save roi
roiManager("save", output2+File.separator+replace(file,".tif",".zip"));
}

//save as csv
ROIs = roiManager("count");
array=newArray();
for(f=0;f<ROIs;f++){
array[f]=f;
}

roiManager("select", array);
roiManager("Measure");
saveAs("Measurements", output_csv2+File.separator+replace(file,".tif",".csv")); 
run("Clear Results");
print(" --- Coordinates saved");

run("Close All");
}}