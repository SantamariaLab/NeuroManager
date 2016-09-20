% ProcessNMSessionMLFile
function ProcessNMSessionMLFile(userStaticDataPath,...
                                xmlFullPath)

[scriptDir, ~, ~] = fileparts(xmlFullPath);

[~, nmDirectorySet, ~] = loadUserStaticData(userStaticDataPath);
installDir = nmDirectorySet.nmMainDir;
addpath(fullfile(installDir, 'NMSessionML'));

xmlDir = fullfile(installDir, 'NMSessionML');
schemaFile = fullfile(xmlDir, 'NMSessMLMATLAB.xsd');
styleFile = fullfile(xmlDir, 'NMSess2MLScript.xslt');

nmSessionMLParserFunc(scriptDir, xmlFullPath, schemaFile, styleFile);
