#!/bin/bash
#### README ####
## El script funcionará super si se corre en el /home/usuario/ y si no tienes instalado previamente Miniconda3
## siempre y cuando se acompañe con los siguientes archivos en la carpeta de ~/Downloads

# bcl-4.3.1-Linux-x86_64.sh 
# bcl.license que se debe descargar desde el sitio oficial de Bcl commons 
# ucsf-chimerax_1.8ubuntu22.04_amd64.deb
# rosetta_src_3.14_bundle.tar.bz2

##################################################################################################################

# Actualizar lista de paquetes disponibles e instalar herramientas y bibliotecas necesarias para Rosetta
sudo apt update

# Instalar dependencias comunes para Rosetta, ChimeraX y BCL
sudo apt install -y git build-essential g++ gfortran python3-dev zlib1g-dev \
libbz2-dev libboost-all-dev cmake libxcb-render0 libxcb-shape0 libxcb-xfixes0 \
libgl1-mesa-glx libxcb-keysyms1 libxcb-image0 libxcb-randr0 libxcb-sync1 \
libxcb-xtest0 libxkbcommon-x11-0 libegl1-mesa libarchive-dev
echo "Actualizaciones completas."
sleep 5
# Linux common and useful softwares
sudo apt install -y gedit
sudo apt install -y gthumb
echo "gedit y gthumb han sido instaladas."
sleep 3
# Descargar e instalar Miniconda si no está ya instalado. Si ya estas trabajando con Miniconda3 comentar todo el bloque 
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"

# Agregar inicialización de Conda a ~/.bashrc si no está ya presente

if ! grep -q 'conda initialize' ~/.bashrc; then
    echo '# >>> conda initialize >>>
# !! Contents within this block are managed by "conda init" !!
__conda_setup="$("$HOME/miniconda/bin/conda" "shell.bash" "hook" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/miniconda/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniconda/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/miniconda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<' >> ~/.bashrc
fi

# Inicializar conda
source ~/.bashrc

# Verificar la versión de conda
conda --version

# Actualizar conda en el entorno base
conda update conda -y
echo "Miniconda3 instalada."
sleep 3
echo "Creando y acyivando el enviroment para el Workshop."

# Crear un nuevo entorno conda llamado RAI_workshop e instalar Python 3.9
conda create -n RAI_workshop python=3.9 -y

# Activar el entorno RAI_workshop
source activate RAI_workshop

# Instalar módulos necesarios en el entorno RAI_workshop
conda install conda-forge::biopython -y
conda install pandas -y
conda install matplotlib -y
conda install seaborn -y

# Instalar PyMOL dentro del entorno Conda
conda install -c conda-forge pymol-open-source -y
# Alternativa: schrodinger pymol-bundle (descomentar si prefieres esta opción)
# conda install -c conda-forge -c schrodinger pymol-bundle -y
# Testear la instalación de PyMOL
pymol -c
echo "Pymol open source ha sido correctamente instalado."
sleep 2

# Desactivar el entorno Conda al finalizar
conda deactivate
echo "Desactivando el enviroment para el Workshop."
sleep 2

#ChimeraX cambiar el archivo a la ruta donde se ejecuta el script.
sudo apt install -y ~/Downloads/ucsf-chimerax_1.8ubuntu22.04_amd64.deb
echo "ChimeraX Listo para usar."
sleep 3
#install Rosetta3.14 from github 
echo "Instalar Rosetta y preparando compilación..."

#opcion para usuarios esporadicos de Rosetta
#git clone https://github.com/RosettaCommons/rosetta
#change Directory 
#cd rosetta
#cd source
#./scons.py -j<NumOfJobs> mode=release bin  -j4 indica 4 cores
#./scons.py -j4 mode=release bin

# Descomprimir Rosetta
echo "Descomprimiendo Rosetta..."
tar -xjf ~/Downloads/rosetta_src_3.14_bundle.tar.bz2 -C ~/Downloads
mv ~/Downloads/rosetta.source.release-371 ~/rosetta

# Compilar Rosetta
echo "Compilando Rosetta..."
cd ~/rosetta/main/source
python3.10 scons.py -j10 mode=release bin

# Verificar si la compilación fue exitosa
if [ $? -ne 0 ]; then
    echo "Error: La compilación de Rosetta ha fallado."
    exit 1
fi

# Ejecutar comando de prueba
echo "Probando Rosetta..."
~/rosetta/main/source/bin/score_jd2.default.linuxgccrelease -help

# Verificar si el comando de prueba fue exitoso
if [ $? -ne 0 ]; then
    echo "Error: El comando de prueba ha fallado."
    exit 1
fi

echo "La instalación de Rosetta ha sido completada satisfactoriamente."
sleep 15

echo "Finalmente instalacion de Biology and Chemistry library"
#BCL - Si se ejecuta el script en el usuario /home/dccuc (o /home/titanx1) no ho habria que darle una ruta completa de tu computadora
cp ~/Downloads/bcl-4.3.1-Linux-x86_64.sh .
chmod +x bcl-4.3.1-Linux-x86_64.sh
yes | ./bcl-4.3.1-Linux-x86_64.sh 
#Copiar la licencia: 
cp ~/Downloads/bcl.license /home/dccuc/bcl-4.3.1-Linux-x86_64
export LD_LIBRARY_PATH=/home/dccuc/bcl-4.3.1-Linux-x86_64:${LD_LIBRARY_PATH}
source ~/.bashrc
echo $LD_LIBRARY_PATH
echo "export PATH=/home/dccuc/bcl-4.3.1-Linux-x86_64:${PATH}" >> ~/.bashrc
source ~/.bashrc
sleep 180
bcl.exe -help
echo "Si el comando anterior falla, abrir una nueva pesataña ya que toma tiempo que se actualice la bashrc"
echo "Todos los softwares para el workshop han sido instaladas satisfactoriamente ."
sleep 15
exit 
