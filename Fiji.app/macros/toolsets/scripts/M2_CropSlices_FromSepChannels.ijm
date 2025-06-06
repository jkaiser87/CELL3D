macro "Crop Slide Action Tool - icon:crop.png"{
// merge image from single channels, collect ROI and split and saves them individually

var input = call("ij.Prefs.get", "input.x",0);

list = getFileList(input);
suffix = ".tif";
setBatchMode("hide");

print("Cropping Images in folder \n"+input);
run("Channels Tool...");
run("ROI Manager...");
roiManager("Show All with labels");

//making folders etc 
subfolders = newArray("Slices", "Stack", "ROIs","Stack\\RGB");
for (i = 0; i < subfolders.length; i++) {
subfolderPath = input + File.separator + subfolders[i];
File.makeDirectory(subfolderPath);
 if (!File.exists(subfolderPath))
  exit("Unable to create directory");
}
  
animalNames = newArray();
    for  (i=0; i<list.length; i++) {
        if (endsWith(list[i], suffix)) {
            animalName = getAnimalName(list[i]);
            if (indexOfArray(animalNames, animalName) == -1) {
                animalNames = Array.concat(animalNames, animalName);
                animalFolder = input + File.separator + "Slices" + File.separator + animalName;
                File.makeDirectory(animalFolder);
            }
        }
    }    

//get file list (without channel addition)
titles = newArray();  
for  (i=0; i<list.length; i++) {
	if (endsWith(list[i], suffix)) {
		baseName = replace(list[i], "_Ch.*$", ""); 
    	titles = Array.concat(titles,baseName);
}}
filelist = unique(titles); //single occurances of image names (deletes _ch01 etc)

processFolder(input);

waitForUser("--- Slices have been stored in the subfolder 'Slices'.");	
}

function processFolder(input) {
	for(ii=0; ii<filelist.length; ii++) { 
		processFile(input, subfolders, filelist[ii]);
	}
}

function processFile(input, subfolders, file) {

if(File.exists(input+File.separator+subfolders[1]+File.separator+file+".tif")) {	
print("--- File "+file+ " previously processed, skipping \n ---- Delete file in Stack folder if you want to re-do this file.");
//open(input+"\\"+file+".tif"); // uncomment line if you want to redo the slices
} else {

print("Processing file "+file);
run("Close All");


// Get a list of files with the same base name (check for _Ch0X)
matchingFiles = newArray();
hasSplitChannels = false;

for (j = 0; j < list.length; j++) {
    if (startsWith(list[j], file)) {
        if (matches(list[j], ".*_Ch0\\d\\.tif$")) {
            hasSplitChannels = true;
        }
        matchingFiles = Array.concat(matchingFiles, list[j]);
    }
}

// opens files and creates merging command
if (hasSplitChannels) {
    print("--- Merging " + matchingFiles.length + " channels");
    
    for (m = 0; m < matchingFiles.length; m++) {
        open(input + matchingFiles[m]);
        rename(matchingFiles[m]); // normalize name
        if (bitDepth() > 16) run("16-bit");
        
        if (m == 0) {
            mergeCommand = " c" + (m + 1) + "=" + matchingFiles[m];
        } else {
            mergeCommand += " c" + (m + 1) + "=" + matchingFiles[m];
        }
    }

    mergeCommand += " create";
    run("Merge Channels...", mergeCommand);
   
} else {
    print("--- No split channels found, assuming merged composite.");
    open(input + file + ".tif");
}
    if (!is("composite")) run("Make Composite", "display=Composite");
    rename(file);


ROIs = roiManager("count");
if (ROIs >0) {
roiManager("Deselect");
roiManager("Delete");
}
setTool("rectangle");

setBatchMode("exit and display");
if(File.exists(input+File.separator+subfolders[2]+File.separator+file+".zip")) {
	roiManager("Open",input+File.separator+subfolders[2]+File.separator+file+".zip");
	//waitForUser("Action","Make any changes necessary to the ROI");
} else {
	waitForUser("Action","Select all slices that you want to export from front to back of brain.\nPress [t] after every square placed.\n\nTo flip a section horizontally, press F (Shift+f) after square is placed. \n\nDO NOT PRESS OK UNTIL THE LAST SLICE HAS A SQUARE AROUND IT!");
}
roiManager("save", input+File.separator+subfolders[2]+File.separator+file+".zip");

setBatchMode("hide");

//select each subset, duplicate, save
ROIs = roiManager("count");
print(" --- Saving "+ROIs+" slices into folder "+subfolders[0]);
for (s = 0; s < ROIs; s++) {
roiManager("Select",s);
run("Duplicate...", "duplicate");
slicenr = s+1;
subfolderAnimal = getAnimalName(file);
saveAs("Tiff",input+File.separator+subfolders[0]+File.separator+subfolderAnimal+File.separator+file+"_s"+String.pad(slicenr,3)+".tif");
close();
}

//lastly, saving stack as tif, which also serves to check if this file has been processed already
selectWindow(file);
print(" --- Saving Stack as "+subfolders[1]+"\\"+file+".tif");
saveAs("Tiff",input+File.separator+subfolders[1]+File.separator+file+".tif");

print(" --- Saving as RGB overview in "+subfolders[3]+File.separator+file+".jpg");
run("Stack to RGB");
saveAs("JPEG",input+File.separator+subfolders[3]+File.separator+file+".jpg");

run("Close All");
}


run("Close All");
run("Collect Garbage");
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
  
  
function unique(array) {
	uniquearray = newArray(); //return array

    count=0;
     //first loop to get the value of the initial array
	for (a=0; a<lengthOf(array); a++) {
    	value = array[a];

    //second loop to check if this value already exists in the new return array
		for (b=0; b<lengthOf(uniquearray); b++) {
        	if (uniquearray[b]==value) count++;
		}

		//if doesnt exist -> add, if it does exist, reset counter
        if (count==0) {
		uniquearray = Array.concat(uniquearray,value);
		}
		
		else {
			count=0;
		}
		}
	
	//return array
	return uniquearray;
}
	
// Returns the index of the first occurrence of value in array or -1 if not found
function indexOfArray(array, value) {
    for (a = 0; a < lengthOf(array); a++) {
        if (array[a] == value) {
            return a; // Return the index where the value is found
        }
    }
    return -1; // Return -1 if the value is not found
}
 


function getAnimalName(filename) {
    parts = split(filename, "_");
    return parts[0];
}