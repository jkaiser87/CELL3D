macro "Setup Count Tool - D16D17D23D26D27D2aD32D33D34D35D36D37D38D39D3aD3bD43D44D45D46D47D48D49D4aD53D54D55D58D59D5aD61D62D63D64D69D6aD6bD6cD71D72D73D74D79D7aD7bD7cD83D84D85D88D89D8aD93D94D95D96D97D98D99D9aDa2Da3Da4Da5Da6Da7Da8Da9DaaDabDb3Db6Db7DbaDc6Dc7CcccD22D24D29D2bD42D4bD56D57D65D68D75D78D86D87D92D9bDb2Db4Db9Dbb"{

var input = call("ij.Prefs.get", "input.x",0);

//input = input + File.separator + "/Slices/";
print("\nPre-Processing of slices in folder "+input);

//input = getDirectory("Choose Folder with Single TIF slices (subfolder 'Slices' created in previous step)");
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
            print(" -- Processing folder: " + subFolderPath);
            createCoordDirectories(subFolderPath);
            processFolder(subFolderPath);
        }
    }

    showMessage("Done", "All slices pre-processed. \nYou can now continue to the next step of labeling SCPN.");
}


}


function processFolder(input) {
    var list = getFileList(input);
    list = Array.sort(list);
    for (var k = 0; k < list.length; k++) {
        if (endsWith(list[k], ".tif")) {
            processFile(input, list[k]);
        }
    }
}


function processFile(input, file) {
print(" -- Processing file " + file);
open(input+file);

getDimensions(width, height, channels, slices, frames);
if(height>width) {
              run("Rotate 90 Degrees Right"); 
}

run("Enhance Contrast", "saturated=0.35");

//rotate to midline
setTool("line");
waitForUser("Action required", "Make a line through the midline \n START AT TOP and go to bottom! \nMake no selection to skip rotating this image (del with Ctrl+Shift+A)");

if(selectionType()!= -1) {
if (selectionType!=5)
      exit("Straight line selection required");
      getLine(x1, y1, x2, y2, lineWidth);

      angle = getAngle(x1, y1, x2, y2);
	  RotateAngle = angle + 90;
		run("Arbitrarily...", "angle="+RotateAngle+" interpolate");

//save image to save rotation
	
	print(" --- Saving rotated file "+file);
	run("Select None");
	run("Save");
}

// get coordinates for midline and outside left and right
ROIs = roiManager("count");
if (ROIs >0) {
roiManager("Deselect");
roiManager("Delete");
}

//set and rename points
setTool("point");
waitForUser("Action required", "Select the left-most point of the left cortex");
run("Properties... ", "name=[LEFT CTX] stroke=red");
roiManager("Add");

waitForUser("Action required", "Select the Midline right where the tissue meets on the top");
run("Properties... ", "name=[MIDLINE] stroke=red");
roiManager("Add");

waitForUser("Action required", "Select the right-most point of the right cortex");
run("Properties... ", "name=[RIGHT CTX] stroke=red");
roiManager("Add");

saveCoordData(input, file);

run("Close All");
}

function saveCoordData(input, file) {
    
    //save coord roi as zip
	var zipPath = input + "ZIP\\COORD" + File.separator + replace(file, ".tif", ".zip");
	roiManager("save", zipPath);
	
	//save as csv
	ROIs = roiManager("count");
	array=newArray();
	for(f=0;f<ROIs;f++){
	array[f]=f;
	}

	//remove scale otherwise particle analysis returns in inches
	run("Set Scale...", "distance=0 known=0 unit=pixel");
	
	roiManager("select", array);
	roiManager("Measure");
	var csvPath = input + "CSV\\COORD"+File.separator+replace(file,".tif",".csv"); 
	saveAs("Measurements", csvPath);
	run("Clear Results");
	print(" --- Coordinates saved as ZIP and CSV files");
}


function createCoordDirectories(subFolderPath) {
    var subfolders = newArray("ZIP", "ZIP" + File.separator + "COORD", "CSV","CSV" + File.separator + "COORD");
	for (ff = 0; ff < subfolders.length; ff++) {
			animalsub = subFolderPath + File.separator + subfolders[ff];
			File.makeDirectory(animalsub);
 			if (!File.exists(animalsub))
 			 exit("Unable to create directory");
		}
}

// Returns the angle in degrees between the specified line and the horizontal axis.
  function getAngle(x1, y1, x2, y2) {
      q1=0; q2orq3=2; q4=3; //quadrant
      dx = x2-x1;
      dy = y1-y2;
      if (dx!=0)
          angle = atan(dy/dx);
      else {
          if (dy>=0)
              angle = PI/2;
          else
              angle = -PI/2;
      }
      angle = (180/PI)*angle;
      if (dx>=0 && dy>=0)
           quadrant = q1;
      else if (dx<0)
          quadrant = q2orq3;
      else
          quadrant = q4;
      if (quadrant==q2orq3)
          angle = angle+180.0;
      else if (quadrant==q4)
          angle = angle+360.0;
      return angle;
      
  }
  