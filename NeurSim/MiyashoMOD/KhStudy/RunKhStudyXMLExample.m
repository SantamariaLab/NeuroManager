% Runs the KhStudy XML example.
clc
myData = 'FullPathToMyStaticDataFile.ini';
exampleXMLFile = 'FullPathToNMSessionML03.xml';
 
% Creates the SimSet and SessionScript files using the XML file.
ProcessNMSessionMLFile(myData, exampleXMLFile);

% Runs the automatically-produced SessionScript file
% (name generated via SessionID and 'SimSet')
NMSessionML03SimSet();

 