#!/bin/bash
# Assume logged in as root.
# Assume used the CentOS 06 (PV) image with 2 GB General Purpose v1 flavor to create bare server.
# This script installs MCR and NEURON (with Python but not parallel).
RSHOME=/root
cd $RSHOME
yum install -y ncurses-term
yum install -y ncurses-devel
yum install -y gcc-c++
yum install -y wget
yum install -y zip
yum install -y unzip
yum install -y python-devel
yum install -y readline-devel
yum install -y libXext.x86_64
yum install -y libXext-devel.x86_64
yum install -y libXt.x86_64
yum install -y libXt-devel.x86_64
yum install -y libXmu.x86_64
yum install -y libXmu-devel.x86_64
yum install -y libXtst.x86_64
yum install -y libXtst-devel.x86_64
# Following may not be necessary
yum install -y zlib-dev openssl-devel sqlite-devel bzip2-devel

# Install Python 2.7.6
# Ref: https://www.digitalocean.com/community/tutorials/how-to-set-up-python-2-7-6-and-3-3-3-on-centos-6-4
wget http://www.python.org/ftp/python/2.7.6/Python-2.7.6.tar.xz
yum install -y xz
xz -d Python-2.7.6.tar.xz
tar -xvf Python-2.7.6.tar
cd Python-2.7.6
./configure --prefix=/usr/local
make
make altinstall
export PATH="/usr/local/bin:$PATH"


cd $RSHOME
mkdir MCR
cd MCR

# === Install MATLAB MCR
echo "Downloading MCR zipfile"
wget -N http://www.mathworks.com/supportfiles/MCR_Runtime/R2013a/MCR_R2013a_glnxa64_installer.zip
echo "done."
echo "Unzipping MCR file"
unzip -o *.zip
echo "done."
	#mkdir $HOME/MATLAB/MCR
echo "Installing MCR"
./install -mode silent -agreeToLicense yes -outputFile . 
echo "done."

echo "Updating MCR paths"
LD_LIBRARY_PATH=LD_LIBRARY_PATH:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/bin/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/os/glnxa64:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/sys/java/jre/glnxa64/jre/lib/amd64
XAPPLRESDIR=/usr/local/MATLAB/MATLAB_Compiler_Runtime/v81/X11/app-defaults
echo "done."


# === Install NEURON with Python and without parnrn
cd $RSHOME
echo "Making neuron directory"
mkdir neuron
cd $RSHOME/neuron
echo "done."

echo "Downloading NEURON tar file"
wget -N http://www.neuron.yale.edu/ftp/neuron/versions/v7.4/v7.4.rel-1370/nrn-7.4.rel-1370.tar.gz
echo "done."

echo "Unpacking tar file"
tar xzf nrn-7.4.rel-1370.tar.gz
mv nrn-7.4 nrn
echo "done."

echo "Configuring NEURON"
cd $RSHOME/neuron/nrn
./configure --prefix=`pwd` --with-nrnpython=/usr/local/bin/python2.7  --without-iv | tee $RSHOME/neuron/configure_log.txt 
echo "done."

echo "Begin make now"
make | tee $RSHOME/neuron/make_log.txt
echo "Make complete."

echo "Begin make install now"
make install | tee $RSHOME/neuron/makeinstall_log.txt
echo "make install complete."

echo "Setting up python 2.7"
cd $RSHOME/neuron/nrn/src/nrnpython
/usr/local/bin/python2.7 setup.py install --prefix=~ | tee $RSHOME/neuron/pythonsetup_log.txt
echo "python 2.7 setup complete."

echo "Making work directory"
cd $RSHOME
mkdir NMDev
chmod ug=+rwx NMDev
chown root NMDev 
echo "done."

echo "Signaling this script is done"
cd $RSHOME
touch InstanceReady
echo "done."

