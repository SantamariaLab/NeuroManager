#!/bin/sh
# Assume logged in as cc.
# Assume used the CentOS-7-2015 image with m1.medium flavor to create bare server.
# This script installs MCR and NEURON (with Python but not parallel).
CCHOME=/home/cc
cd $CCHOME
sudo yum install -y ncurses-term
sudo yum install -y ncurses-devel
sudo yum install -y gcc-c++
sudo yum install -y wget
sudo yum install -y zip
sudo yum install -y unzip
sudo yum install -y python-devel
sudo yum install -y readline-devel
sudo yum install -y libXext.x86_64
sudo yum install -y libXext-devel.x86_64
sudo yum install -y libXt.x86_64
sudo yum install -y libXt-devel.x86_64
sudo yum install -y libXmu.x86_64
sudo yum install -y libXmu-devel.x86_64
sudo yum install -y libXtst.x86_64
sudo yum install -y libXtst-devel.x86_64

# for debugging this script
#sudo  yum install -y emacs

cd $CCHOME
sudo mkdir MCR
cd MCR

# === Install MATLAB MCR
echo "Downloading MCR zipfile"
sudo wget -N http://www.mathworks.com/supportfiles/MCR_Runtime/R2013a/MCR_R2013a_glnxa64_installer.zip
echo "done."
echo "Unzipping MCR file"
sudo unzip -o *.zip
echo "done."
	#mkdir $CCHOME/MATLAB/MCR
echo "Installing MCR"
sudo ./install -mode silent -agreeToLicense yes -outputFile . 
echo "done."

echo "Updating MCR paths"
LD_LIBRARY_PATH=LD_LIBRARY_PATH:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/bin/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/os/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/java/jre/glnxa64/jre/lib/amd64
XAPPLRESDIR=/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/X11/app-defaults
echo "done."

# === Install NEURON with Python and without parnrn
cd $CCHOME
echo "Making neuron directory"
sudo mkdir neuron
cd $CCHOME/neuron
echo "done."

echo "Downloading NEURON tar file"
sudo wget -N http://www.neuron.yale.edu/ftp/neuron/versions/v7.4/v7.4.rel-1370/nrn-7.4.rel-1370.tar.gz
echo "done."

echo "Unpacking tar file"
sudo tar xzf nrn-7.4.rel-1370.tar.gz
sudo mv nrn-7.4 nrn
echo "done."

echo "Configuring NEURON"
cd $CCHOME/neuron/nrn
sudo ./configure --prefix=`pwd` --with-nrnpython=/usr/bin/python2.7  --without-iv | sudo tee $CCHOME/neuron/configure_log.txt 
echo "done."

echo "Begin make now"
sudo make | sudo tee $CCHOME/neuron/make_log.txt
echo "Make complete."

echo "Begin make install now"
sudo make install | sudo tee $CCHOME/neuron/makeinstall_log.txt
echo "make install complete."

echo "Setting up python 2.7"
cd $CCHOME/neuron/nrn/src/nrnpython
sudo /usr/bin/python2.7 setup.py install --prefix=~ | sudo tee $CCHOME/neuron/pythonsetup_log.txt
echo "python 2.7 setup complete."

echo "Making work directory"
cd $CCHOME
sudo mkdir NMDev
sudo chmod ug=+rwx NMDev
sudo chown cc NMDev 
echo "done."

echo "Signaling this script is done"
cd $CCHOME
sudo touch InstanceReady
echo "done."

