% Runs the NMSessionML02 example.
clc
myData = 'FullPathToMyStaticDataFile.ini';
exampleXMLFile = 'FullPathToNMSessionML02.xml';
 
% Creates the SimSet and SessionScript files using the XML file.
ProcessNMSessionMLFile(myData, exampleXMLFile);

% Runs the automatically-produced SessionScript file
% Name generated via SessionID (not simset id) and 'SimSet'.
NMSessionML02SimSet();

 