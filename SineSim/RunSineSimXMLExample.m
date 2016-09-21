% Runs the NMSessionML01 example.
clc
myData = 'FullPathToMyStaticDataFile.ini';
exampleXMLFile = 'FullPathToNMSessionML01.xml';
 
% Creates the SimSet and SessionScript files using the XML file.
ProcessNMSessionMLFile(myData, exampleXMLFile);

% Runs the automatically-produced SessionScript file
% Name generated via SessionID (not the _simset_ id) and 'SimSet'.
NMSessionML01SimSet();

 