macro "Delete Outside Selection Area" {

	ogimg = getTitle();
    // ----- Step 1: Get coordinates of old selection and clear ROI manager -----
    getSelectionCoordinates(x, y);
    n = lengthOf(x);
    if (n < 1) {
        showMessage("No Selection", "This tool only works on a dot selection.");
        return;
    }
    
 	run("Add Selection..."); //adds selection to overlay so we can still see when we draw area
    run("Select None");
    roiManager("reset"); //delets original ROI
     
    // ----- Step 2: Select deletion area and convert to Mask -----
    // Prompt the user to draw the area that defines the deletion zone.
    //setTool("rectangle");
    setTool("freehand");
    //showMessage("Action required", "Draw Area in which points should be KEPT, \npress 't' to add to ROI Manager, which will continue script");
    //cannot use waitforuser because its already active
    print("!-- Draw Area in which points should be KEPT in.");
    print("!-- Press [t] to add the area to ROI the  Manager, which will continue script");
    
    // ----- Step 3: Poll until a deletion ROI is available and then create mask from it ---
       
   // Poll until the ROI Manager has at least one ROI.
    t0 = getTime();
    
    while (roiManager("count") == 0) {
         wait(100);
         if (getTime() - t0 > 60000) {
              showMessage("Timeout", "No deletion area ROI was added within 60 seconds.");
              exit();
         }
    }
    run("Remove Overlay");
    
    roiManager("select", 0);

    run("Create Mask");
    maskimg = getTitle(); // title of the mask image
    roiManager("reset");
    
    deletioncount = 0;
    x_keep = newArray();
    y_keep = newArray();
    
    selectWindow(maskimg); 
    
    for (i = 0; i < n; i++) {
    	value = getPixel(x[i], y[i]);
    	 if (value != 0) {
            x_keep = Array.concat(x_keep, x[i]);
            y_keep = Array.concat(y_keep, y[i]);
        } else {
            deletioncount++;
        }
    }
    
    /* //this works on rectangle selection, checks if x/y coordinate is in bounds

     *  getSelectionBounds(areaX, areaY, areaWidth, areaHeight);
     *  for (i = 0; i < n; i++) {
    	if (!(x[i] >= areaX && x[i] <= (areaX + areaWidth) &&
      		y[i] >= areaY && y[i] <= (areaY + areaHeight))) {
   			
			 	x_keep = Array.concat(x_keep,x[i]);
             	y_keep = Array.concat(y_keep,y[i]);
             	deletioncount++;
             }
             
    }*/ 
    
     // Close the mask image if you want.
    selectWindow(maskimg);
    close();
    
    selectWindow(ogimg);
    
    run("Select None");
    makeSelection("point", x_keep, y_keep);
    roiManager("add");
	roiManager("Select",0);
	setTool("multipoint");
           
    print("--- Deleted "+deletioncount+") points outside selected area.");
}
